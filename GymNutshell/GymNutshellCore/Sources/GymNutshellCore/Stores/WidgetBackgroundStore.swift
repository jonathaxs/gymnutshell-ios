// ⌘
//  GymNutshellCore/Stores/WidgetBackgroundStore.swift
//
//  Propósito: Persiste a WidgetBackground escolhida pelo usuário no App Group
//             compartilhado com o widget extension. A flag separada `enabled`
//             permite manter a última cor escolhida mesmo quando o usuário
//             desliga o toggle, evitando perder a seleção.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-05-12.
// ⌘

import Foundation

/// Modos de fundo do widget escolhidos pelo usuário em Ajustes › Widgets.
public enum WidgetBackgroundMode: String, Codable, Sendable, CaseIterable {
    case system    // Fundo padrão do iOS (preto/branco conforme tema)
    case accent    // Cor de destaque do app
    case custom    // Cor personalizada escolhida no ColorPicker
}

public enum WidgetBackgroundStore {

    private static let appGroupID = "group.com.jonathaxs.gymnutshell"
    public static let storageKey = "widget.background.v1"
    public static let modeKey = "widget.background.mode"

    /// Lê o modo de fundo selecionado pelo usuário. Default é `.system`:
    /// novos usuários veem os widgets com o fundo padrão do iOS.
    public static func loadMode() -> WidgetBackgroundMode {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let raw = defaults.string(forKey: modeKey),
              let mode = WidgetBackgroundMode(rawValue: raw) else {
            return .system
        }
        return mode
    }

    /// Lê a cor personalizada salva (independente do modo atual).
    /// Usada tanto pelo widget (quando mode == .custom) quanto pelo settings view
    /// pra repopular o ColorPicker.
    public static func loadCustomColor() -> WidgetBackground? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: storageKey),
              let bg = try? JSONDecoder().decode(WidgetBackground.self, from: data) else {
            return nil
        }
        return bg
    }

    public static func saveCustomColor(_ background: WidgetBackground) {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = try? JSONEncoder().encode(background) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
