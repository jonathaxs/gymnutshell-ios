// ⌘
//  GymNutshell/GymNutshellApp/Views/SettingsView/Preferences/ThemeSettingsView.swift
//
//  Propósito: Permite ao usuário escolher o tema do mascote (ex: Gato, Cachorro, Urso...).
//             Cada tema troca os emojis e os nomes dos níveis em todo o app.
//             Os temas são agrupados por categoria pra facilitar a navegação.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-28.
// ⌘

import SwiftUI
import GymNutshellCore

// MARK: - Tela de tema

struct ThemeSettingsView: View {

    @AppStorage(AppTheme.storageKey) private var selectedTheme: AppTheme = .gym
    @AppStorage(UserProfile.sexKey) private var sex: String = "male"
    @AppStorage(AppAccentColor.storageKey) private var storedColorRaw: String = AppAccentColor.blue.rawValue
    private var accentColor: Color { (AppAccentColor(rawValue: storedColorRaw) ?? .blue).color }

    @State private var infoTheme: AppTheme? = nil

    var body: some View {
        List {
            ForEach(AppTheme.ThemeCategory.allCases, id: \.self) { category in
                Section(category.localizedName(sex: sex)) {
                    ForEach(AppTheme.themes(in: category), id: \.self) { theme in
                        let isSelected = selectedTheme == theme
                        let themeName = theme.displayName(sex: sex)
                        HStack(spacing: 8) {
                            // Bloco esquerdo (nome + emojis + check) = elemento único de a11y;
                            // botão Visualizar fica FORA do combine pra ser focável separado.
                            // Mesmo layout da etapa Emoji da Welcome.
                            HStack(spacing: 14) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(themeName)
                                        .font(.body.weight(isSelected ? .semibold : .regular))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)

                                    Text(theme.themeEmojis(sex: sex))
                                        .font(.body)
                                        .lineLimit(1)
                                        .fixedSize()
                                        .accessibilityHidden(true)
                                }

                                Spacer(minLength: 0)

                                Image(systemName: "checkmark")
                                    .font(.body.weight(.bold))
                                    .foregroundStyle(accentColor)
                                    .opacity(isSelected ? 1 : 0)
                                    .accessibilityHidden(true)
                            }
                            .contentShape(Rectangle())
                            .tapButton { selectedTheme = theme }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(themeName)
                            .accessibilityValue(isSelected
                                                ? String(localized: "a11y.selected", bundle: .gymNutshellCore)
                                                : String(localized: "a11y.not.selected", bundle: .gymNutshellCore))
                            .accessibilityHint(String(localized: "a11y.theme.hint", bundle: .gymNutshellCore))

                            Button {
                                infoTheme = theme
                            } label: {
                                Text(String(localized: "welcome.theme.preview", bundle: .gymNutshellCore))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.primary)
                                    .lineLimit(1)
                            }
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.capsule)
                            .controlSize(.regular)
                            .tint(.gray)
                            .accessibilityLabel(String(format: String(localized: "a11y.theme.info.label.format",
                                                                     bundle: .gymNutshellCore), themeName))
                            .accessibilityHint(String(localized: "a11y.theme.info.hint", bundle: .gymNutshellCore))
                        }
                        .padding(.vertical, 8)
                        // Selecionado: fundo do card com um véu da cor de destaque (o véu sozinho deixaria a linha transparente).
                        .listRowBackground(isSelected
                                           ? Color(.secondarySystemGroupedBackground).overlay(accentColor.opacity(0.12))
                                           : nil)
                    }
                }
            }
        }
        .navigationTitle(String(localized: "settings.theme.title", bundle: .gymNutshellCore))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $infoTheme) { theme in
            NavigationStack {
                ThemeInfoView(theme: theme, sex: sex)
            }
        }
    }
}
