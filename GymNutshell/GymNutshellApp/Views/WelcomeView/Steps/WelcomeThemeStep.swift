// ⌘
//  GymNutshell/GymNutshellApp/Views/WelcomeView/Steps/WelcomeThemeStep.swift
//
//  Propósito: Etapa do onboarding, permite ao usuário escolher o tema do mascote
//             antes de ver o resumo das metas. A seleção é devolvida via binding
//             e persistida no fim do onboarding. Os temas são exibidos agrupados por categoria.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-28.
// ⌘

import SwiftUI
import GymNutshellCore

/// Etapa do onboarding: exibe um card selecionável pra cada AppTheme disponível,
/// agrupado por categoria com cabeçalhos de seção.
struct WelcomeThemeStep: View {

    @Binding var selectedTheme: AppTheme
    var sex: String = "male"
    let accentColor: Color
    var isWide: Bool = false

    @State private var infoTheme: AppTheme? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                if !isWide {
                    WelcomeStepHeader(
                        emoji: "🎭",
                        title: String(localized: "welcome.step.theme.title", bundle: .gymNutshellCore),
                        subtitle: String(localized: "welcome.step.theme.subtitle", bundle: .gymNutshellCore)
                    )
                }

                // Uma seção por categoria, cada uma com cabeçalho e cards de tema.
                ForEach(AppTheme.ThemeCategory.allCases, id: \.self) { category in
                    VStack(alignment: .leading, spacing: 10) {

                        Text(category.localizedName(sex: sex))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)

                        VStack(spacing: 10) {
                            ForEach(AppTheme.themes(in: category), id: \.self) { theme in
                                let isSelected = selectedTheme == theme
                                let themeName = theme.displayName(sex: sex)
                                HStack(spacing: 14) {
                                    // Bloco esquerdo (prévia + nome + check), elemento único
                                    // a11y; botão info FORA pra ficar focável separado.
                                    HStack(spacing: 14) {
                                        Text(theme.themeEmojis(sex: sex))
                                            .font(.title3)
                                            .accessibilityHidden(true)

                                        Text(themeName)
                                            .font(.subheadline.weight(.medium))
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
                                    .tint(isSelected ? .white : accentColor)
                                    .accessibilityLabel(String(format: String(localized: "a11y.theme.info.label.format",
                                                                             bundle: .gymNutshellCore), themeName))
                                    .accessibilityHint(String(localized: "a11y.theme.info.hint",
                                                              bundle: .gymNutshellCore))
                                }
                                .padding()
                                .background(isSelected ? accentColor : Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }

                // Nota de rodapé, fonte menor, estilo caption.
                Text(String(localized: "welcome.step.theme.footer", bundle: .gymNutshellCore))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
            .padding()
        }
        .sheet(item: $infoTheme) { theme in
            NavigationStack {
                ThemeInfoView(theme: theme, sex: sex, accentOverride: accentColor)
            }
        }
    }
}
