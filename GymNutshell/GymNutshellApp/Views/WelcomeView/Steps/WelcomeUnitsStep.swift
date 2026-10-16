// ⌘
//  GymNutshell/GymNutshellApp/Views/WelcomeView/Steps/WelcomeUnitsStep.swift
//
//  Propósito: Etapa opcional do onboarding, só pra aparelhos no sistema americano. O usuário escolhe
//             se a água aparece em onças fluidas (imperial, padrão) ou em mililitros (métrico).
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-10-09.
// ⌘

import SwiftUI
import GymNutshellCore

/// Etapa do onboarding: dois cards selecionáveis (Imperial / Métrico).
struct WelcomeUnitsStep: View {

    @Binding var selection: MeasurementSystem
    let accentColor: Color
    var isWide: Bool = false

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    if !isWide {
                        WelcomeStepHeader(
                            emoji: "📏",
                            title: String(localized: "welcome.step.units.title", bundle: .gymNutshellCore),
                            subtitle: String(localized: "welcome.step.units.subtitle", bundle: .gymNutshellCore),
                            note: String(localized: "welcome.step.units.note", bundle: .gymNutshellCore),
                            accentColor: accentColor
                        )
                    }

                    card(.us,
                         title: String(localized: "settings.preference.measurementSystem.us", bundle: .gymNutshellCore),
                         desc: String(format: String(localized: "welcome.units.imperial.desc", bundle: .gymNutshellCore), UnitConverter.flOzWaterStep))
                    card(.metric,
                         title: String(localized: "settings.preference.measurementSystem.metric", bundle: .gymNutshellCore),
                         desc: String(localized: "welcome.units.metric.desc", bundle: .gymNutshellCore))

                    if isWide {
                        Text(String(localized: "welcome.step.units.note", bundle: .gymNutshellCore))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding(.horizontal, AppStyle.horizontalPadding)
                .padding(.vertical)
                .frame(maxWidth: .infinity, minHeight: isWide ? geo.size.height : 0, alignment: .center)
            }
        }
    }

    private func card(_ system: MeasurementSystem, title: String, desc: String) -> some View {
        let isSelected = selection == system
        return VStack(alignment: .leading, spacing: 8) {
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
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(isSelected: isSelected, accentColor: accentColor)
        .contentShape(RoundedRectangle(cornerRadius: AppStyle.cardRadius, style: .continuous))
        .tapButton {
            UISelectionFeedbackGenerator().selectionChanged()
            selection = system
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected
                            ? String(localized: "a11y.selected", bundle: .gymNutshellCore)
                            : String(localized: "a11y.not.selected", bundle: .gymNutshellCore))
    }
}
