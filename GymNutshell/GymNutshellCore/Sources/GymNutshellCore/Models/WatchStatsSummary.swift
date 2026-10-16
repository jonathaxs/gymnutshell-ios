// ⌘
//  GymNutshellCore/Models/WatchStatsSummary.swift
//
//  Propósito: Snapshot de estatísticas calculado no iPhone e enviado pro Watch
//             via WatchConnectivity. Watch apenas decodifica e renderiza.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-04-29.
// ⌘

import Foundation

public struct WatchStatsSummary: Codable, Sendable {

    /// Um dia dentro dos últimos 7, emoji da conquista e percentual concluído.
    public struct DayEntry: Codable, Sendable {
        public let emoji: String    // vazio se não há registro naquele dia
        public let percent: Int
        public init(emoji: String, percent: Int) {
            self.emoji = emoji
            self.percent = percent
        }
    }

    public let totalDays: Int
    public let totalPoints: Int
    public let level1Days: Int
    public let level2Days: Int
    public let level3Days: Int
    public let level4Days: Int
    public let level5Days: Int
    public let workoutDays: Int
    public let cardioDays: Int
    /// 7 entradas, da mais antiga pra mais recente.
    public let last7Days: [DayEntry]
    public let updatedAt: Date
}

// MARK: - Inicialização a partir dos dados do SwiftData (iOS only)

import SwiftData

extension WatchStatsSummary {

    public init(records: [DailyRecord]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        totalDays   = records.count
        totalPoints = records.reduce(0) { $0 + $1.points }

        level1Days = records.filter { DailyAchievement.from(emoji: $0.achievementEmoji) == .level1 }.count
        level2Days = records.filter { DailyAchievement.from(emoji: $0.achievementEmoji) == .level2 }.count
        level3Days = records.filter { DailyAchievement.from(emoji: $0.achievementEmoji) == .level3 }.count
        level4Days = records.filter { DailyAchievement.from(emoji: $0.achievementEmoji) == .level4 }.count
        level5Days = records.filter { DailyAchievement.from(emoji: $0.achievementEmoji) == .level5 }.count

        workoutDays = records.filter { $0.didWorkout }.count
        cardioDays  = records.filter { $0.didCardio  }.count

        last7Days = (0..<7).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            if let rec = records.first(where: { calendar.startOfDay(for: $0.date) == day }) {
                return DayEntry(emoji: rec.achievementEmoji, percent: rec.percent)
            }
            return DayEntry(emoji: "", percent: 0)
        }

        updatedAt = Date()
    }
}
