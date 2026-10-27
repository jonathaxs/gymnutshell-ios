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

    // MARK: - Textos

    public var displayName: String {
        switch self {
        case .standard: return String(localized: "category.kind.standard", bundle: .gymNutshellCore)
        case .restDay:  return String(localized: "category.kind.restDay", bundle: .gymNutshellCore)
        case .checkIn:  return String(localized: "category.kind.checkIn", bundle: .gymNutshellCore)
        }
    }

    /// Explicação curta do tipo, mostrada abaixo do seletor em Ajustes.
    public var settingsFooter: String {
        switch self {
        case .standard: return String(localized: "category.kind.standard.footer", bundle: .gymNutshellCore)
        case .restDay:  return String(localized: "category.kind.restDay.footer", bundle: .gymNutshellCore)
        case .checkIn:  return String(localized: "category.kind.checkIn.footer", bundle: .gymNutshellCore)
        }
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
