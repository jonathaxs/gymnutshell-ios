// ⌘
//  GymNutshellCore/Models/WidgetSnapshot.swift
//
//  Propósito: Snapshot pré-computado do progresso do dia para widgets e complications.
//             Escrito pelo app principal via WidgetSnapshotStore, lido pelos widget extensions.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-04-29.
// ⌘

import Foundation
import SwiftData

public struct WidgetSnapshot: Codable, Sendable {

    /// Progresso normalizado do dia (0.0–1.0), média de todos os objetivos ativos.
    public let progressNormalized: Double

    /// Nível do tier atual (1–4).
    public let tier: Int

    /// Emoji do tier pré-computado com tema + gênero do usuário.
    public let tierEmoji: String

    /// Nome localizado do tier pré-computado.
    public let tierName: String

    /// Raw value de `AppAccentColor` para aplicar a cor de destaque no widget.
    public let accentColorRaw: String

    /// Momento em que o snapshot foi gerado.
    public let updatedAt: Date

    /// Últimos ~35 dias com o percentual final de cada um (do mais antigo pro mais recente).
    /// Inclui o dia de hoje no final, usando o progresso parcial atual.
    public let recentDays: [DaySummary]

    /// Metas ativas com progresso individual (na ordem do GoalOrderStore, sem as removidas).
    public let goals: [GoalProgress]

    public var progressPercent: Int { Int((progressNormalized * 100).rounded(.down)) }

    public init(
        progressNormalized: Double,
        tier: Int,
        tierEmoji: String,
        tierName: String,
        accentColorRaw: String,
        updatedAt: Date = Date(),
        recentDays: [DaySummary] = [],
        goals: [GoalProgress] = []
    ) {
        self.progressNormalized = max(0, min(1, progressNormalized))
        self.tier = max(1, min(4, tier))
        self.tierEmoji = tierEmoji
        self.tierName = tierName
        self.accentColorRaw = accentColorRaw
        self.updatedAt = updatedAt
        self.recentDays = recentDays
        self.goals = goals
    }

    private enum CodingKeys: String, CodingKey {
        case progressNormalized, tier, tierEmoji, tierName,
             accentColorRaw, updatedAt, recentDays, goals
    }

    // Decoder tolerante: snapshots antigos não têm recentDays/goals.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.progressNormalized = max(0, min(1, try c.decode(Double.self, forKey: .progressNormalized)))
        self.tier = max(1, min(4, try c.decode(Int.self, forKey: .tier)))
        self.tierEmoji = try c.decode(String.self, forKey: .tierEmoji)
        self.tierName = try c.decode(String.self, forKey: .tierName)
        self.accentColorRaw = try c.decode(String.self, forKey: .accentColorRaw)
        self.updatedAt = try c.decode(Date.self, forKey: .updatedAt)
        self.recentDays = (try? c.decode([DaySummary].self, forKey: .recentDays)) ?? []
        self.goals = (try? c.decode([GoalProgress].self, forKey: .goals)) ?? []
    }

    public static let placeholder = WidgetSnapshot(
        progressNormalized: 0.65,
        tier: 2,
        tierEmoji: "🐈",
        tierName: "---",
        accentColorRaw: AppAccentColor.blue.rawValue,
        recentDays: WidgetSnapshot.placeholderDays(),
        goals: [
            GoalProgress(key: "tracking.workout", emoji: "🏋️", label: "Treino",   percent: 80),
            GoalProgress(key: "tracking.water",   emoji: "💧", label: "Água",     percent: 60),
            GoalProgress(key: "tracking.protein", emoji: "🍗", label: "Proteína", percent: 40),
            GoalProgress(key: "tracking.sleep",   emoji: "💤", label: "Sono",     percent: 100)
        ]
    )

    private static func placeholderDays() -> [DaySummary] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<35).reversed().map { i in
            let d = cal.date(byAdding: .day, value: -i, to: today) ?? today
            return DaySummary(date: d, percent: Int.random(in: 30...100))
        }
    }
}

// MARK: - Sub-structs

public struct DaySummary: Codable, Sendable, Hashable {
    public let date: Date
    public let percent: Int

    public init(date: Date, percent: Int) {
        self.date = date
        self.percent = max(0, min(100, percent))
    }
}

public struct GoalProgress: Codable, Sendable, Hashable, Identifiable {
    public let key: String
    public let emoji: String
    public let label: String
    public let percent: Int

    public var id: String { key }

    public init(key: String, emoji: String, label: String, percent: Int) {
        self.key = key
        self.emoji = emoji
        self.label = label
        self.percent = max(0, min(100, percent))
    }
}

// MARK: - Builder (executado apenas no processo do app principal)

extension WidgetSnapshot {

    /// Lê os intakes e metas do `UserDefaults.standard` e calcula o snapshot atual.
    /// Deve ser chamado apenas a partir do app principal (iOS), nunca do widget extension.
    ///
    /// - Parameter recentRecords: histórico de `DailyRecord` (qualquer subconjunto contendo
    ///   ao menos os últimos 35 dias). Quando vazio, `recentDays` no snapshot fica vazio.
    public static func buildCurrent(recentRecords: [DailyRecord] = []) -> WidgetSnapshot {
        let defaults = UserDefaults.standard

        // Ordem canônica: categoria primeiro, meta depois. Mesmo algoritmo que
        // TodayView, EditTodayView, Watch, Notifications, Settings → Goals usam.
        let activeKeys = OrderedGoalsResolver.orderedActiveBuiltinKeys()

        var perGoal: [(String, Double)] = []
        for key in activeKeys {
            perGoal.append((key, intakeProgress(key: key, defaults: defaults)))
        }

        let dailyProgress = perGoal.isEmpty ? 0 : perGoal.map(\.1).reduce(0, +) / Double(perGoal.count)
        let achievement = DailyAchievement.from(progress: dailyProgress)

        let themeRaw = defaults.string(forKey: AppTheme.storageKey) ?? ""
        let theme = AppTheme(rawValue: themeRaw) ?? .gym
        let sex = defaults.string(forKey: UserProfile.sexKey) ?? ""
        let accentColorRaw = defaults.string(forKey: AppAccentColor.storageKey) ?? AppAccentColor.blue.rawValue

        let tierNumber = achievement.number

        let goals = perGoal.map { (key, value) in
            GoalProgress(
                key: key,
                emoji: emoji(forTrackingKey: key),
                label: label(forTrackingKey: key),
                percent: Int((value * 100).rounded(.down))
            )
        }

        let recentDays = buildRecentDays(records: recentRecords, todayProgress: dailyProgress)

        return WidgetSnapshot(
            progressNormalized: dailyProgress,
            tier: tierNumber,
            tierEmoji: theme.emoji(for: achievement, sex: sex),
            tierName: theme.name(for: achievement, sex: sex),
            accentColorRaw: accentColorRaw,
            recentDays: recentDays,
            goals: goals
        )
    }

    /// Constrói a janela dos últimos 35 dias terminando em hoje.
    /// Dias anteriores usam o `percent` armazenado em `DailyRecord`; hoje usa o progresso parcial.
    /// Dias sem registro ficam com 0%.
    private static func buildRecentDays(records: [DailyRecord], todayProgress: Double) -> [DaySummary] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        var byDay: [Date: Int] = [:]
        for r in records {
            let day = cal.startOfDay(for: r.date)
            byDay[day] = r.percent
        }

        return (0..<35).reversed().map { offset -> DaySummary in
            let day = cal.date(byAdding: .day, value: -offset, to: today) ?? today
            if offset == 0 {
                return DaySummary(date: day, percent: Int((todayProgress * 100).rounded(.down)))
            }
            return DaySummary(date: day, percent: byDay[day] ?? 0)
        }
    }

    // Emoji / label por chave de meta, espelha a tabela em `NotificationKind`.
    private static func emoji(forTrackingKey key: String) -> String {
        switch key {
        case "tracking.workout":  return "🏋️"
        case "tracking.cardio":   return "🏃"
        case "tracking.sleep":    return "💤"
        case "tracking.water":    return "💧"
        case "tracking.calories": return "🔥"
        case "tracking.protein":  return "🍗"
        case "tracking.carbs":    return "🍞"
        case "tracking.goodFat":  return "🧈"
        case "tracking.fiber":    return "🌾"
        case "tracking.creatine": return "🧪"
        default: return "•"
        }
    }

    private static func label(forTrackingKey key: String) -> String {
        let locKey: String
        switch key {
        case "tracking.workout":  locKey = "today.goals.workout"
        case "tracking.cardio":   locKey = "today.goals.cardio"
        case "tracking.sleep":    locKey = "today.metric.sleep"
        case "tracking.water":    locKey = "today.metric.water"
        case "tracking.calories": locKey = "today.metric.calories"
        case "tracking.protein":  locKey = "today.metric.protein"
        case "tracking.carbs":    locKey = "today.metric.carbs"
        case "tracking.goodFat":  locKey = "today.metric.fats"
        case "tracking.fiber":    locKey = "today.metric.fiber"
        case "tracking.creatine": locKey = "today.goals.creatine"
        default: return key
        }
        return String(localized: String.LocalizationValue(locKey), bundle: .gymNutshellCore)
    }

    private static func intakeProgress(key: String, defaults: UserDefaults) -> Double {
        switch key {
        case "tracking.workout":
            if defaults.bool(forKey: "workoutRestDay") { return 1.0 }
            return ProgressHelpers.normalizedProgress(
                current: defaults.integer(forKey: "workoutIntake"),
                goal: GoalsProvider.workout
            )
        case "tracking.cardio":
            if defaults.bool(forKey: "cardioRestDay") { return 1.0 }
            return ProgressHelpers.normalizedProgress(
                current: defaults.integer(forKey: "cardioIntake"),
                goal: GoalsProvider.cardio
            )
        case "tracking.sleep":
            return ProgressHelpers.normalizedProgress(
                current: defaults.integer(forKey: "sleepHours"),
                goal: GoalsProvider.sleep
            )
        case "tracking.water":
            return ProgressHelpers.normalizedProgress(
                current: defaults.integer(forKey: "waterIntake"),
                goal: GoalsProvider.water
            )
        case "tracking.calories":
            return ProgressHelpers.normalizedProgress(
                current: defaults.integer(forKey: "caloriesIntake"),
                goal: GoalsProvider.calories
            )
        case "tracking.protein":
            return ProgressHelpers.normalizedProgress(
                current: defaults.integer(forKey: "proteinIntake"),
                goal: GoalsProvider.protein
            )
        case "tracking.carbs":
            return ProgressHelpers.normalizedProgress(
                current: defaults.integer(forKey: "carbIntake"),
                goal: GoalsProvider.carbs
            )
        case "tracking.goodFat":
            return ProgressHelpers.normalizedProgress(
                current: defaults.integer(forKey: "goodFatIntake"),
                goal: GoalsProvider.goodFat
            )
        case "tracking.fiber":
            return ProgressHelpers.normalizedProgress(
                current: defaults.integer(forKey: "fiberIntake"),
                goal: GoalsProvider.fiber
            )
        case "tracking.creatine":
            return ProgressHelpers.normalizedProgress(
                current: defaults.integer(forKey: "creatineIntake"),
                goal: GoalsProvider.creatine
            )
        default:
            return 0
        }
    }
}
