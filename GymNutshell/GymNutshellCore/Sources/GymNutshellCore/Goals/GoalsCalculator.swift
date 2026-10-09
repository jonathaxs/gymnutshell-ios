// ⌘
//  GymNutshellCore/Goals/GoalsCalculator.swift
//
//  Propósito: Metas diárias padrão por objetivo × sexo (tabela fixa). Desde a 1.1 o app não coleta
//             peso, altura nem idade: os valores partem de um corpo de referência e o usuário ajusta
//             tudo depois com − / +.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-10.
// ⌘

import Foundation

/// Fornece as metas diárias padrão a partir do objetivo de fitness e do sexo.
///
/// Base da tabela: corpo de referência (homem 75 kg / 175 cm / 30 anos; mulher 62 kg / 163 cm / 30 anos),
/// atividade moderada (×1.55), cutting −20% / bulking +15% de calorias, proteína 2.0–2.2 g/kg,
/// água 35 ml/kg e fibra ~14 g por 1000 kcal. Referências: ISSN, EFSA, IOM/AHA, AASM/NSF.
public enum GoalsCalculator {

    // MARK: - Resultado

    /// Guarda todas as metas diárias de um perfil.
    public struct Result: Sendable, Equatable {
        public var calories: Int   // kcal
        public var water: Int      // ml
        public var protein: Int    // g
        public var carbs: Int      // g
        public var goodFat: Int    // g
        public var fiber: Int      // g
        public var sleep: Int      // h (fixo)
        public var creatine: Int   // g (fixo)
        public var workout: Int    // min (fixo = DefaultGoals.workout)
        public var cardio: Int     // min (fixo = DefaultGoals.cardio)

        public init(
            calories: Int,
            water: Int,
            protein: Int,
            carbs: Int,
            goodFat: Int,
            fiber: Int,
            sleep: Int,
            creatine: Int,
            workout: Int,
            cardio: Int
        ) {
            self.calories = calories
            self.water = water
            self.protein = protein
            self.carbs = carbs
            self.goodFat = goodFat
            self.fiber = fiber
            self.sleep = sleep
            self.creatine = creatine
            self.workout = workout
            self.cardio = cardio
        }
    }

    // MARK: - Tabela

    /// Valores variáveis de uma combinação objetivo × sexo.
    private struct Row {
        let calories: Int
        let water: Int
        let protein: Int
        let carbs: Int
        let goodFat: Int
        let fiber: Int
    }

    // Homem: cutting / manutenção / bulking.
    private static let male: [UserGoal: Row] = [
        .cutting:     Row(calories: 2100, water: 2750, protein: 165, carbs: 190, goodFat: 55, fiber: 29),
        .maintenance: Row(calories: 2650, water: 2750, protein: 150, carbs: 260, goodFat: 70, fiber: 37),
        .bulking:     Row(calories: 3050, water: 2750, protein: 150, carbs: 340, goodFat: 85, fiber: 43)
    ]

    // Mulher: cutting / manutenção / bulking.
    private static let female: [UserGoal: Row] = [
        .cutting:     Row(calories: 1650, water: 2250, protein: 135, carbs: 160, goodFat: 45, fiber: 23),
        .maintenance: Row(calories: 2050, water: 2250, protein: 125, carbs: 220, goodFat: 55, fiber: 29),
        .bulking:     Row(calories: 2350, water: 2250, protein: 125, carbs: 280, goodFat: 70, fiber: 33)
    ]

    // MARK: - Cálculo

    /// Metas padrão pro objetivo e sexo informados. Qualquer sexo diferente de "female"
    /// (inclusive o legado "other") usa a coluna masculina.
    public static func calculate(sex: String, goal: UserGoal) -> Result {
        let table = UserProfile.normalizedSex(sex) == "female" ? female : male
        // A tabela cobre todos os UserGoal; o fallback só existe pra não crashar se surgir um caso novo.
        let row = table[goal] ?? table[.maintenance]!

        return Result(
            calories: row.calories,
            water: row.water,
            protein: row.protein,
            carbs: row.carbs,
            goodFat: row.goodFat,
            fiber: row.fiber,
            sleep: DefaultGoals.sleep,
            creatine: DefaultGoals.creatine,
            workout: DefaultGoals.workout,
            cardio: DefaultGoals.cardio
        )
    }
}
