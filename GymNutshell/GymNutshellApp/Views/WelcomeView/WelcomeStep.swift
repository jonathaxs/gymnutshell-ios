// ⌘
//  GymNutshell/GymNutshellApp/Views/WelcomeView/WelcomeStep.swift
//
//  Propósito: Enum das etapas do onboarding + textos de painel contextual (modo wide).
// ⌘

import Foundation
import GymNutshellCore

enum WelcomeStep: Int, CaseIterable {
    case start
    case goal
    case summary
    case theme

    /// Emoji representativo da etapa, exibido no painel contextual em wide.
    var panelEmoji: String {
        switch self {
        case .start:        return "👋"
        case .goal:         return "🎯"
        case .summary:      return "✅"
        case .theme:        return "🎭"
        }
    }

    /// Título localizado da etapa, repetido entre cabeçalho narrow e painel wide.
    var panelTitle: String {
        switch self {
        case .start:        return String(localized: "welcome.step.start.title", bundle: .gymNutshellCore)
        case .goal:         return String(localized: "welcome.step.goal.title", bundle: .gymNutshellCore)
        case .summary:      return String(localized: "welcome.step.summary.title", bundle: .gymNutshellCore)
        case .theme:        return String(localized: "welcome.step.theme.title", bundle: .gymNutshellCore)
        }
    }

    /// Subtítulo opcional pra manter paridade com o cabeçalho narrow.
    var panelSubtitle: String? {
        switch self {
        case .summary: return String(localized: "welcome.step.summary.subtitle", bundle: .gymNutshellCore)
        case .theme:   return String(localized: "welcome.step.theme.subtitle", bundle: .gymNutshellCore)
        default:       return nil
        }
    }
}
