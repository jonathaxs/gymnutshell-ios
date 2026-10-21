// ⌘
//  GymNutshellCore/Stores/GoalOrderStore.swift
//
//  Propósito: Persiste a ordem de exibição das nove metas fixas do Gym Nutshell.
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
        "tracking.protein",
        "tracking.carbs",
        "tracking.fiber",
        "tracking.goodFat",
        "tracking.creatine"
    ]

    private static let key = "tracking.fixedOrder"

    public static func load() -> [String] {
        guard let stored = UserDefaults.standard.array(forKey: key) as? [String] else {
            return defaultOrder
        }
        // Ignora chaves de metas que não existem mais pra preservar a ordem de quem atualizou o app.
        let filtered = stored.filter { defaultOrder.contains($0) }
        guard Set(filtered) == Set(defaultOrder) else {
            return defaultOrder
        }
        return filtered
    }

    public static func save(_ order: [String]) {
        let filtered = order.filter { defaultOrder.contains($0) }
        guard Set(filtered) == Set(defaultOrder) else { return }
        UserDefaults.standard.set(filtered, forKey: key)
    }
}
