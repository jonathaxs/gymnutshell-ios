// ⌘
//  GymNutshellCore/Models/BackupPayload.swift
//
//  Propósito: Estruturas Codable que representam o estado completo do app num arquivo JSON de backup.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-28.
// ⌘

import Foundation

// MARK: - BackupPayload

/// Estrutura raiz do arquivo JSON de backup.
/// Todos os tipos internos são Codable pra poder ser lidos por outras ferramentas se precisar.
public struct BackupPayload: Codable, Sendable {

    public let version: Int
    public let exportedAt: Date
    public let profile: ProfileSnapshot
    public let goals: GoalsSnapshot
    public let goalsOrder: [String]
    public let customGoals: [CustomTrackingGoal]
    public let removedItems: [String]?
    public let dailyRecords: [RecordSnapshot]

    public let appearance: AppearanceSnapshot?
    public let customCategories: [CustomGoalCategory]?
    public let categoryOrder: [String]?
    public let builtinCategoryOrder: [String]?
    public let preferences: PreferencesSnapshot?

    public init(
        version: Int,
        exportedAt: Date,
        profile: ProfileSnapshot,
        goals: GoalsSnapshot,
        goalsOrder: [String],
        customGoals: [CustomTrackingGoal],
        removedItems: [String]?,
        dailyRecords: [RecordSnapshot],
        appearance: AppearanceSnapshot?,
        customCategories: [CustomGoalCategory]?,
        categoryOrder: [String]?,
        builtinCategoryOrder: [String]?,
        preferences: PreferencesSnapshot?
    ) {
        self.version = version
        self.exportedAt = exportedAt
        self.profile = profile
        self.goals = goals
        self.goalsOrder = goalsOrder
        self.customGoals = customGoals
        self.removedItems = removedItems
        self.dailyRecords = dailyRecords
        self.appearance = appearance
        self.customCategories = customCategories
        self.categoryOrder = categoryOrder
        self.builtinCategoryOrder = builtinCategoryOrder
        self.preferences = preferences
    }

    public struct ProfileSnapshot: Codable, Sendable {
        public let name: String
        public let username: String?
        public let height: Int
        public let weight: Double
        public let age: Int
        public let sex: String
        /// Objetivo principal do usuário. JSON mantém a chave `fitnessGoal` pra compatibilidade
        /// com backups exportados antes do rename (v1..v3).
        public let userGoal: String
        public let measurementSystem: String?

        public init(
            name: String,
            username: String?,
            height: Int,
            weight: Double,
            age: Int,
            sex: String,
            userGoal: String,
            measurementSystem: String?
        ) {
            self.name = name
            self.username = username
            self.height = height
            self.weight = weight
            self.age = age
            self.sex = sex
            self.userGoal = userGoal
            self.measurementSystem = measurementSystem
        }

        enum CodingKeys: String, CodingKey {
            case name, username, height, weight, age, sex, measurementSystem
            case userGoal = "fitnessGoal"
        }
    }

    /// Preferências diversas persistidas em UserDefaults (widget, orientação, notificações,
    /// incrementos das metas). Tudo opcional pra manter compatibilidade com backups v1..v3.
    /// Notificações e incrementos usam dicionários genéricos pra não precisar editar este
    /// arquivo a cada meta/tipo novo.
    public struct PreferencesSnapshot: Codable, Sendable {
        public let widgetBackground: String?       // widget.background.v1
        public let widgetBackgroundMode: String?   // widget.background.mode
        public let orientationLock: String?        // app.orientation.lock
        public let autoWorkoutCheckin: Bool?       // healthkit.autoWorkoutCheckin
        public let controlStyle: String?           // app.controlStyle (slider | stepper), novo na 1.1
        /// id da notificação ("<kind>" ou "custom.<uuid>") → valor.
        public let notificationEnabled: [String: Bool]?
        public let notificationInterval: [String: Int]?
        public let notificationSound: [String: String]?
        /// Chave completa do incremento ("tracking.X.increment") → passo.
        public let goalIncrements: [String: Int]?

        public init(
            widgetBackground: String?,
            widgetBackgroundMode: String?,
            orientationLock: String?,
            autoWorkoutCheckin: Bool?,
            controlStyle: String? = nil,
            notificationEnabled: [String: Bool]?,
            notificationInterval: [String: Int]?,
            notificationSound: [String: String]?,
            goalIncrements: [String: Int]?
        ) {
            self.widgetBackground = widgetBackground
            self.widgetBackgroundMode = widgetBackgroundMode
            self.orientationLock = orientationLock
            self.autoWorkoutCheckin = autoWorkoutCheckin
            self.controlStyle = controlStyle
            self.notificationEnabled = notificationEnabled
            self.notificationInterval = notificationInterval
            self.notificationSound = notificationSound
            self.goalIncrements = goalIncrements
        }
    }

    /// Preferências visuais do usuário, persistidas em UserDefaults via @AppStorage.
    public struct AppearanceSnapshot: Codable, Sendable {
        public let theme: String
        public let accentColor: String

        public init(theme: String, accentColor: String) {
            self.theme = theme
            self.accentColor = accentColor
        }
    }

    public struct GoalsSnapshot: Codable, Sendable {
        public let calories: Int
        public let sleep: Int
        public let water: Int
        public let protein: Int
        public let carbs: Int
        public let goodFat: Int
        public let fiber: Int

        public init(calories: Int, sleep: Int, water: Int, protein: Int, carbs: Int, goodFat: Int, fiber: Int) {
            self.calories = calories
            self.sleep = sleep
            self.water = water
            self.protein = protein
            self.carbs = carbs
            self.goodFat = goodFat
            self.fiber = fiber
        }

        enum CodingKeys: String, CodingKey {
            case calories, sleep, water, protein, carbs, fiber
            case goodFat = "fats"
        }

        /// Decodificação tolerante: backups v3 e anteriores não têm `calories`,
        /// nesse caso caímos no default do app pra não quebrar a restauração.
        public init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.calories = try c.decodeIfPresent(Int.self, forKey: .calories) ?? DefaultGoals.calories
            self.sleep    = try c.decode(Int.self, forKey: .sleep)
            self.water    = try c.decode(Int.self, forKey: .water)
            self.protein  = try c.decode(Int.self, forKey: .protein)
            self.carbs    = try c.decode(Int.self, forKey: .carbs)
            self.goodFat  = try c.decode(Int.self, forKey: .goodFat)
            self.fiber    = try c.decode(Int.self, forKey: .fiber)
        }
    }

    /// Representação simples de um DailyRecord pra serialização em JSON.
    public struct RecordSnapshot: Codable, Sendable {
        public let date: Date
        public let water: Int
        public let protein: Int
        public let carbs: Int
        public let goodFat: Int
        public let fiber: Int
        public let sleep: Int
        public let percent: Int
        public let achievementTitle: String
        public let achievementEmoji: String
        public let points: Int
        public let didWorkout: Bool
        public let didCardio: Bool?
        public let customValues: [String: Int]

        public init(
            date: Date,
            water: Int,
            protein: Int,
            carbs: Int,
            goodFat: Int,
            fiber: Int,
            sleep: Int,
            percent: Int,
            achievementTitle: String,
            achievementEmoji: String,
            points: Int,
            didWorkout: Bool,
            didCardio: Bool?,
            customValues: [String: Int]
        ) {
            self.date = date
            self.water = water
            self.protein = protein
            self.carbs = carbs
            self.goodFat = goodFat
            self.fiber = fiber
            self.sleep = sleep
            self.percent = percent
            self.achievementTitle = achievementTitle
            self.achievementEmoji = achievementEmoji
            self.points = points
            self.didWorkout = didWorkout
            self.didCardio = didCardio
            self.customValues = customValues
        }

        enum CodingKeys: String, CodingKey {
            case date, water, protein, fiber, sleep, percent, points, didWorkout, didCardio, customValues
            case carbs = "carb"
            case goodFat = "fat"
            case achievementTitle = "catTitle"
            case achievementEmoji = "catEmoji"
        }
    }
}
