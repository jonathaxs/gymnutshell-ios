// ⌘
//  GymNutshellCore/Services/UnitConverter.swift
//
//  Propósito: Converte a água entre ml e fl oz (sistema imperial).
//             O app sempre guarda a água em ml internamente.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-22.
// ⌘

import Foundation

/// Converte a água entre ml e fl oz.
public enum UnitConverter {

    // MARK: - Água

    /// No Reino Unido o "fl oz" é a onça britânica (28,41 ml); no resto, a americana (29,57 ml).
    private static var usesImperialFlOz: Bool { Locale.current.region == .unitedKingdom }

    public static var mlPerFlOz: Double { usesImperialFlOz ? 28.4131 : 29.5735 }

    /// Passo padrão da água em fl oz: 8 (um copo americano) ou 10 (meio pint britânico).
    public static var flOzWaterStep: Int { usesImperialFlOz ? 10 : 8 }

    public static func mlToFlOz(_ ml: Double) -> Double {
        ml / mlPerFlOz
    }

    public static func flOzToMl(_ flOz: Double) -> Double {
        flOz * mlPerFlOz
    }
}
