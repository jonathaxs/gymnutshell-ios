// ⌘
//  GymNutshellCore/Models/StreakBonus.swift
//
//  Propósito: Define o model SwiftData StreakBonus.
//             Cada instância representa um bônus de sequência concedido ao usuário
//             por completar uma semana ou um mês inteiro no nível 3 ou 4.
//             Os bônus saíram do app na 1.1: o model só continua no schema pra o store
//             antigo abrir sem migração. Nada mais cria, lê ou mostra esses registros.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-26.
// ⌘

import Foundation
import SwiftData

// MARK: - StreakBonus

/// Armazena um único bônus de sequência ganho pelo usuário.
@Model
public final class StreakBonus {

    /// Sábado para bônus semanais; último dia do mês para bônus mensais.
    public var anchorDate: Date = Date()

    /// Identifica o tipo de bônus.
    /// Valores possíveis: "weekly.level3", "weekly.level4", "monthly.level3", "monthly.level4"
    public var bonusType: String = ""

    /// Pontos concedidos por esse bônus: 400, 800, 2000 ou 5000.
    public var bonusPoints: Int = 0

    /// O emoji exibido na célula do calendário na data âncora.
    public var bonusEmoji: String = ""

    // MARK: - Inicializador

    public init(anchorDate: Date, bonusType: String, initialPoints: Int, initialEmoji: String) {
        self.anchorDate = anchorDate
        self.bonusType = bonusType
        self.bonusPoints = initialPoints
        self.bonusEmoji = initialEmoji
    }
}
