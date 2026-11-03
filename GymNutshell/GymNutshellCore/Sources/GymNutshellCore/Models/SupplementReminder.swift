// ⌘
//  GymNutshellCore/Models/SupplementReminder.swift
//
//  Propósito: Lembretes por horário das metas check-in (suplementos). Guarda os horários
//             de cada meta, monta os avisos dos próximos dias e registra o "Tomei" vindo
//             da notificação.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-11-01.
// ⌘

import Foundation

// MARK: - ReminderTime

/// Horário de um lembrete (hora e minuto, 24h).
public struct ReminderTime: Codable, Hashable, Comparable, Identifiable, Sendable {
    public var hour: Int
    public var minute: Int

    public init(hour: Int, minute: Int) {
        self.hour = min(max(hour, 0), 23)
        self.minute = min(max(minute, 0), 59)
    }

    public var id: Int { hour * 60 + minute }

    public static func < (lhs: ReminderTime, rhs: ReminderTime) -> Bool { lhs.id < rhs.id }

    /// Data de hoje (ou do dia passado) nesse horário.
    public func date(on day: Date, calendar: Calendar = .current) -> Date? {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)
    }

    /// Horário no formato do aparelho (ex: "08:00" ou "8:00 AM").
    public var formatted: String {
        guard let date = date(on: Date()) else { return "\(hour):\(minute)" }
        return date.formatted(date: .omitted, time: .shortened)
    }

    /// Texto estável "HH:mm" usado no backup.
    public var storageString: String { String(format: "%02d:%02d", hour, minute) }

    public init?(storageString: String) {
        let parts = storageString.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2, (0...23).contains(parts[0]), (0...59).contains(parts[1]) else { return nil }
        self.init(hour: parts[0], minute: parts[1])
    }

    // MARK: Atalhos

    /// Atalho de horário mostrado como botão ao editar os lembretes.
    public struct Preset: Identifiable, Sendable {
        public let titleKey: String
        public let time: ReminderTime
        public var id: String { titleKey }

        public var title: String {
            NSLocalizedString(titleKey, bundle: .gymNutshellCore, comment: "")
        }
    }

    /// Manhã, almoço, fim da tarde, noite e antes de dormir.
    public static let presets: [Preset] = [
        Preset(titleKey: "notifications.supplement.preset.morning", time: ReminderTime(hour: 8, minute: 0)),
        Preset(titleKey: "notifications.supplement.preset.lunch", time: ReminderTime(hour: 12, minute: 0)),
        Preset(titleKey: "notifications.supplement.preset.afternoon", time: ReminderTime(hour: 17, minute: 0)),
        Preset(titleKey: "notifications.supplement.preset.night", time: ReminderTime(hour: 20, minute: 0)),
        Preset(titleKey: "notifications.supplement.preset.bedtime", time: ReminderTime(hour: 22, minute: 30))
    ]
}

// MARK: - Preferências

/// Horários por meta e a opção de agrupar.
/// Chaves:
///   - `notifications.times.<id>` : [ReminderTime] em JSON, `<id>` = "creatine" ou "custom.<uuid>"
///   - `notifications.supplements.grouped` : Bool
public extension NotificationPreferences {

    /// Id do lembrete da Creatina (mesmo id usado nas outras preferências dela).
    static let creatineReminderId = NotificationKind.creatine.rawValue

    static func customReminderId(_ id: UUID) -> String { "custom.\(id.uuidString)" }

    static func reminderTimes(id: String) -> [ReminderTime] {
        guard
            let data = UserDefaults.standard.data(forKey: "notifications.times.\(id)"),
            let times = try? JSONDecoder().decode([ReminderTime].self, from: data)
        else { return [] }
        return Array(Set(times)).sorted()
    }

    static func setReminderTimes(_ times: [ReminderTime], id: String) {
        let unique = Array(Set(times)).sorted()
        if unique.isEmpty {
            UserDefaults.standard.removeObject(forKey: "notifications.times.\(id)")
        } else if let data = try? JSONEncoder().encode(unique) {
            UserDefaults.standard.set(data, forKey: "notifications.times.\(id)")
        }
    }

    static let groupSupplementsKey = "notifications.supplements.grouped"

    /// Junta num aviso só os suplementos do mesmo horário. Desligado por padrão.
    static var groupSupplements: Bool {
        UserDefaults.standard.bool(forKey: groupSupplementsKey)
    }

    /// Ativo e com horário para essa meta.
    static func isReminderEnabled(id: String) -> Bool {
        UserDefaults.standard.bool(forKey: "notifications.enabled.\(id)")
    }
}

// MARK: - Planejamento

/// Uma meta check-in com seus horários, pronta pra virar avisos.
public struct SupplementReminderEntry: Sendable {
    public let id: String
    public let emoji: String
    public let name: String
    public let times: [ReminderTime]
    public let doneToday: Bool

    public init(id: String, emoji: String, name: String, times: [ReminderTime], doneToday: Bool) {
        self.id = id
        self.emoji = emoji
        self.name = name
        self.times = times
        self.doneToday = doneToday
    }
}

/// Aviso a agendar: um horário de um dia, com uma ou várias metas (quando agrupado).
public struct PlannedSupplementReminder: Equatable, Sendable {
    public let identifier: String
    public let fireDate: Date
    public let entryIds: [String]
    public let title: String
    public let body: String
}

public enum SupplementReminderPlanner {

    /// Prefixo dos identifiers, usado pra cancelar todos de uma vez.
    public static let identifierPrefix = "notif.supplement."

    /// Dias agendados à frente. O app reagenda ao abrir, então 3 dias cobrem bem quem abre todo dia.
    public static let daysAhead = 3

    /// Teto de avisos pendentes, deixa espaço pros lembretes por intervalo (o iOS guarda 64 no total).
    public static let maxPending = 30

    private static let stampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMddHHmm"
        return f
    }()

    /// Monta os avisos dos próximos dias. Pula horários que já passaram e, hoje,
    /// as metas já feitas. Agrupado: um aviso por horário com todas as metas dele.
    /// `showEmoji` põe o emoji de cada meta (e o ⏰ do agrupado) no texto do aviso.
    public static func plan(
        entries: [SupplementReminderEntry],
        now: Date = Date(),
        calendar: Calendar = .current,
        grouped: Bool,
        showEmoji: Bool = false,
        days: Int = daysAhead
    ) -> [PlannedSupplementReminder] {
        let today = calendar.startOfDay(for: now)

        // (data do aviso, meta) de todos os dias, já sem passados e sem feitos hoje.
        var slots: [(date: Date, entry: SupplementReminderEntry)] = []
        for offset in 0..<max(days, 0) {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            for entry in entries {
                if offset == 0 && entry.doneToday { continue }
                for time in entry.times {
                    guard let date = time.date(on: day, calendar: calendar), date > now else { continue }
                    slots.append((date, entry))
                }
            }
        }

        var result: [PlannedSupplementReminder] = []
        if grouped {
            let byDate = Dictionary(grouping: slots, by: \.date)
            for date in byDate.keys {
                let group = byDate[date, default: []].map(\.entry).sorted { $0.name < $1.name }
                result.append(reminder(for: group, at: date, showEmoji: showEmoji))
            }
        } else {
            result = slots.map { reminder(for: [$0.entry], at: $0.date, showEmoji: showEmoji) }
        }

        return Array(
            result
                .sorted { ($0.fireDate, $0.identifier) < ($1.fireDate, $1.identifier) }
                .prefix(maxPending)
        )
    }

    private static func reminder(for group: [SupplementReminderEntry], at date: Date,
                                 showEmoji: Bool) -> PlannedSupplementReminder {
        let stamp = stampFormatter.string(from: date)
        func label(_ entry: SupplementReminderEntry) -> String {
            showEmoji && !entry.emoji.isEmpty ? "\(entry.emoji) \(entry.name)" : entry.name
        }
        if group.count == 1, let entry = group.first {
            return PlannedSupplementReminder(
                identifier: "\(identifierPrefix)\(stamp).\(entry.id)",
                fireDate: date,
                entryIds: [entry.id],
                title: label(entry),
                body: String(format: NSLocalizedString("notifications.supplement.body", bundle: .gymNutshellCore, comment: ""),
                             entry.name)
            )
        }
        let names = group.map(label)
        let groupTitle = NSLocalizedString("notifications.supplement.group.title", bundle: .gymNutshellCore, comment: "")
        return PlannedSupplementReminder(
            identifier: "\(identifierPrefix)\(stamp).group",
            fireDate: date,
            entryIds: group.map(\.id),
            title: showEmoji ? "⏰ \(groupTitle)" : groupTitle,
            body: ListFormatter.localizedString(byJoining: names)
        )
    }
}

// MARK: - Estado de hoje

/// Lê do UserDefaults as metas check-in com lembrete ativo e se já foram feitas hoje.
/// O dia corrente é o `lastFinishedDate` da tela Hoje; se ele ficou para trás
/// (app ainda não abriu hoje), os valores salvos são de ontem e nada conta como feito.
public enum SupplementReminderState {

    public static func entries(now: Date = Date()) -> [SupplementReminderEntry] {
        let todayKey = AppDateFormatters.dayKey.string(from: now)
        let isCurrentDay = UserDefaults.standard.string(forKey: "lastFinishedDate") == todayKey
        let pending = Set(SupplementCheckIn.pendingIds(for: todayKey))

        func done(_ id: String, current: Int, goal: Int) -> Bool {
            pending.contains(id) || (isCurrentDay && CategoryKind.isCheckInDone(current: current, goal: goal))
        }

        var result: [SupplementReminderEntry] = []

        // Creatina fica sempre em Suplemento (check-in).
        let creatineId = NotificationPreferences.creatineReminderId
        if !RemovedItemsStore.load().contains("tracking.creatine"),
           NotificationPreferences.isReminderEnabled(id: creatineId) {
            let times = NotificationPreferences.reminderTimes(id: creatineId)
            if !times.isEmpty {
                result.append(SupplementReminderEntry(
                    id: creatineId,
                    emoji: NotificationKind.creatine.emoji ?? "🧪",
                    name: NSLocalizedString("today.goals.creatine", bundle: .gymNutshellCore, comment: ""),
                    times: times,
                    doneToday: done(creatineId, current: UserDefaults.standard.integer(forKey: "creatineIntake"),
                                    goal: GoalsProvider.creatine)
                ))
            }
        }

        let categories = CustomGoalCategoriesStore.load()
        let intakes = CustomTrackingIntakesStore.load()
        for goal in CustomTrackingGoalsStore.load() where goal.kind(in: categories) == .checkIn {
            let id = NotificationPreferences.customReminderId(goal.id)
            guard NotificationPreferences.isReminderEnabled(id: id) else { continue }
            let times = NotificationPreferences.reminderTimes(id: id)
            guard !times.isEmpty else { continue }
            result.append(SupplementReminderEntry(
                id: id,
                emoji: goal.emoji,
                name: goal.name,
                times: times,
                doneToday: done(id, current: intakes[goal.id.uuidString] ?? 0, goal: goal.goal)
            ))
        }
        return result
    }
}

// MARK: - "Tomei" pela notificação

extension Notification.Name {
    /// Postada depois de marcar um suplemento pela notificação, a Hoje recarrega os valores.
    public static let gaSupplementCheckedIn = Notification.Name("ga.supplementCheckedIn")
}

/// Marca metas check-in como feitas a partir da ação da notificação.
/// Se a Hoje já está no dia do aviso, grava direto. Se o app ainda não virou o dia,
/// guarda como pendente e a Hoje aplica depois de fechar o dia anterior.
public enum SupplementCheckIn {

    private static let pendingKey = "notifications.supplements.pendingCheckIns"

    public static func markDone(ids: [String], on date: Date, now: Date = Date()) {
        let dayKey = AppDateFormatters.dayKey.string(from: date)
        if UserDefaults.standard.string(forKey: "lastFinishedDate") == dayKey {
            apply(ids: ids)
        } else if dayKey == AppDateFormatters.dayKey.string(from: now) {
            var pending = loadPending()
            pending[dayKey] = Array(Set(pending[dayKey, default: []] + ids))
            savePending(pending)
        }
        // Aviso de um dia que já passou: ignora, não marca o dia errado.
        NotificationCenter.default.post(name: .gaSupplementCheckedIn, object: nil)
    }

    /// Chamado pela Hoje depois de virar o dia: aplica o que ficou pendente pra hoje e limpa o resto.
    public static func applyPending(now: Date = Date()) {
        let pending = loadPending()
        guard !pending.isEmpty else { return }
        let todayKey = AppDateFormatters.dayKey.string(from: now)
        UserDefaults.standard.removeObject(forKey: pendingKey)
        if UserDefaults.standard.string(forKey: "lastFinishedDate") == todayKey, let ids = pending[todayKey] {
            apply(ids: ids)
        }
    }

    static func pendingIds(for dayKey: String) -> [String] {
        loadPending()[dayKey] ?? []
    }

    // Grava o valor de "Feito" (a dose da meta), igual ao seletor da Hoje.
    private static func apply(ids: [String]) {
        var intakes: [String: Int]? = nil
        let goals = CustomTrackingGoalsStore.load()
        for id in ids {
            if id == NotificationPreferences.creatineReminderId {
                UserDefaults.standard.set(CategoryKind.checkInValue(done: true, goal: GoalsProvider.creatine), forKey: "creatineIntake")
            } else if let goal = goals.first(where: { NotificationPreferences.customReminderId($0.id) == id }) {
                if intakes == nil { intakes = CustomTrackingIntakesStore.load() }
                intakes?[goal.id.uuidString] = CategoryKind.checkInValue(done: true, goal: goal.goal)
            }
        }
        if let intakes { CustomTrackingIntakesStore.save(intakes) }
    }

    private static func loadPending() -> [String: [String]] {
        guard
            let data = UserDefaults.standard.data(forKey: pendingKey),
            let dict = try? JSONDecoder().decode([String: [String]].self, from: data)
        else { return [:] }
        return dict
    }

    private static func savePending(_ dict: [String: [String]]) {
        guard let data = try? JSONEncoder().encode(dict) else { return }
        UserDefaults.standard.set(data, forKey: pendingKey)
    }
}
