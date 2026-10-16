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

    /// Imperial só de cara no sistema americano (EUA, Libéria, Mianmar); no resto, métrico.
    public static func detectDefault() -> MeasurementSystem {
        Locale.current.measurementSystem == .us ? .us : .metric
    }

    /// Regiões fora do métrico (sistema americano e Reino Unido) escolhem na Welcome;
    /// no resto do mundo (inclusive Brasil) o app já usa métrico sem perguntar.
    public static var needsChoice: Bool {
        Locale.current.measurementSystem != .metric
    }

    /// Converte o valor salvo (backup ou versão antiga). "uk" e desconhecidos viram métrico.
    public static func normalized(_ raw: String) -> MeasurementSystem {
        MeasurementSystem(rawValue: raw) ?? .metric
    }
}
