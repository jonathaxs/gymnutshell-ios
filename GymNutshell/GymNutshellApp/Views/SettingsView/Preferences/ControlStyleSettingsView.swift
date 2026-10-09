// ⌘
//  GymNutshell/GymNutshellApp/Views/SettingsView/Preferences/ControlStyleSettingsView.swift
//
//  Propósito: Troca o estilo dos controles de registro das metas (slider ou botões − / +).
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-10-08.
// ⌘

import SwiftUI
import GymNutshellCore

/// Tela de Ajustes com as duas opções de controle; toque aplica na hora.
struct ControlStyleSettingsView: View {

    @AppStorage(ControlStyle.storageKey) private var styleRaw: String = ControlStyle.default.rawValue

    var body: some View {
        List {
            Section {
                row(.slider,
                    title: String(localized: "welcome.control.slider", bundle: .gymNutshellCore),
                    desc: String(localized: "welcome.control.slider.desc", bundle: .gymNutshellCore))
                row(.stepper,
                    title: String(localized: "welcome.control.stepper", bundle: .gymNutshellCore),
                    desc: String(localized: "welcome.control.stepper.desc", bundle: .gymNutshellCore))
            } footer: {
                Text(String(localized: "settings.controlStyle.footer", bundle: .gymNutshellCore))
            }
        }
        .navigationTitle(String(localized: "settings.preference.controlStyle", bundle: .gymNutshellCore))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ style: ControlStyle, title: String, desc: String) -> some View {
        let isSelected = styleRaw == style.rawValue
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(desc).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
            }
        }
        .contentShape(Rectangle())
        .tapButton { styleRaw = style.rawValue }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected
                            ? String(localized: "a11y.selected", bundle: .gymNutshellCore)
                            : String(localized: "a11y.not.selected", bundle: .gymNutshellCore))
    }
}
