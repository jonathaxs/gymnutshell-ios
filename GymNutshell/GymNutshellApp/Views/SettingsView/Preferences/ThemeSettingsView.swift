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
                        HStack {
                            // Bloco esquerdo (prévia + nome + check) = elemento único de a11y;
                            // botão de info fica FORA do combine pra ser focável separado.
                            HStack {
                                Text(theme.themeEmojis(sex: sex))
                                    .font(.title3)
                                    .accessibilityHidden(true)

                                Text(themeName)
                                    .foregroundColor(isSelected ? .white : Color.primary)

                                Spacer()

                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                        .font(.subheadline.weight(.bold))
                                        .accessibilityHidden(true)
                                }
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
                                Image(systemName: "info.circle")
                                .font(.title2)
                                .frame(minWidth: 44, minHeight: 44)
                            }
                            .buttonStyle(.borderless)
                            .tint(isSelected ? .white : .accentColor)
                            .accessibilityLabel(String(format: String(localized: "a11y.theme.info.label.format",
                                                                     bundle: .gymNutshellCore), themeName))
                            .accessibilityHint(String(localized: "a11y.theme.info.hint", bundle: .gymNutshellCore))
                        }
                        .listRowBackground(isSelected ? accentColor : nil)
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
