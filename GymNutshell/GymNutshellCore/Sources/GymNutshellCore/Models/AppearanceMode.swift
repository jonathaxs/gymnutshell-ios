// ⌘
//  GymNutshellCore/Models/AppearanceMode.swift
//
//  Propósito: Modo de aparência do app: segue o dispositivo (padrão), sempre claro ou sempre escuro.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-11-04.
// ⌘

import SwiftUI

public enum AppearanceMode: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    public static let storageKey = "app.appearanceMode"

    public var id: String { rawValue }

    /// `nil` deixa o sistema decidir.
    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    public var title: String {
        // Chave numa constante: interpolar direto no LocalizationValue vira formato ("%@").
        let key = "settings.appearance.mode.\(rawValue)"
        return String(localized: String.LocalizationValue(key), bundle: .gymNutshellCore)
    }

    public var systemImage: String {
        switch self {
        case .system: return "iphone"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }
}
