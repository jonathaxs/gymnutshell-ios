// ⌘
//  GymNutshellCore/Models/AppAccentColor.swift
//
//  Propósito: Define as 8 cores de destaque selecionáveis do app (lógica + persistência + SwiftUI).
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-04-15.
// ⌘

import Foundation
import SwiftUI

/// Cor de destaque configurável pelo usuário, usada em ícones de Settings,
/// backgrounds de categoria na TodayView e seleções de tema no onboarding pós-conclusão.
public enum AppAccentColor: String, CaseIterable, Sendable {
    case red
    case blue
    case purple
    case green
    case yellow
    case orange
    case cyan
    case pink

    /// Chave de AppStorage usada pra persistir a escolha de cor do usuário.
    public static let storageKey = "profile.accentColor"

    // MARK: - Nome localizado

    public var displayName: String {
        switch self {
        case .red:    return String(localized: "color.red", bundle: .gymNutshellCore)
        case .blue:   return String(localized: "color.blue", bundle: .gymNutshellCore)
        case .purple: return String(localized: "color.purple", bundle: .gymNutshellCore)
        case .green:  return String(localized: "color.green", bundle: .gymNutshellCore)
        case .yellow: return String(localized: "color.yellow", bundle: .gymNutshellCore)
        case .orange: return String(localized: "color.orange", bundle: .gymNutshellCore)
        case .cyan:   return String(localized: "color.cyan", bundle: .gymNutshellCore)
        case .pink:   return String(localized: "color.pink", bundle: .gymNutshellCore)
        }
    }

    // MARK: - Cor padrão baseada no sexo

    /// Retorna a cor de destaque padrão para o sexo informado.
    /// Usada no onboarding pra salvar a cor inicial antes de o usuário a customizar.
    public static func defaultForSex(_ sex: String) -> AppAccentColor {
        switch sex {
        case "female": return .purple
        default:       return .blue   // "male" e legado "other"/vazio seguem o visual masculino
        }
    }

    // MARK: - SwiftUI Color

    public var color: Color {
        switch self {
        case .red:    return .red
        case .blue:   return .blue
        case .purple: return .purple
        case .green:  return .green
        case .yellow: return .yellow
        case .orange: return .orange
        case .cyan:   return .cyan
        case .pink:   return .pink
        }
    }
}
