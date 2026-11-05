// ⌘
//  GymNutshellCore/Services/StreakBonusCalculator.swift
//
//  Propósito: Bônus de sequência da 2.0. Semana (segunda a domingo) ou mês inteiro com todos os
//             dias no nível 4 ou 5, ou todos no nível 5. Calculados na hora a partir dos dias
//             salvos: editar um dia faz o bônus aparecer ou sumir sozinho, e o backup não precisa
//             guardar nada. O model `StreakBonus` antigo segue só no schema e não é usado.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-11-04.
// ⌘

import Foundation

// MARK: - StreakBonusKind

/// Os 4 tipos de bônus. O rawValue é estável (vai no id do aviso e nas chaves de texto).
public enum StreakBonusKind: String, CaseIterable, Identifiable, Sendable {
    case weeklyLevel4  = "weekly.level4"
    case weeklyLevel5  = "weekly.level5"
    case monthlyLevel4 = "monthly.level4"
    case monthlyLevel5 = "monthly.level5"

    public var id: String { rawValue }

    public var isMonthly: Bool { self == .monthlyLevel4 || self == .monthlyLevel5 }

    /// Semana nível 4+: 8 | semana só nível 5: 12 | mês nível 4+: 20 | mês só nível 5: 33.
    public var points: Int {
        switch self {
        case .weeklyLevel4:  return 8
        case .weeklyLevel5:  return 12
        case .monthlyLevel4: return 20
        case .monthlyLevel5: return 33
        }
    }

    /// Emoji no calendário, no histórico e no aviso. Nenhum deles aparece nos temas de conquista.
    public var emoji: String {
        switch self {
        case .weeklyLevel4:  return "🎖️"
        case .weeklyLevel5:  return "💀"
        case .monthlyLevel4: return "🌟"
        case .monthlyLevel5: return "☠️"
        }
    }

    // A chave vai numa constante antes: interpolar direto no LocalizationValue vira formato ("%@").
    public var title: String {
        let key = "streak.bonus.\(rawValue).title"
        return String(localized: String.LocalizationValue(key), bundle: .gymNutshellCore)
    }

    public var detail: String {
        let key = "streak.bonus.\(rawValue).description"
        return String(localized: String.LocalizationValue(key), bundle: .gymNutshellCore)
    }
}

// MARK: - EarnedStreakBonus

/// Um bônus ganho: o tipo e o dia que fechou o período (domingo ou último dia do mês).
public struct EarnedStreakBonus: Identifiable, Hashable, Sendable {
    public let kind: StreakBonusKind
    /// Início do dia que fechou o período.
    public let anchorDate: Date

    public var points: Int { kind.points }

    /// Id estável, ex: "weekly.level5.2026-11-02".
    public var id: String {
        let c = Calendar(identifier: .gregorian).dateComponents(in: .current, from: anchorDate)
        return String(format: "%@.%04d-%02d-%02d", kind.rawValue, c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    public init(kind: StreakBonusKind, anchorDate: Date) {
        self.kind = kind
        self.anchorDate = anchorDate
    }
}

// MARK: - StreakBonusCalculator

public enum StreakBonusCalculator {

    /// Calendário com a semana de segunda a domingo, o mesmo do calendário de Conquistas.
    public static var weekCalendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }

    /// Bônus a partir dos dias salvos (nível lido do emoji, igual ao resto do app).
    public static func bonuses(from records: [DailyRecord]) -> [EarnedStreakBonus] {
        let calendar = weekCalendar
        var levels: [Date: DailyAchievement] = [:]
        for record in records {
            levels[calendar.startOfDay(for: record.date)] = DailyAchievement.from(emoji: record.achievementEmoji)
        }
        return bonuses(levels: levels, calendar: calendar)
    }

    /// Bônus a partir de dia → nível. Um dia sem registro quebra a sequência. Período todo no
    /// nível 5 ganha só o bônus maior. Resultado do mais recente pro mais antigo.
    public static func bonuses(levels: [Date: DailyAchievement],
                               calendar: Calendar = weekCalendar) -> [EarnedStreakBonus] {
        var byDay: [Date: DailyAchievement] = [:]
        for (date, level) in levels { byDay[calendar.startOfDay(for: date)] = level }

        var result: [EarnedStreakBonus] = []

        // Semanas: cada domingo salvo fecha a semana que começou na segunda anterior.
        for sunday in byDay.keys where calendar.component(.weekday, from: sunday) == 1 {
            let week = (0..<7).compactMap { calendar.date(byAdding: .day, value: -$0, to: sunday) }
            if let kind = kind(for: week.map { byDay[calendar.startOfDay(for: $0)] },
                               top: .weeklyLevel5, high: .weeklyLevel4) {
                result.append(EarnedStreakBonus(kind: kind, anchorDate: sunday))
            }
        }

        // Meses: o último dia salvo do mês fecha o mês.
        for day in byDay.keys {
            guard let next = calendar.date(byAdding: .day, value: 1, to: day),
                  !calendar.isDate(next, equalTo: day, toGranularity: .month),
                  let month = calendar.dateInterval(of: .month, for: day),
                  let count = calendar.range(of: .day, in: .month, for: day)?.count
            else { continue }
            let monthDays = (0..<count).compactMap { calendar.date(byAdding: .day, value: $0, to: month.start) }
            if let kind = kind(for: monthDays.map { byDay[calendar.startOfDay(for: $0)] },
                               top: .monthlyLevel5, high: .monthlyLevel4) {
                result.append(EarnedStreakBonus(kind: kind, anchorDate: day))
            }
        }

        return result.sorted {
            $0.anchorDate == $1.anchorDate ? $0.kind.isMonthly && !$1.kind.isMonthly : $0.anchorDate > $1.anchorDate
        }
    }

    /// Pontos totais: nível de cada dia (1 a 5) + bônus.
    public static func totalPoints(records: [DailyRecord]) -> Int {
        let daily = records.reduce(0) { $0 + DailyAchievement.from(emoji: $1.achievementEmoji).points }
        return daily + bonuses(from: records).reduce(0) { $0 + $1.points }
    }

    private static func kind(for levels: [DailyAchievement?],
                             top: StreakBonusKind,
                             high: StreakBonusKind) -> StreakBonusKind? {
        let numbers = levels.map { $0?.number ?? 0 }
        guard !numbers.isEmpty, numbers.allSatisfy({ $0 >= 4 }) else { return nil }
        return numbers.allSatisfy { $0 == 5 } ? top : high
    }
}

// MARK: - StreakBonusNotifier

/// Avisa uma vez só cada bônus novo. Na primeira rodada (ou depois de importar um backup) só
/// marca os bônus que já existem, sem avisar.
public enum StreakBonusNotifier {

    static let notifiedKey = "streakBonus.notifiedIds"

    /// Chamado depois de restaurar um backup: os bônus importados não viram aviso.
    public static func resetSeed(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: notifiedKey)
    }

    public static func notifyNew(records: [DailyRecord], defaults: UserDefaults = .standard) {
        let bonuses = StreakBonusCalculator.bonuses(from: records)
        let ids = bonuses.map(\.id)
        guard let stored = defaults.stringArray(forKey: notifiedKey) else {
            // Quem já usava o app antes da volta dos bônus ganha o aviso ligado, igual a quem instala agora.
            if defaults.object(forKey: "notifications.enabled.\(NotificationKind.streakBonus.rawValue)") == nil {
                NotificationPreferences.setEnabled(true, for: .streakBonus)
            }
            defaults.set(ids, forKey: notifiedKey)
            return
        }
        let known = Set(stored)
        // Só avisa bônus recentes: editar um dia antigo não dispara aviso de semanas atrás.
        let limit = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? .distantPast
        for bonus in bonuses where !known.contains(bonus.id) && bonus.anchorDate >= limit {
            NotificationManager.shared.fireStreakBonus(bonus)
        }
        defaults.set(Array(known.union(ids)), forKey: notifiedKey)
    }
}
