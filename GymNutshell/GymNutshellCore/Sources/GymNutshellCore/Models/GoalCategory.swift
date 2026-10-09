// ⌘
//  GymNutshellCore/Models/GoalCategory.swift
//
//  Propósito: Define as cinco categorias usadas pra agrupar metas fixas e personalizadas.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-04-14.
// ⌘

import Foundation

/// Categorias usadas pra agrupar as metas de rastreio fixas e personalizadas.
/// A ordem dos cases define a ordem de exibição nas telas (Essencial primeiro).
public enum GoalCategory: String, Codable, CaseIterable, Sendable {

    case essencial
    case nutricao
    case treino
    case suplemento

    // MARK: - Nome localizado

    public var displayName: String {
        switch self {
        case .essencial:  return String(localized: "goal.category.essencial", bundle: .gymNutshellCore)
        case .nutricao:   return String(localized: "goal.category.nutricao", bundle: .gymNutshellCore)
        case .treino:     return String(localized: "goal.category.treino", bundle: .gymNutshellCore)
        case .suplemento: return String(localized: "goal.category.suplemento", bundle: .gymNutshellCore)
        }
    }

    // MARK: - Ícone (SF Symbol)

    /// Ícone da categoria nos blocos da tela Hoje.
    public var symbolName: String {
        switch self {
        case .essencial:  return "heart.fill"
        case .nutricao:   return "fork.knife"
        case .treino:     return "dumbbell.fill"
        case .suplemento: return "pills.fill"
        }
    }

    // MARK: - Mapeamento de chaves fixas

    /// Categoria padrão de uma chave de meta fixa.
    public static func defaultCategory(for key: String) -> GoalCategory? {
        switch key {
        case "tracking.sleep", "tracking.water":
            return .essencial
        case "tracking.calories", "tracking.protein", "tracking.carbs", "tracking.goodFat", "tracking.fiber":
            return .nutricao
        case "tracking.workout", "tracking.cardio":
            return .treino
        case "tracking.creatine":
            return .suplemento
        default:
            return nil
        }
    }
}
