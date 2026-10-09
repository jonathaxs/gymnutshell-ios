// ⌘
//  GymNutshellCore/Services/BackupManager.swift
//
//  Propósito: Codifica e decodifica o estado completo do app como um arquivo JSON de backup.
//             O insert/delete real no SwiftData acontece nas views, já que precisa do ModelContext.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-12.
// ⌘

import Foundation
import SwiftData

// MARK: - BackupManager

public enum BackupManager {

    // MARK: - Exportar

    public static func export(records: [DailyRecord]) throws -> Data {
        let defaults = UserDefaults.standard

        let profile = BackupPayload.ProfileSnapshot(
            name:              defaults.string(forKey: UserProfile.nameKey) ?? "",
            username:          nil,
            // Dados físicos saíram na 1.1; segue gravando 0 pra backups continuarem legíveis na 1.0/Android.
            height:            0,
            weight:            0,
            age:               0,
            sex:               UserProfile.normalizedSex(defaults.string(forKey: UserProfile.sexKey) ?? ""),
            userGoal:          defaults.string(forKey: UserProfile.userGoalKey) ?? "",
            measurementSystem: defaults.string(forKey: UserProfile.measurementSystemKey)
        )

        let appearance = BackupPayload.AppearanceSnapshot(
            theme:       defaults.string(forKey: AppTheme.storageKey) ?? AppTheme.gym.rawValue,
            accentColor: defaults.string(forKey: AppAccentColor.storageKey) ?? AppAccentColor.blue.rawValue
        )

        let customCategories     = CustomGoalCategoriesStore.load()
        let categoryOrderIds     = UnifiedCategoryOrderStore.load().map(\.id)
        let builtinCategoryOrder = GoalCategoryOrderStore.load().map(\.rawValue)

        let goals = BackupPayload.GoalsSnapshot(
            calories: GoalsProvider.calories,
            sleep:   GoalsProvider.sleep,
            water:   GoalsProvider.water,
            protein: GoalsProvider.protein,
            carbs:   GoalsProvider.carbs,
            goodFat: GoalsProvider.goodFat,
            fiber:   GoalsProvider.fiber
        )

        let goalsOrder          = GoalOrderStore.load()
        let customGoals         = CustomTrackingGoalsStore.load()
        let removedItems        = Array(RemovedItemsStore.load())
        let preferences         = buildPreferences(defaults: defaults, customGoals: customGoals)

        let snapshots = records.map { r -> BackupPayload.RecordSnapshot in
            let customValues = (try? JSONDecoder().decode([String: Int].self, from: r.customValues)) ?? [:]
            return BackupPayload.RecordSnapshot(
                date:         r.date,
                water:        r.water,
                protein:      r.protein,
                carbs:        r.carbs,
                goodFat:      r.goodFat,
                fiber:        r.fiber,
                sleep:        r.sleep,
                percent:      r.percent,
                achievementTitle: r.achievementTitle,
                achievementEmoji: r.achievementEmoji,
                points:       r.points,
                didWorkout:   r.didWorkout,
                didCardio:    r.didCardio,
                customValues: customValues
            )
        }

        let payload = BackupPayload(
            version:              4,
            exportedAt:           Date(),
            profile:              profile,
            goals:                goals,
            goalsOrder:           goalsOrder,
            customGoals:          customGoals,
            removedItems:         removedItems,
            dailyRecords:         snapshots,
            appearance:           appearance,
            customCategories:     customCategories,
            categoryOrder:        categoryOrderIds,
            builtinCategoryOrder: builtinCategoryOrder,
            preferences:          preferences
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting     = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(payload)
    }

    // MARK: - Preferências (chaves soltas no UserDefaults)

    /// Chaves que vivem fora do Core (definidas no app), referenciadas por string estável.
    private enum PrefKeys {
        static let orientationLock = "app.orientation.lock"
        static let autoWorkoutCheckin = "healthkit.autoWorkoutCheckin"
    }

    private static func buildPreferences(
        defaults: UserDefaults,
        customGoals: [CustomTrackingGoal]
    ) -> BackupPayload.PreferencesSnapshot {
        // Notificações: tipos fixos (NotificationKind) + personalizados (custom.<uuid>).
        var notifIds = NotificationKind.allCases.map(\.rawValue)
        notifIds += customGoals.map { "custom.\($0.id.uuidString)" }

        var enabled:  [String: Bool]   = [:]
        var interval: [String: Int]    = [:]
        var sound:    [String: String] = [:]
        for id in notifIds {
            if defaults.object(forKey: "notifications.enabled.\(id)") != nil {
                enabled[id] = defaults.bool(forKey: "notifications.enabled.\(id)")
            }
            if defaults.object(forKey: "notifications.intervalMinutes.\(id)") != nil {
                interval[id] = defaults.integer(forKey: "notifications.intervalMinutes.\(id)")
            }
            if let s = defaults.string(forKey: "notifications.sound.\(id)") {
                sound[id] = s
            }
        }

        // Incrementos customizados das metas built-in (só os que o usuário de fato editou).
        var increments: [String: Int] = [:]
        for key in GoalOrderStore.defaultOrder {
            let incKey = "\(key).increment"
            if defaults.object(forKey: incKey) != nil {
                increments[incKey] = defaults.integer(forKey: incKey)
            }
        }

        let autoCheckin = defaults.object(forKey: PrefKeys.autoWorkoutCheckin) != nil
            ? defaults.bool(forKey: PrefKeys.autoWorkoutCheckin)
            : nil

        return BackupPayload.PreferencesSnapshot(
            widgetBackground:     defaults.string(forKey: WidgetBackgroundStore.storageKey),
            widgetBackgroundMode: defaults.string(forKey: WidgetBackgroundStore.modeKey),
            orientationLock:      defaults.string(forKey: PrefKeys.orientationLock),
            autoWorkoutCheckin:   autoCheckin,
            controlStyle:         defaults.string(forKey: ControlStyle.storageKey),
            notificationEnabled:  enabled.isEmpty   ? nil : enabled,
            notificationInterval: interval.isEmpty  ? nil : interval,
            notificationSound:    sound.isEmpty     ? nil : sound,
            goalIncrements:       increments.isEmpty ? nil : increments
        )
    }

    private static func restorePreferences(_ prefs: BackupPayload.PreferencesSnapshot, into defaults: UserDefaults) {
        if let v = prefs.widgetBackground     { defaults.set(v, forKey: WidgetBackgroundStore.storageKey) }
        if let v = prefs.widgetBackgroundMode { defaults.set(v, forKey: WidgetBackgroundStore.modeKey) }
        if let v = prefs.orientationLock      { defaults.set(v, forKey: PrefKeys.orientationLock) }
        if let v = prefs.autoWorkoutCheckin   { defaults.set(v, forKey: PrefKeys.autoWorkoutCheckin) }
        // Backup da 1.0 não tem o campo: mantém o valor atual. Valor desconhecido também é ignorado.
        if let v = prefs.controlStyle, ControlStyle(rawValue: v) != nil {
            defaults.set(v, forKey: ControlStyle.storageKey)
        }

        if let map = prefs.notificationEnabled {
            for (id, val) in map { defaults.set(val, forKey: "notifications.enabled.\(id)") }
        }
        if let map = prefs.notificationInterval {
            for (id, val) in map { defaults.set(val, forKey: "notifications.intervalMinutes.\(id)") }
        }
        if let map = prefs.notificationSound {
            for (id, val) in map { defaults.set(val, forKey: "notifications.sound.\(id)") }
        }
        if let map = prefs.goalIncrements {
            for (key, val) in map { defaults.set(val, forKey: key) }
        }
    }

    // MARK: - Decodificar

    public static func decode(_ data: Data) throws -> BackupPayload {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(BackupPayload.self, from: data)
    }

    // MARK: - Restaurar (somente UserDefaults)

    public static func restoreUserDefaults(from payload: BackupPayload) {
        let defaults = UserDefaults.standard
        let p = payload.profile

        defaults.set(p.name,        forKey: UserProfile.nameKey)
        // height/weight/age de backups da 1.0 são ignorados (dados físicos não existem mais).
        defaults.set(UserProfile.normalizedSex(p.sex), forKey: UserProfile.sexKey)
        defaults.set(p.userGoal,    forKey: UserProfile.userGoalKey)
        if let system = p.measurementSystem {
            defaults.set(system, forKey: UserProfile.measurementSystemKey)
        }

        let g = payload.goals
        defaults.set(g.calories, forKey: "tracking.calories")
        defaults.set(g.sleep,   forKey: "tracking.sleep")
        defaults.set(g.water,   forKey: "tracking.water")
        defaults.set(g.protein, forKey: "tracking.protein")
        defaults.set(g.carbs,   forKey: "tracking.carbs")
        defaults.set(g.goodFat, forKey: "tracking.goodFat")
        defaults.set(g.fiber,   forKey: "tracking.fiber")

        GoalOrderStore.save(payload.goalsOrder)
        CustomTrackingGoalsStore.save(payload.customGoals)

        if let removed = payload.removedItems {
            RemovedItemsStore.save(removed)
        }

        if let appearance = payload.appearance {
            defaults.set(appearance.theme,       forKey: AppTheme.storageKey)
            defaults.set(appearance.accentColor, forKey: AppAccentColor.storageKey)
        }

        if let customCategories = payload.customCategories {
            CustomGoalCategoriesStore.save(customCategories)
        }
        if let builtinOrder = payload.builtinCategoryOrder {
            let categories = builtinOrder.compactMap { GoalCategory(rawValue: $0) }
            if !categories.isEmpty {
                GoalCategoryOrderStore.save(categories)
            }
        }
        if let categoryOrder = payload.categoryOrder {
            defaults.set(categoryOrder, forKey: UnifiedCategoryOrderStore.key)
        }

        if let prefs = payload.preferences {
            restorePreferences(prefs, into: defaults)
        }
    }

    // MARK: - Aplicar backup completo

    /// Restaura um `BackupPayload` por inteiro: apaga os `DailyRecord` existentes,
    /// reaplica UserDefaults/metas/preferências e reinsere os snapshots no SwiftData.
    /// Os 4 fluxos de restauração (Welcome iCloud, Welcome arquivo, painel de
    /// onboarding wide e Settings → Backup) compartilham este método.
    public static func applyPayload(_ payload: BackupPayload, into context: ModelContext) throws {
        try context.delete(model: DailyRecord.self)
        restoreUserDefaults(from: payload)
        for snap in payload.dailyRecords {
            let record = DailyRecord(
                date: snap.date, water: snap.water, protein: snap.protein,
                carbs: snap.carbs, goodFat: snap.goodFat, fiber: snap.fiber,
                sleep: snap.sleep, percent: snap.percent,
                achievementTitle: snap.achievementTitle, achievementEmoji: snap.achievementEmoji,
                points: snap.points
            )
            record.didWorkout = snap.didWorkout
            record.didCardio = snap.didCardio ?? false
            record.customValues = (try? JSONEncoder().encode(snap.customValues)) ?? Data()
            context.insert(record)
        }
    }

    // MARK: - Nome de arquivo sugerido

    public static func suggestedFilename() -> String {
        let name = UserDefaults.standard.string(forKey: UserProfile.nameKey) ?? "user"
        let sanitized = name.lowercased().filter { $0.isLetter || $0.isNumber }
        let dateStr = ISO8601DateFormatter().string(from: Date()).prefix(10)
        return "gymnutshell-\(sanitized)-backup-\(dateStr).json"
    }
}
