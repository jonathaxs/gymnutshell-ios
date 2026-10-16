// ⌘
//  GymNutshellCore/Services/UnitConverter.swift
//
//  Propósito: Converte valores de peso e altura entre unidades métricas e imperiais.
//             O app sempre guarda valores em kg e cm internamente.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-22.
// ⌘

import Foundation

/// Converte peso e altura entre unidades métricas e imperiais.
public enum UnitConverter {

    // MARK: - Peso (US: libras)

    public static func kgToLbs(_ kg: Double) -> Double {
        kg * 2.20462
    }

    public static func lbsToKg(_ lbs: Double) -> Double {
        lbs / 2.20462
    }

    // MARK: - Peso (UK: stones + libras)

    public static func kgToStoneLbs(_ kg: Double) -> (stones: Int, lbs: Int) {
        let totalLbs = kg * 2.20462
        let stones = Int(totalLbs / 14)
        let remainingLbs = Int(totalLbs.rounded()) - stones * 14
        return (stones, remainingLbs)
    }

    public static func stoneLbsToKg(stones: Int, lbs: Int) -> Double {
        Double(stones * 14 + lbs) / 2.20462
    }

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

    // MARK: - Altura

    public static func cmToFeetAndInches(_ cm: Int) -> (feet: Int, inches: Int) {
        let totalInches = Int((Double(cm) / 2.54).rounded())
        return (totalInches / 12, totalInches % 12)
    }

    public static func feetAndInchesToCm(feet: Int, inches: Int) -> Int {
        Int((Double(feet * 12 + inches) * 2.54).rounded())
    }
}
