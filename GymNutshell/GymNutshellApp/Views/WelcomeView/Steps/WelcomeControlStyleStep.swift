// ⌘
//  GymNutshell/GymNutshellApp/Views/WelcomeView/Steps/WelcomeControlStyleStep.swift
//
//  Propósito: Etapa do onboarding, o usuário escolhe se marca as metas deslizando (slider)
//             ou com botões − / +. Cada opção mostra uma prévia do controle.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-10-08.
// ⌘

import SwiftUI
import GymNutshellCore

/// Etapa do onboarding: dois cards selecionáveis (slider / − +) com prévia do controle.
struct WelcomeControlStyleStep: View {

    @Binding var selection: ControlStyle
    let accentColor: Color
    var isWide: Bool = false

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    if !isWide {
                        WelcomeStepHeader(
                            emoji: "🎛️",
                            title: String(localized: "welcome.step.control.title", bundle: .gymNutshellCore),
                            subtitle: String(localized: "welcome.step.control.subtitle", bundle: .gymNutshellCore),
                            accentColor: accentColor
                        )
                    }

                    card(.slider,
                         title: String(localized: "welcome.control.slider", bundle: .gymNutshellCore),
                         desc: String(localized: "welcome.control.slider.desc", bundle: .gymNutshellCore)) {
                        // Prévia estática, não interativa.
                        Capsule()
                            .fill(Color.secondary.opacity(0.25))
                            .frame(height: 6)
                            .overlay(alignment: .leading) {
                                Capsule().fill(accentColor).frame(width: 90, height: 6)
                            }
                            .overlay(alignment: .leading) {
                                Circle().fill(.white).frame(width: 24, height: 24)
                                    .shadow(radius: 2, y: 1)
                                    .offset(x: 78)
                            }
                    }

                    card(.stepper,
                         title: String(localized: "welcome.control.stepper", bundle: .gymNutshellCore),
                         desc: String(localized: "welcome.control.stepper.desc", bundle: .gymNutshellCore)) {
                        HStack(spacing: 12) {
                            Image(systemName: "minus.circle.fill").font(.title).symbolRenderingMode(.hierarchical)
                            Capsule()
                                .fill(Color.secondary.opacity(0.25))
                                .frame(height: 6)
                                .overlay(alignment: .leading) {
                                    Capsule().fill(accentColor).frame(width: 90, height: 6)
                                }
                            Image(systemName: "plus.circle.fill").font(.title).symbolRenderingMode(.hierarchical)
                        }
                        .foregroundStyle(accentColor)
                    }

                    Text(String(localized: "welcome.control.footer", bundle: .gymNutshellCore))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, AppStyle.horizontalPadding)
                .padding(.vertical)
                .frame(maxWidth: .infinity, minHeight: isWide ? geo.size.height : 0, alignment: .center)
            }
        }
    }

    // MARK: - Card de opção

    private func card<Preview: View>(
        _ style: ControlStyle,
        title: String,
        desc: String,
        @ViewBuilder preview: () -> Preview
    ) -> some View {
        let isSelected = selection == style
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? accentColor : Color.secondary.opacity(0.5))
                    .accessibilityHidden(true)
            }
            Text(desc)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            preview()
                .padding(.vertical, 6)
                .accessibilityHidden(true)
        }
        .padding(18)
        .appCard(isSelected: isSelected, accentColor: accentColor)
        .contentShape(RoundedRectangle(cornerRadius: AppStyle.cardRadius, style: .continuous))
        .tapButton {
            UISelectionFeedbackGenerator().selectionChanged()
            selection = style
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected
                            ? String(localized: "a11y.selected", bundle: .gymNutshellCore)
                            : String(localized: "a11y.not.selected", bundle: .gymNutshellCore))
    }
}
