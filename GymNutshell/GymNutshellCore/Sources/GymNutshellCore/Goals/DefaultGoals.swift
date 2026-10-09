// ⌘
//  GymNutshellCore/Goals/DefaultGoals.swift
//
//  Propósito: Centraliza os valores padrão das metas diárias usadas pelo app.
//
//  Created by Jonathas Motta (@jonathaxs) on 2025-12-19.
// ⌘

import Foundation

/// Centraliza as metas diárias padrão do app.
/// Esses valores representam o baseline inicial usado pelo app.
/// No futuro, deveriam vir das configurações definidas pelo usuário.
public enum DefaultGoals {
    // MARK: - Treino
    public static let workout: Int = 50
    public static let workoutIncrement: Int = 15
    public static let cardio: Int = 15
    public static let cardioIncrement: Int = 5

    // MARK: - Recuperação
    public static let sleep: Int = 8

    // MARK: - Hidratação
    public static let water: Int = 3000

    // MARK: - Energia
    public static let calories: Int = 2000
    public static let caloriesIncrement: Int = 50

    // MARK: - Macros
    public static let protein: Int = 150
    public static let carbs: Int = 300
    public static let goodFat: Int = 80

    // MARK: - Fibra
    public static let fiber: Int = 25

    // MARK: - Suplementos
    public static let creatine: Int = 5
    public static let creatineIncrement: Int = 1
}
