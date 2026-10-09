// ⌘
//  GymNutshellCore/Services/NotificationManager.swift
//
//  Propósito: Singleton que centraliza todo o sistema de notificações locais do app.
//             Pede autorização, agenda lembretes baseados em intervalo pras Metas e
//             Progresso, dispara notificações de evento e cancela/reagenda tudo.
//
//  Estratégia: só notificações locais. Sem APNs, sem servidor, sem entitlement novo.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-04-23.
// ⌘

import Foundation
import UserNotifications

// MARK: - Rotas de deep-link

extension Notification.Name {
    public static let gaNotificationRoute      = Notification.Name("ga.notificationRoute")
    public static let gaAchievementsShowToday  = Notification.Name("ga.achievementsShowToday")
    public static let gaSettingsShowBackup     = Notification.Name("ga.settingsShowBackup")
    public static let gaSettingsShowGoals      = Notification.Name("ga.settingsShowGoals")
    public static let gaSettingsShowControls   = Notification.Name("ga.settingsShowControls")
}

// MARK: - NotificationManager

public final class NotificationManager: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {

    // MARK: Singleton

    public static let shared = NotificationManager()
    private override init() { super.init() }

    private let center = UNUserNotificationCenter.current()

    // Identifiers já gravados no histórico nesta sessão, evita duplicatas entre willPresent e didReceive.
    private var loggedNotificationIdentifiers: Set<String> = []

    // MARK: - Setup

    public func configure() {
        center.delegate = self
    }

    // MARK: - Delegate

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        appendIntervalNotificationToHistoryIfNeeded(notification.request)
        completionHandler([.banner, .sound, .badge])
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let request = response.notification.request
        if let raw = request.content.userInfo["route"] as? String,
           let route = NotificationRoute(rawValue: raw) {
            var userInfo: [String: Any] = ["route": route.rawValue]
            if let ts = request.content.userInfo["achievementDate"] as? Double {
                userInfo["achievementDate"] = ts
            }
            NotificationCenter.default.post(
                name: .gaNotificationRoute,
                object: nil,
                userInfo: userInfo
            )
        }
        // Grava no histórico somente se não foi gravado via willPresent (foreground).
        appendIntervalNotificationToHistoryIfNeeded(request)
        center.removeDeliveredNotifications(withIdentifiers: [request.identifier])
        completionHandler()
    }

    // Grava notificações de intervalo (água, progresso, metas) no histórico.
    // Notificações de evento (conquista, streak, saúde, backup) já são gravadas no ponto de disparo.
    private func appendIntervalNotificationToHistoryIfNeeded(_ request: UNNotificationRequest) {
        guard !loggedNotificationIdentifiers.contains(request.identifier) else { return }
        let userInfo = request.content.userInfo
        guard let kindIdRaw = userInfo["kindId"] as? String,
              let routeRaw = userInfo["route"] as? String,
              let route = NotificationRoute(rawValue: routeRaw) else { return }
        // Evento puros (achievement, streakBonus, appleHealth, backup) são gravados no ponto de
        // disparo, não precisam de segunda gravação aqui.
        if let kind = NotificationKind(rawValue: kindIdRaw), !kind.isIntervalBased { return }
        loggedNotificationIdentifiers.insert(request.identifier)
        let title = request.content.title
        let body  = request.content.body
        Task { @MainActor in
            if let kind = NotificationKind(rawValue: kindIdRaw) {
                NotificationHistoryStore.shared.append(
                    kind: kind, title: title, body: body, route: route
                )
            }
        }
    }

    private func route(for kind: NotificationKind) -> NotificationRoute {
        switch kind {
        case .achievement, .streakBonus: return .achievementsToday
        case .backup:                    return .backup
        default:                         return .today
        }
    }

    private static let scheduleLookaheadCount = 4

    // MARK: - Autorização

    @MainActor
    public func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    public func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    // MARK: - Abre Ajustes do iOS

    /// URL pra abrir a tela do app dentro de Ajustes do iOS.
    /// Em watchOS retorna nil, o Watch não tem tela de app específica em Settings.
    /// Constante `app-settings:` é o mesmo valor de `UIApplication.openSettingsURLString`,
    /// hardcoded aqui pra manter o Core livre de UIKit.
    public static var systemSettingsURL: URL? {
        #if os(watchOS)
        return nil
        #else
        if ProcessInfo.processInfo.isiOSAppOnMac || ProcessInfo.processInfo.isMacCatalystApp {
            return URL(string: "x-apple.systempreferences:com.apple.Localization-Settings.extension")
        }
        return URL(string: "app-settings:")
        #endif
    }

    // MARK: - Onboarding inicial

    public func applyDefaultEnabledKinds() {
        NotificationPreferences.setEnabled(true, for: .progress)
        NotificationPreferences.setEnabled(true, for: .achievement)
        NotificationPreferences.setEnabled(true, for: .streakBonus)
        NotificationPreferences.setEnabled(false, for: .appleHealth)
        NotificationPreferences.setEnabled(false, for: .backup)
        NotificationPreferences.setEnabled(true, for: .water)
        for kind in [NotificationKind.sleep, .protein, .carbs, .goodFat, .fiber,
                     .workout, .cardio, .creatine] {
            NotificationPreferences.setEnabled(false, for: kind)
        }
    }

    // MARK: - Agendamento baseado em intervalo

    public func reschedule(kind: NotificationKind, currentIntake: Int? = nil, goal: Int? = nil) {
        guard kind.isIntervalBased else { return }

        guard NotificationPreferences.isEnabled(kind) else {
            cancel(kind: kind)
            return
        }

        if let intake = currentIntake, let target = goal, target > 0, intake >= target {
            cancel(kind: kind)
            return
        }

        let interval = NotificationPreferences.intervalMinutes(kind)
        scheduleInterval(
            kindId: kind.rawValue,
            titleKey: kind.titleKey,
            bodyKey: "notifications.kind.\(kind.rawValue).body",
            intervalMinutes: interval,
            startHour: kind.dailyStartHour,
            cutoffHour: kind.dailyCutoffHour,
            route: route(for: kind),
            sound: NotificationPreferences.sound(for: kind).systemSound
        )
    }

    public func rescheduleCustom(goal: CustomTrackingGoal, currentIntake: Int?) {
        guard NotificationPreferences.isCustomEnabled(id: goal.id) else {
            cancelCustom(id: goal.id)
            return
        }
        if let intake = currentIntake, goal.goal > 0, intake >= goal.goal {
            cancelCustom(id: goal.id)
            return
        }
        let interval = NotificationPreferences.customIntervalMinutes(id: goal.id, fallback: goal.increment > 0 ? 120 : 120)
        scheduleInterval(
            kindId: "custom.\(goal.id.uuidString)",
            title: "\(goal.emoji) \(goal.name)",
            body: String(format: String(localized: "notifications.custom.body", bundle: .gymNutshellCore), goal.name),
            intervalMinutes: interval,
            startHour: 6,
            cutoffHour: 22,
            route: .today,
            sound: NotificationPreferences.customSound(id: goal.id).systemSound
        )
    }

    public func cancel(kind: NotificationKind) {
        removePending(withPrefix: "notif.\(kind.rawValue).")
    }

    public func cancelCustom(id: UUID) {
        removePending(withPrefix: "notif.custom.\(id.uuidString).")
    }

    public func rescheduleAllActive() {
        Task {
            let status = await authorizationStatus()
            guard status == .authorized || status == .provisional else {
                center.removeAllPendingNotificationRequests()
                return
            }
            for kind in NotificationKind.allCases where kind.isIntervalBased {
                reschedule(kind: kind)
            }
        }
    }

    // MARK: - Eventos

    public func fireAchievementUnlocked(tierName: String, emoji: String, date: Date = Date()) {
        guard NotificationPreferences.isEnabled(.achievement) else { return }
        let title = String(localized: "notifications.kind.achievement.title", bundle: .gymNutshellCore)
        let body = String(format: String(localized: "notifications.kind.achievement.body", bundle: .gymNutshellCore), emoji, tierName)
        scheduleImmediate(
            identifier: "notif.achievement.\(Int(Date().timeIntervalSince1970))",
            title: title,
            body: body,
            route: .achievementsToday,
            achievementDate: date,
            sound: NotificationPreferences.sound(for: .achievement).systemSound
        )
        Task { @MainActor in
            NotificationHistoryStore.shared.append(
                kind: .achievement, title: title, body: body,
                route: .achievementsToday, achievementDate: date
            )
        }
    }

    public func fireStreakBonus(emoji: String, points: Int, typeKey: String, date: Date = Date()) {
        guard NotificationPreferences.isEnabled(.streakBonus) else { return }
        let title = String(localized: "notifications.kind.streakBonus.title", bundle: .gymNutshellCore)
        let body = String(
            format: String(localized: "notifications.kind.streakBonus.body", bundle: .gymNutshellCore),
            emoji, points
        )
        scheduleImmediate(
            identifier: "notif.streakBonus.\(Int(Date().timeIntervalSince1970))",
            title: title,
            body: body,
            route: .achievementsToday,
            achievementDate: date,
            sound: NotificationPreferences.sound(for: .streakBonus).systemSound
        )
        Task { @MainActor in
            NotificationHistoryStore.shared.append(
                kind: .streakBonus, title: title, body: body,
                route: .achievementsToday, achievementDate: date
            )
        }
    }

    public enum HealthLogKind: Sendable { case cardio, workout, sleep }

    public func fireHealthLogged(_ kind: HealthLogKind, value: Int, activityName: String? = nil) {
        guard NotificationPreferences.isEnabled(.appleHealth) else { return }
        let title = String(localized: "notifications.kind.appleHealth.title", bundle: .gymNutshellCore)
        let body: String
        switch kind {
        case .cardio:
            body = String(
                format: String(localized: "notifications.kind.appleHealth.body.cardio", bundle: .gymNutshellCore),
                value, activityName ?? String(localized: "healthkit.activity.other", bundle: .gymNutshellCore)
            )
        case .workout:
            body = String(
                format: String(localized: "notifications.kind.appleHealth.body.workout", bundle: .gymNutshellCore),
                value, activityName ?? String(localized: "healthkit.activity.other", bundle: .gymNutshellCore)
            )
        case .sleep:
            body = String(format: String(localized: "notifications.kind.appleHealth.body.sleep", bundle: .gymNutshellCore), value)
        }
        scheduleImmediate(
            identifier: "notif.appleHealth.\(Int(Date().timeIntervalSince1970))",
            title: title,
            body: body,
            route: .today,
            sound: NotificationPreferences.sound(for: .appleHealth).systemSound
        )
        Task { @MainActor in
            NotificationHistoryStore.shared.append(
                kind: .appleHealth, title: title, body: body, route: .today
            )
        }
    }

    public func fireBackupCompleted() {
        guard NotificationPreferences.isEnabled(.backup) else { return }
        let title = String(localized: "notifications.kind.backup.title", bundle: .gymNutshellCore)
        let body = String(localized: "notifications.kind.backup.body", bundle: .gymNutshellCore)
        scheduleImmediate(
            identifier: "notif.backup.\(Int(Date().timeIntervalSince1970))",
            title: title,
            body: body,
            route: .backup,
            sound: NotificationPreferences.sound(for: .backup).systemSound
        )
        Task { @MainActor in
            NotificationHistoryStore.shared.append(
                kind: .backup, title: title, body: body, route: .backup
            )
        }
    }

    // MARK: - Agendamento da conquista de meia-noite

    private static let midnightAchievementId = "notif.achievement.midnight"

    public func scheduleDailyAchievementAtMidnight(tierName: String, emoji: String, earnedOn: Date = Date()) {
        guard NotificationPreferences.isEnabled(.achievement) else {
            center.removePendingNotificationRequests(withIdentifiers: [Self.midnightAchievementId])
            return
        }

        center.removePendingNotificationRequests(withIdentifiers: [Self.midnightAchievementId])

        let calendar = Calendar.current
        guard let startOfTomorrow = calendar.date(
            byAdding: .day, value: 1,
            to: calendar.startOfDay(for: earnedOn)
        ) else { return }
        let fireDate = startOfTomorrow.addingTimeInterval(5)

        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let content = UNMutableNotificationContent()
        content.title = String(localized: "notifications.kind.achievement.title", bundle: .gymNutshellCore)
        content.body = String(format: String(localized: "notifications.kind.achievement.body", bundle: .gymNutshellCore), emoji, tierName)
        content.sound = NotificationPreferences.sound(for: .achievement).systemSound
        content.userInfo = [
            "route": NotificationRoute.achievementsToday.rawValue,
            "achievementDate": earnedOn.timeIntervalSince1970
        ]

        let request = UNNotificationRequest(
            identifier: Self.midnightAchievementId,
            content: content,
            trigger: trigger
        )
        center.add(request) { _ in }
    }

    // MARK: - Núcleo de agendamento

    private func scheduleInterval(
        kindId: String,
        title: String? = nil,
        body: String? = nil,
        titleKey: String? = nil,
        bodyKey: String? = nil,
        intervalMinutes: Int,
        startHour: Int,
        cutoffHour: Int,
        route: NotificationRoute,
        sound: UNNotificationSound? = .default
    ) {
        removePending(withPrefix: "notif.\(kindId).")

        guard intervalMinutes > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = title ?? NSLocalizedString(titleKey ?? "", bundle: .gymNutshellCore, comment: "")
        content.body  = body  ?? NSLocalizedString(bodyKey  ?? "", bundle: .gymNutshellCore, comment: "")
        content.sound = sound
        content.userInfo = ["route": route.rawValue, "kindId": kindId]

        let calendar = Calendar.current
        var next = Date().addingTimeInterval(TimeInterval(intervalMinutes * 60))

        for slot in 0..<Self.scheduleLookaheadCount {
            let hour = calendar.component(.hour, from: next)
            if hour >= cutoffHour || hour < startHour {
                break
            }
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: next)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let identifier = "notif.\(kindId).\(Int(next.timeIntervalSince1970))-\(slot)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            center.add(request) { _ in }

            next = next.addingTimeInterval(TimeInterval(intervalMinutes * 60))
        }
    }

    private func scheduleImmediate(
        identifier: String,
        title: String,
        body: String,
        route: NotificationRoute,
        achievementDate: Date? = nil,
        sound: UNNotificationSound? = .default
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound
        var userInfo: [String: Any] = ["route": route.rawValue]
        if let date = achievementDate {
            userInfo["achievementDate"] = date.timeIntervalSince1970
        }
        content.userInfo = userInfo

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request) { _ in }
    }

    // MARK: - Limpeza

    private func removePending(withPrefix prefix: String) {
        center.getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier).filter { $0.hasPrefix(prefix) }
            if !ids.isEmpty {
                self.center.removePendingNotificationRequests(withIdentifiers: ids)
            }
        }
    }
}
