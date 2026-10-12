// ⌘
//  GymNutshellCore/Stores/MeasurementSystem.swift
//
//  Propósito: Define os três sistemas de medida suportados e fornece o padrão
//             com base no locale do aparelho.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-22.
// ⌘

import Foundation

/// Os dois sistemas de medida suportados pelo app.
public enum MeasurementSystem: String, CaseIterable, Sendable {
    case metric // mililitros
    case us     // fluid ounces (imperial)
}

/// Gerencia a preferência de sistema de medida do usuário.
public enum MeasurementSystemStore {

    public static let key = UserProfile.measurementSystemKey

    public static func detectDefault() -> MeasurementSystem {
        needsChoice ? .us : .metric
    }

    /// Só aparelhos no sistema americano (EUA, Libéria, Mianmar) escolhem na Welcome;
    /// no resto do mundo (inclusive Brasil e Reino Unido) o app já usa métrico.
    public static var needsChoice: Bool {
        Locale.current.measurementSystem == .us
    }

    /// Converte o valor salvo (backup ou versão antiga). "uk" e desconhecidos viram métrico.
    public static func normalized(_ raw: String) -> MeasurementSystem {
        MeasurementSystem(rawValue: raw) ?? .metric
    }
}
