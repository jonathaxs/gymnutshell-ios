// ⌘
//  GymNutshellCore/ML/RiskFeatures.swift
//
//  Propósito: Transforma o histórico em números (features) pro modelo de "dia de risco".
//             Cada dia vira um vetor montado só com o que se sabe NO COMEÇO daquele dia
//             (dia da semana e dias anteriores), senão o modelo "cola" vendo o próprio resultado.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-11-10.
// ⌘

import Foundation

// MARK: - Montagem das features

public enum RiskFeatures {

    /// Nome de cada posição do vetor, na mesma ordem de `vector`. Ajuda a ler os pesos na tela de debug.
    public static let names: [String] = [
        "dom", "seg", "ter", "qua", "qui", "sex", "sab",
        "ontem_percent", "ontem_sem_registro", "media_7d", "dias_registrados_7d",
        "sequencia", "ontem_sono", "ontem_treino", "ontem_cardio"
    ]

    /// Índice dos dias por início do dia, pra achar "ontem" e "últimos 7 dias" rápido.
    public static func index(_ days: [TrainingDay], calendar: Calendar) -> [Date: TrainingDay] {
        var byDay: [Date: TrainingDay] = [:]
        for day in days { byDay[calendar.startOfDay(for: day.date)] = day }
        return byDay
    }

    /// Vetor de features do dia `date`, olhando só os dias antes dele.
    public static func vector(for date: Date, history byDay: [Date: TrainingDay],
                              weakThreshold: Int, calendar: Calendar) -> [Double] {
        let today = calendar.startOfDay(for: date)
        func daysAgo(_ n: Int) -> TrainingDay? {
            guard let d = calendar.date(byAdding: .day, value: -n, to: today) else { return nil }
            return byDay[d]
        }

        // Dia da semana em "one-hot": 7 posições, só a do dia vale 1.
        var weekday = [Double](repeating: 0, count: 7)
        weekday[calendar.component(.weekday, from: today) - 1] = 1

        // Ontem. Sem registro conta como 0 e liga a flag "sem registro".
        let yesterday = daysAgo(1)
        let yesterdayPercent = Double(yesterday?.percent ?? 0) / 100
        let yesterdayMissing: Double = yesterday == nil ? 1 : 0

        // Últimos 7 dias: média do percent dos dias registrados e quantos dias tiveram registro.
        let last7 = (1...7).compactMap { daysAgo($0) }
        let mean7 = last7.isEmpty ? 0 : Double(last7.map(\.percent).reduce(0, +)) / Double(last7.count) / 100
        let recorded7 = Double(last7.count) / 7

        // Sequência: dias seguidos antes de hoje acima do limite de dia fraco (até 14).
        var streak = 0
        while streak < 14, let d = daysAgo(streak + 1), d.percent > weakThreshold { streak += 1 }

        return weekday + [
            yesterdayPercent, yesterdayMissing, mean7, recorded7,
            Double(streak) / 14,
            Double(yesterday?.sleep ?? 0),
            yesterday?.didWorkout == true ? 1 : 0,
            yesterday?.didCardio == true ? 1 : 0
        ]
    }
}

// MARK: - Normalização (z-score)

/// Deixa cada feature com média 0 e desvio 1. Sem isso, uma feature grande (sono = 8) pesa
/// mais no gradiente que uma pequena (percent = 0.8) só por causa da escala.
/// A média e o desvio vêm SÓ do treino; a validação usa os mesmos valores.
public struct Standardizer: Equatable, Sendable {
    public let means: [Double]
    public let stds: [Double]

    public init(means: [Double], stds: [Double]) {
        self.means = means
        self.stds = stds
    }

    public init(fitting rows: [[Double]]) {
        let n = Double(rows.count)
        let width = rows.first?.count ?? 0
        var means = [Double](repeating: 0, count: width)
        var stds = [Double](repeating: 1, count: width)
        for j in 0..<width {
            let mean = rows.reduce(0) { $0 + $1[j] } / n
            let variance = rows.reduce(0) { $0 + ($1[j] - mean) * ($1[j] - mean) } / n
            means[j] = mean
            // Feature constante (desvio 0) fica com desvio 1 pra não dividir por zero.
            stds[j] = variance > 1e-12 ? variance.squareRoot() : 1
        }
        self.init(means: means, stds: stds)
    }

    public func transform(_ row: [Double]) -> [Double] {
        row.indices.map { (row[$0] - means[$0]) / stds[$0] }
    }
}
