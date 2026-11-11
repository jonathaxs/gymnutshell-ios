// ⌘
//  GymNutshellCore/ML/WeekdayStats.swift
//
//  Propósito: Calcula a média do percentual diário por dia da semana a partir do histórico.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-11-11.
// ⌘

import Foundation

// MARK: - Média por dia da semana

/// Média de percentual acumulado em um dia da semana.
public struct WeekdayAverage: Equatable, Sendable, Identifiable {
    /// Dia da semana no Calendar (1 = domingo ... 7 = sábado).
    public let weekday: Int
    /// Média do percentual (0 a 100).
    public let average: Double
    /// Quantidade de dias registrados nesse dia da semana.
    public let count: Int

    public var id: Int { weekday }

    public init(weekday: Int, average: Double, count: Int) {
        self.weekday = weekday
        self.average = average
        self.count = count
    }
}

public enum WeekdayStats {

    /// Devolve a média de `percent` por dia da semana (só os dias com pelo menos 1 registro),
    /// ordenados a partir de `calendar.firstWeekday`.
    public static func averages(days: [TrainingDay], calendar: Calendar = .current) -> [WeekdayAverage] {
        var totals: [Int: (sum: Int, count: Int)] = [:]
        for day in days {
            let weekday = calendar.component(.weekday, from: day.date)
            let current = totals[weekday, default: (0, 0)]
            totals[weekday] = (current.sum + day.percent, current.count + 1)
        }

        let first = ((calendar.firstWeekday - 1) % 7 + 7) % 7
        let orderedWeekdays = (0..<7).map { ((first + $0) % 7) + 1 }

        return orderedWeekdays.compactMap { weekday in
            guard let bucket = totals[weekday], bucket.count > 0 else { return nil }
            return WeekdayAverage(
                weekday: weekday,
                average: Double(bucket.sum) / Double(bucket.count),
                count: bucket.count
            )
        }
    }
}
