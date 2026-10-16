// ⌘
//  GymNutshellCore/Stores/GoalOrderStore.swift
//
//  Propósito: Persiste a ordem de exibição das dez metas fixas do Gym Nutshell.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-12.
// ⌘

import Foundation

public enum GoalOrderStore {

    public static let defaultOrder: [String] = [
        "tracking.workout",
        "tracking.cardio",
        "tracking.sleep",
        "tracking.water",
        "tracking.calories",
        "tracking.protein",
        "tracking.carbs",
        "tracking.fiber",
        "tracking.goodFat",
        "tracking.creatine"
    ]

    private static let key = "tracking.fixedOrder"

    public static func load() -> [String] {
        guard
            let stored = UserDefaults.standard.array(forKey: key) as? [String],
            Set(stored) == Set(defaultOrder)
        else {
            return defaultOrder
        }
        return stored
    }

    public static func save(_ order: [String]) {
        guard Set(order) == Set(defaultOrder) else { return }
        UserDefaults.standard.set(order, forKey: key)
    }
}
