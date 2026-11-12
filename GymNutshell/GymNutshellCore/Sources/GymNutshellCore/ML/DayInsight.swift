// ⌘
//  GymNutshellCore/ML/DayInsight.swift
//
//  Propósito: Decide o que a Hoje mostra abaixo da data: a previsão do modelo de "dia de risco"
//             (só se ele ganhou das regras simples na validação) ou, senão, a média daquele dia
//             da semana. Também diz o que mais pesou na previsão, pro balão da data.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-11-12.
// ⌘

import Foundation

// MARK: - O que pesou

/// Grupos de features, na linguagem do usuário. O dia da semana junta as 7 posições do one-hot.
public enum DayInsightFactor: String, CaseIterable, Sendable {
    case weekday, yesterday, lastWeek, streak, sleep, workout, cardio

    /// Posições de `RiskFeatures.vector` que formam cada grupo.
    var featureIndices: [Int] {
        switch self {
        case .weekday:   return Array(0...6)
        case .yesterday: return [7, 8]
        case .lastWeek:  return [9, 10]
        case .streak:    return [11]
        case .sleep:     return [12]
        case .workout:   return [13]
        case .cardio:    return [14]
        }
    }
}

// MARK: - Resultado

public struct DayInsight: Equatable, Sendable {

    public enum Kind: Equatable, Sendable {
        /// Previsão do modelo: chance de dia fraco (0 a 1), acerto na validação e o que mais pesou.
        case model(risk: Double, accuracy: Double, factors: [DayInsightFactor])
        /// Sem modelo confiável: média desse dia da semana e média geral (0 a 100).
        case weekday(average: Int, overall: Int)
    }

    public let kind: Kind
    /// Dia da semana de hoje no Calendar (1 = domingo).
    public let weekday: Int
    /// Quantos dias (antes de hoje) entraram na conta.
    public let dayCount: Int

    /// Hoje tende a ser fraco (risco >= 50% ou média do dia da semana até o limite de dia fraco).
    public var needsAttention: Bool {
        switch kind {
        case .model(let risk, _, _): return risk >= 0.5
        case .weekday(let average, _): return average <= RiskModel.defaultWeakThreshold
        }
    }
}

// MARK: - Montagem

public enum DayInsightBuilder {

    /// Máximo de fatores citados no balão.
    static let maxFactors = 2
    /// Mínimo de registros naquele dia da semana pra média valer.
    static let minimumWeekdayCount = 2

    /// Insight de `date`. Usa só os dias antes dela (o dia de hoje ainda está em andamento).
    /// Devolve nil com menos de `RiskModel.minimumDays` dias ou sem registros suficientes nesse dia da semana.
    public static func make(for date: Date, days: [TrainingDay],
                            calendar: Calendar = .current) -> DayInsight? {
        let today = calendar.startOfDay(for: date)
        let past = days.filter { calendar.startOfDay(for: $0.date) < today }
        guard past.count >= RiskModel.minimumDays else { return nil }
        let weekday = calendar.component(.weekday, from: today)

        // 1. Modelo, se ele ganhou das regras na validação.
        if let report = RiskModel.evaluate(days: past, calendar: calendar), report.beatsBaseline {
            let byDay = RiskFeatures.index(past, calendar: calendar)
            let raw = RiskFeatures.vector(for: today, history: byDay,
                                          weakThreshold: RiskModel.defaultWeakThreshold, calendar: calendar)
            let z = report.standardizer.transform(raw)
            let risk = report.model.probability(z)
            let factors = topFactors(weights: report.model.weights, z: z, towardsWeak: risk >= 0.5)
            return DayInsight(kind: .model(risk: risk, accuracy: report.modelAccuracy, factors: factors),
                              weekday: weekday, dayCount: past.count)
        }

        // 2. Senão, a estatística do dia da semana (não é ML, só média).
        guard let stat = WeekdayStats.averages(days: past, calendar: calendar).first(where: { $0.weekday == weekday }),
              stat.count >= minimumWeekdayCount else { return nil }
        let overall = Double(past.map(\.percent).reduce(0, +)) / Double(past.count)
        return DayInsight(kind: .weekday(average: Int(stat.average.rounded()), overall: Int(overall.rounded())),
                          weekday: weekday, dayCount: past.count)
    }

    /// Contribuição de cada grupo = soma de peso × valor normalizado. Positivo puxa pra dia fraco.
    /// Com risco alto, cita os que mais puxaram pra fraco; com risco baixo, os que mais ajudaram.
    static func topFactors(weights: [Double], z: [Double], towardsWeak: Bool) -> [DayInsightFactor] {
        let scored = DayInsightFactor.allCases.map { factor in
            (factor, factor.featureIndices.reduce(0.0) { $0 + weights[$1] * z[$1] })
        }
        let sign: Double = towardsWeak ? 1 : -1
        return scored
            .filter { $0.1 * sign > 1e-6 }
            .sorted { $0.1 * sign > $1.1 * sign }
            .prefix(maxFactors)
            .map(\.0)
    }
}
