// ⌘
//  GymNutshellCore/ML/RiskModel.swift
//
//  Propósito: Junta tudo do "dia de risco": monta o dataset, separa treino e validação em
//             ordem de data, treina a regressão logística e compara com duas regras simples.
//             O app só deve mostrar a previsão do modelo se ele ganhar das regras na validação.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-11-10.
// ⌘

import Foundation

// MARK: - Relatório

/// Resultado do treino, pra decidir o que mostrar e pra tela de debug.
public struct RiskModelReport: Sendable {
    public let model: LogisticRegression
    public let standardizer: Standardizer
    public let trainCount: Int
    public let validationCount: Int
    /// Fração de dias fracos no histórico todo.
    public let weakRate: Double
    /// Acertos na validação (0 a 1).
    public let modelAccuracy: Double
    /// Regra "dia da semana": prevê fraco se aquele dia da semana foi fraco em metade ou mais do treino.
    public let weekdayAccuracy: Double
    /// Regra "maioria": chuta sempre a resposta mais comum no treino.
    public let majorityAccuracy: Double

    /// O modelo só vale se ganhar das duas regras (empate não conta).
    public var beatsBaseline: Bool { modelAccuracy > max(weekdayAccuracy, majorityAccuracy) }
}

// MARK: - Modelo de risco

public enum RiskModel {

    /// Dia fraco = percent até 60 (nível 3 ou menos), o dia que quebra o bônus de sequência.
    public static let defaultWeakThreshold = 60
    /// Mínimo de dias registrados pra treinar.
    public static let minimumDays = 21
    /// Fração final do histórico (os dias mais recentes) guardada pra validação.
    public static let validationFraction = 0.2

    /// Treina e avalia. Devolve nil com menos de `minimumDays` dias.
    public static func evaluate(days: [TrainingDay],
                                weakThreshold: Int = defaultWeakThreshold,
                                calendar: Calendar = .current) -> RiskModelReport? {
        guard days.count >= minimumDays else { return nil }

        // 1. Dataset: uma linha por dia registrado, features + rótulo (1 = fraco).
        let sorted = days.sorted { $0.date < $1.date }
        let byDay = RiskFeatures.index(sorted, calendar: calendar)
        let rawX = sorted.map { RiskFeatures.vector(for: $0.date, history: byDay,
                                                    weakThreshold: weakThreshold, calendar: calendar) }
        let y = sorted.map { $0.percent <= weakThreshold ? 1.0 : 0.0 }
        let weekdays = sorted.map { calendar.component(.weekday, from: $0.date) }

        // 2. Separação cronológica: treina no passado, valida no futuro (nunca embaralhar,
        //    senão o modelo "vê" dias vizinhos dos que vai prever).
        let validationCount = max(1, Int((Double(sorted.count) * validationFraction).rounded()))
        let trainCount = sorted.count - validationCount
        let trainRange = 0..<trainCount
        let validationRange = trainCount..<sorted.count

        // 3. Normalização com estatística só do treino.
        let standardizer = Standardizer(fitting: Array(rawX[trainRange]))
        let x = rawX.map(standardizer.transform)

        // 4. Treino.
        let model = LogisticRegression.train(x: Array(x[trainRange]), y: Array(y[trainRange]))

        // 5. Avaliação na validação.
        func accuracy(_ predict: (Int) -> Bool) -> Double {
            let hits = validationRange.filter { predict($0) == (y[$0] == 1) }.count
            return Double(hits) / Double(validationRange.count)
        }
        let modelAccuracy = accuracy { model.probability(x[$0]) >= 0.5 }

        let trainWeakRate = trainRange.reduce(0) { $0 + y[$1] } / Double(trainCount)
        let majorityAccuracy = accuracy { _ in trainWeakRate >= 0.5 }

        var weekdayRate: [Int: (weak: Double, total: Double)] = [:]
        for i in trainRange {
            let current = weekdayRate[weekdays[i], default: (0, 0)]
            weekdayRate[weekdays[i]] = (current.weak + y[i], current.total + 1)
        }
        let weekdayAccuracy = accuracy { i in
            // Dia da semana que não apareceu no treino cai na regra da maioria.
            guard let r = weekdayRate[weekdays[i]] else { return trainWeakRate >= 0.5 }
            return r.weak / r.total >= 0.5
        }

        return RiskModelReport(
            model: model, standardizer: standardizer,
            trainCount: trainCount, validationCount: validationCount,
            weakRate: y.reduce(0, +) / Double(y.count),
            modelAccuracy: modelAccuracy, weekdayAccuracy: weekdayAccuracy,
            majorityAccuracy: majorityAccuracy
        )
    }

    /// Chance de `date` ser um dia fraco, usando o modelo treinado e o histórico até ontem.
    public static func riskProbability(for date: Date, days: [TrainingDay], report: RiskModelReport,
                                       weakThreshold: Int = defaultWeakThreshold,
                                       calendar: Calendar = .current) -> Double {
        let byDay = RiskFeatures.index(days, calendar: calendar)
        let raw = RiskFeatures.vector(for: date, history: byDay, weakThreshold: weakThreshold, calendar: calendar)
        return report.model.probability(report.standardizer.transform(raw))
    }
}
