// ⌘
//  GymNutshellCore/Goals/GoalsProvider.swift
//
//  Propósito: Ponto de acesso único pros valores de metas diárias, lendo do AppStorage definido pelo usuário.
//
//  Created by Jonathas Motta (@jonathaxs) on 2025-12-19.
// ⌘

import Foundation

/// Fornece os valores de metas diárias usados em todo o app.
public enum GoalsProvider {

    // MARK: - Treino
    public static var workout: Int {
        stored(key: "tracking.workout", fallback: DefaultGoals.workout)
    }

    public static var cardio: Int {
        stored(key: "tracking.cardio", fallback: DefaultGoals.cardio)
    }

    // MARK: - Recuperação
    public static var sleep: Int {
        stored(key: "tracking.sleep", fallback: DefaultGoals.sleep)
    }

    // MARK: - Hidratação
    public static var water: Int {
        stored(key: "tracking.water", fallback: DefaultGoals.water)
    }

    // MARK: - Energia
    public static var calories: Int {
        stored(key: "tracking.calories", fallback: DefaultGoals.calories)
    }

    // MARK: - Macros
    public static var protein: Int {
        stored(key: "tracking.protein", fallback: DefaultGoals.protein)
    }

    public static var carbs: Int {
        stored(key: "tracking.carbs", fallback: DefaultGoals.carbs)
    }

    public static var goodFat: Int {
        stored(key: "tracking.goodFat", fallback: DefaultGoals.goodFat)
    }

    // MARK: - Fibra
    public static var fiber: Int {
        stored(key: "tracking.fiber", fallback: DefaultGoals.fiber)
    }

    // MARK: - Suplementos
    public static var creatine: Int {
        stored(key: "tracking.creatine", fallback: DefaultGoals.creatine)
    }

    // MARK: - Todas as metas

    /// Metas atuais do usuário (ou o padrão, onde nada foi definido), no formato do `GoalsCalculator`.
    public static var current: GoalsCalculator.Result {
        GoalsCalculator.Result(
            calories: calories, water: water, protein: protein, carbs: carbs,
            goodFat: goodFat, fiber: fiber, sleep: sleep, creatine: creatine,
            workout: workout, cardio: cardio
        )
    }

    // MARK: - Salvar
    public static func save(_ result: GoalsCalculator.Result) {
        let defaults = UserDefaults.standard
        defaults.set(result.calories, forKey: "tracking.calories")
        defaults.set(result.water,    forKey: "tracking.water")
        defaults.set(result.protein,  forKey: "tracking.protein")
        defaults.set(result.carbs,    forKey: "tracking.carbs")
        defaults.set(result.goodFat,  forKey: "tracking.goodFat")
        defaults.set(result.fiber,    forKey: "tracking.fiber")
        defaults.set(result.sleep,    forKey: "tracking.sleep")
        defaults.set(result.creatine, forKey: "tracking.creatine")
    }

    // MARK: - Helper privado
    private static func stored(key: String, fallback: Int) -> Int {
        let value = UserDefaults.standard.integer(forKey: key)
        return value > 0 ? value : fallback
    }
}
