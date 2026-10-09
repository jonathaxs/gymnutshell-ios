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

    @AppStorage(AppAccentColor.storageKey) private var storedColorRaw: String = AppAccentColor.blue.rawValue
    private var accentColor: Color { (AppAccentColor(rawValue: storedColorRaw) ?? .blue).color }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                card(.slider,
                     title: String(localized: "welcome.control.slider", bundle: .gymNutshellCore),
                     desc: String(localized: "welcome.control.slider.desc", bundle: .gymNutshellCore)) {
                    SliderPreview(color: accentColor)
                }
                card(.stepper,
                     title: String(localized: "welcome.control.stepper", bundle: .gymNutshellCore),
                     desc: String(localized: "welcome.control.stepper.desc", bundle: .gymNutshellCore)) {
                    StepperPreview(color: accentColor)
                }
                Text(String(localized: "settings.controlStyle.footer", bundle: .gymNutshellCore))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, AppStyle.horizontalPadding)
            .padding(.vertical)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(String(localized: "settings.preference.controlStyle", bundle: .gymNutshellCore))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func card<Preview: View>(
        _ style: ControlStyle,
        title: String,
        desc: String,
        @ViewBuilder preview: () -> Preview
    ) -> some View {
        let isSelected = styleRaw == style.rawValue
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
            styleRaw = style.rawValue
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected
                            ? String(localized: "a11y.selected", bundle: .gymNutshellCore)
                            : String(localized: "a11y.not.selected", bundle: .gymNutshellCore))
    }
}
