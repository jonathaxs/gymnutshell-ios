// ⌘
//  GymNutshell/GymNutshellApp/Views/SettingsView/Preferences/MeasurementSettingsView.swift
//
//  Propósito: Permite ao usuário escolher entre Métrico (ml) e Imperial (fl oz).
//             Selecionar uma linha salva imediatamente via @AppStorage, sem botão de Salvar.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-22.
// ⌘

import SwiftUI
import GymNutshellCore

/// Tela de settings pra escolher o sistema de medidas (Métrico ou Imperial).
/// Selecionar uma linha aplica a mudança imediatamente. A nova preferência é
/// refletida no Perfil e nas Settings sem precisar reiniciar o app.
struct MeasurementSettingsView: View {

    @AppStorage(UserProfile.measurementSystemKey) private var measurementSystem: MeasurementSystem = .metric

    var body: some View {
        List {
            Section {
                systemRow(.metric)
                systemRow(.us)
            } footer: {
                Text(String(localized: "settings.measurementSystem.footer", bundle: .gymNutshellCore))
            }
        }
        .navigationTitle(String(localized: "settings.preference.measurementSystem", bundle: .gymNutshellCore))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Linha

    /// Linha tocável que exibe o nome do sistema e um checkmark quando está selecionado.
    @ViewBuilder
    private func systemRow(_ system: MeasurementSystem) -> some View {
        let label: String = {
            switch system {
            case .metric: return String(localized: "settings.preference.measurementSystem.metric", bundle: .gymNutshellCore)
            case .us:     return String(localized: "settings.preference.measurementSystem.us", bundle: .gymNutshellCore)
            }
        }()

        let isSelected = measurementSystem == system
        Button {
            measurementSystem = system
        } label: {
            HStack {
                Text(label)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                        .fontWeight(.semibold)
                        .accessibilityHidden(true)
                }
            }
            // Mantém o texto na cor primária mesmo que a linha esteja dentro de um Button.
            .foregroundStyle(.primary)
        }
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
