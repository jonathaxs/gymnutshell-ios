// ⌘
//  GymNutshellCore/Stores/RemovedItemsStore.swift
//
//  Propósito: Rastreia quais metas built-in opcionais o usuário escolheu remover.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-14.
// ⌘

import Foundation

public enum RemovedItemsStore {

    public static let removableTrackingKeys: Set<String> = [
        "tracking.goodFat",
        "tracking.creatine"
    ]

    private static let udKey = "app.removedBuiltinItems"

    public static func load() -> Set<String> {
        guard
            let data = UserDefaults.standard.data(forKey: udKey),
            let array = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return Set(array)
    }

    public static func isRemoved(_ key: String) -> Bool {
        load().contains(key)
    }

    public static func remove(_ key: String) {
        var current = load()
        current.insert(key)
        persist(current)
    }

    public static func restore(_ key: String) {
        var current = load()
        current.remove(key)
        persist(current)
    }

    public static func save(_ items: [String]) {
        persist(Set(items))
    }

    private static func persist(_ items: Set<String>) {
        let data = try? JSONEncoder().encode(Array(items))
        UserDefaults.standard.set(data, forKey: udKey)
    }
}
