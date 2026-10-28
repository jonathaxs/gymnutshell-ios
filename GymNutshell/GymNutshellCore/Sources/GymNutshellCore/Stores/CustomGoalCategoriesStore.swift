// ⌘
//  GymNutshellCore/Stores/CustomGoalCategoriesStore.swift
//
//  Propósito: Persiste as categorias criadas pelo usuário como array JSON no UserDefaults.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-04-20.
// ⌘

import Foundation

public enum CustomGoalCategoriesStore {

    private static let key = "customGoalCategories"

    public static func load() -> [CustomGoalCategory] {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let categories = try? JSONDecoder().decode([CustomGoalCategory].self, from: data)
        else { return [] }
        return categories
    }

    public static func save(_ categories: [CustomGoalCategory]) {
        guard let data = try? JSONEncoder().encode(categories) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    public static func upsert(_ category: CustomGoalCategory) {
        var all = load()
        if let index = all.firstIndex(where: { $0.id == category.id }) {
            all[index] = category
        } else {
            all.append(category)
        }
        save(all)
    }

    public static func delete(id: String) {
        var all = load()
        all.removeAll { $0.id == id }
        save(all)
    }
}
