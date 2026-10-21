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
                        subtitle: String(localized: "welcome.step.theme.subtitle", bundle: .gymNutshellCore),
                        note: String(localized: "welcome.step.theme.footer", bundle: .gymNutshellCore),
                        accentColor: accentColor
                    )
                }

                // Uma seção por categoria, cada uma com cabeçalho e um card agrupado de temas.
                ForEach(AppTheme.ThemeCategory.allCases, id: \.self) { category in
                    VStack(alignment: .leading, spacing: 8) {
                        AppSectionLabel(text: category.localizedName(sex: sex))

                        AppGroupedCard(dividerInset: 16) {
                            ForEach(AppTheme.themes(in: category), id: \.self) { theme in
                                themeRow(theme)
                            }
                        }
                    }
                }

                // Sem cabeçalho (layout largo), o aviso fica no fim.
                if isWide {
                    Text(String(localized: "welcome.step.theme.footer", bundle: .gymNutshellCore))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                }
            }
            .padding(.horizontal, AppStyle.horizontalPadding)
            .padding(.vertical)
        }
    }

    // MARK: - Linha de tema

    private func themeRow(_ theme: AppTheme) -> some View {
        let isSelected = selectedTheme == theme
        let themeName = theme.displayName(sex: sex)
        return HStack(spacing: 8) {
            // Bloco esquerdo (prévia + nome + check), elemento único
            // a11y; botão Visualizar FORA pra ficar focável separado.
            HStack(spacing: 14) {
                // Nome em cima e os 5 emojis numa linha só embaixo, pra caber o Visualizar ao lado.
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
            .tapButton {
                UISelectionFeedbackGenerator().selectionChanged()
                selectedTheme = theme
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(themeName)
            .accessibilityValue(isSelected
                                ? String(localized: "a11y.selected", bundle: .gymNutshellCore)
                                : String(localized: "a11y.not.selected", bundle: .gymNutshellCore))
            .accessibilityHint(String(localized: "a11y.theme.hint", bundle: .gymNutshellCore))

            // Cápsula do tamanho do Adicionar da etapa de metas, mas cinza: a cor de destaque fica só na seleção.
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
            // Balão com os níveis logo abaixo do botão (o mesmo da grade da Hoje).
            .downwardPopover(isPresented: Binding(get: { infoTheme == theme },
                                                  set: { if !$0 { infoTheme = nil } })) {
                ThemeLevelsPopover(theme: theme, sex: sex, accentColor: accentColor)
            }
            .accessibilityLabel(String(format: String(localized: "a11y.theme.info.label.format",
                                                     bundle: .gymNutshellCore), themeName))
            .accessibilityHint(String(localized: "a11y.theme.info.hint",
                                      bundle: .gymNutshellCore))
        }
        .padding(.leading, 16)
        .padding(.trailing, 12)
        .padding(.vertical, 14)
        .frame(minHeight: 72)
        .background(isSelected ? accentColor.opacity(0.10) : .clear)
    }
}
