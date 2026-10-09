// ⌘
//  GymNutshellCore/Models/UserProfile.swift
//
//  Propósito: Centraliza as chaves AppStorage dos dados de perfil coletados no onboarding.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-10.
// ⌘

import Foundation

/// Centraliza todas as chaves AppStorage relacionadas ao perfil do usuário.
/// Esses valores são coletados no onboarding e usados pra calcular as metas diárias.
public enum UserProfile {

    // MARK: - Chaves
    public static let nameKey                   = "profile.name"
    public static let sexKey                    = "profile.sex"         // "male" / "female" (legado "other" vira "male")
    public static let userGoalKey               = "profile.userGoal"
    public static let favoriteExerciseKey       = "profile.favoriteExercise"
    public static let didCompleteOnboardingKey  = "profile.didCompleteOnboarding"
    public static let measurementSystemKey      = "profile.measurementSystem"
    public static let themeKey                  = AppTheme.storageKey
    public static let colorKey                  = AppAccentColor.storageKey

    // MARK: - Chaves de navegação
    public static let selectedTabKey                  = "app.selectedTab"
    public static let achievementsSelectedDateKey     = "achievements.selectedDate"
    public static let achievementsFilterModeKey       = "achievements.filterMode"

    // MARK: - Migração da 1.0 → 1.1

    /// Chaves de dados físicos que existiam na 1.0 e foram removidas na 1.1.
    private static let legacyPhysicalKeys = [
        "profile.weight", "profile.height", "profile.age", "profile.birthday"
    ]

    /// Sexo só pode ser "male" ou "female". Qualquer outro valor (ex: "other" da 1.0) vira "male".
    public static func normalizedSex(_ raw: String) -> String {
        raw == "female" ? "female" : "male"
    }

    /// Roda no launch: apaga os dados físicos antigos (a 1.1 não usa mais) e normaliza o sexo
    /// salvo. Não mexe nas metas já definidas, quem veio da 1.0 mantém os valores que tinha.
    public static func migrateLegacyProfile(defaults: UserDefaults = .standard) {
        legacyPhysicalKeys.forEach { defaults.removeObject(forKey: $0) }
        if let sex = defaults.string(forKey: sexKey), sex != normalizedSex(sex) {
            defaults.set(normalizedSex(sex), forKey: sexKey)
        }
    }
}

/// Easter egg, exercício/grupo muscular favorito do usuário.
public enum FavoriteExercise: String, CaseIterable, Identifiable, Sendable {
    case unknown
    case back
    case arms
    case chest
    case legs
    case hamstrings
    case glutes
    case shoulders
    case biceps
    case triceps
    case abs
    case traps
    case forearms
    case calves

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .unknown:    return String(localized: "favoriteExercise.unknown", bundle: .gymNutshellCore)
        case .back:       return String(localized: "favoriteExercise.back", bundle: .gymNutshellCore)
        case .arms:       return String(localized: "favoriteExercise.arms", bundle: .gymNutshellCore)
        case .chest:      return String(localized: "favoriteExercise.chest", bundle: .gymNutshellCore)
        case .legs:       return String(localized: "favoriteExercise.legs", bundle: .gymNutshellCore)
        case .hamstrings: return String(localized: "favoriteExercise.hamstrings", bundle: .gymNutshellCore)
        case .glutes:     return String(localized: "favoriteExercise.glutes", bundle: .gymNutshellCore)
        case .shoulders:  return String(localized: "favoriteExercise.shoulders", bundle: .gymNutshellCore)
        case .biceps:     return String(localized: "favoriteExercise.biceps", bundle: .gymNutshellCore)
        case .triceps:    return String(localized: "favoriteExercise.triceps", bundle: .gymNutshellCore)
        case .abs:        return String(localized: "favoriteExercise.abs", bundle: .gymNutshellCore)
        case .traps:      return String(localized: "favoriteExercise.traps", bundle: .gymNutshellCore)
        case .forearms:   return String(localized: "favoriteExercise.forearms", bundle: .gymNutshellCore)
        case .calves:     return String(localized: "favoriteExercise.calves", bundle: .gymNutshellCore)
        }
    }
}

/// Representa o objetivo principal do usuário.
/// Usado pra ajustar os cálculos de macros no onboarding e nas Configurações.
public enum UserGoal: String, CaseIterable, Identifiable, Sendable {
    case bulking
    case maintenance
    case cutting

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .bulking:
            return String(localized: "fitness.goal.bulking", bundle: .gymNutshellCore)
        case .maintenance:
            return String(localized: "fitness.goal.maintenance", bundle: .gymNutshellCore)
        case .cutting:
            return String(localized: "fitness.goal.cutting", bundle: .gymNutshellCore)
        }
    }
}
