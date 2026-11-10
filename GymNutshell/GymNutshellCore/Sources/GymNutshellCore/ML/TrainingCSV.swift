// ⌘
//  GymNutshellCore/ML/TrainingCSV.swift
//
//  Propósito: Monta um CSV com uma linha por dia registrado, base dos dados de treino do
//             modelo de "dia de risco". Usado pela exportação de debug.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-11-10.
// ⌘

import Foundation

// MARK: - Linha do CSV

/// Um dia do histórico, só com os campos que entram no CSV.
/// Fica separado do DailyRecord pra dar pra testar sem SwiftData.
public struct TrainingDay: Equatable, Sendable {
    public var date: Date
    public var water: Int
    public var protein: Int
    public var carbs: Int
    public var goodFat: Int
    public var fiber: Int
    public var sleep: Int
    public var didWorkout: Bool
    public var didCardio: Bool
    public var workoutRestDay: Bool
    public var cardioRestDay: Bool
    public var percent: Int
    public var points: Int

    public init(date: Date, water: Int, protein: Int, carbs: Int, goodFat: Int, fiber: Int, sleep: Int,
                didWorkout: Bool, didCardio: Bool, workoutRestDay: Bool, cardioRestDay: Bool,
                percent: Int, points: Int) {
        self.date = date
        self.water = water
        self.protein = protein
        self.carbs = carbs
        self.goodFat = goodFat
        self.fiber = fiber
        self.sleep = sleep
        self.didWorkout = didWorkout
        self.didCardio = didCardio
        self.workoutRestDay = workoutRestDay
        self.cardioRestDay = cardioRestDay
        self.percent = percent
        self.points = points
    }

    public init(record: DailyRecord) {
        self.init(date: record.date, water: record.water, protein: record.protein, carbs: record.carbs,
                  goodFat: record.goodFat, fiber: record.fiber, sleep: record.sleep,
                  didWorkout: record.didWorkout, didCardio: record.didCardio,
                  workoutRestDay: record.workoutRestDay, cardioRestDay: record.cardioRestDay,
                  percent: record.percent, points: record.points)
    }
}

// MARK: - Montagem do CSV

public enum TrainingCSV {

    public static let header = "date,weekday,water,protein,carbs,good_fat,fiber,sleep,did_workout,did_cardio,workout_rest_day,cardio_rest_day,percent,points"

    /// Gera o CSV em ordem cronológica. weekday segue o Calendar: 1 = domingo ... 7 = sábado.
    public static func make(days: [TrainingDay], calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        let lines = days.sorted { $0.date < $1.date }.map { d -> String in
            let weekday = calendar.component(.weekday, from: d.date)
            let fields: [String] = [
                formatter.string(from: d.date), "\(weekday)",
                "\(d.water)", "\(d.protein)", "\(d.carbs)", "\(d.goodFat)", "\(d.fiber)", "\(d.sleep)",
                flag(d.didWorkout), flag(d.didCardio), flag(d.workoutRestDay), flag(d.cardioRestDay),
                "\(d.percent)", "\(d.points)"
            ]
            return fields.joined(separator: ",")
        }
        return ([header] + lines).joined(separator: "\n") + "\n"
    }

    private static func flag(_ value: Bool) -> String { value ? "1" : "0" }
}
