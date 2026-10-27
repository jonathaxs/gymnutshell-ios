// ⌘
//  GymNutshellCore/Models/CategoryKind.swift
//
//  Propósito: Tipo de uma categoria de metas, que define o controle mostrado na tela Hoje.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-10-26.
// ⌘

import Foundation

/// Tipo de categoria. Define como as metas dela são registradas na tela Hoje.
/// - `standard`: slider ou botões − / + (estilo global).
/// - `restDay`: igual ao padrão, mais o botão ON/OFF de dia de descanso.
/// - `checkIn`: seletor Pendente | Feito. Feito grava o valor da meta; Pendente grava 0.
public enum CategoryKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case standard
    case restDay
    case checkIn

    public var id: String { rawValue }

    /// Desconhecido (backup de versão futura) cai no padrão.
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = CategoryKind(rawValue: raw) ?? .standard
    }

    // MARK: - Check-in

    /// Valor gravado ao marcar Feito/Pendente numa meta check-in.
    public static func checkInValue(done: Bool, goal: Int) -> Int {
        done ? max(goal, 1) : 0
    }

    /// Uma meta check-in conta como feita quando o valor atual alcança a meta.
    /// Valor parcial (registro antigo em partes) aparece como Pendente.
    public static func isCheckInDone(current: Int, goal: Int) -> Bool {
        current > 0 && current >= goal
    }
}
