// ⌘
//  GymNutshell/GymNutshellApp/Views/SettingsView/Preferences/WidgetBackgroundSettingsView.swift
//
//  Propósito: Permite escolher entre 3 modos de fundo pros widgets da tela inicial:
//             Padrão (segue iOS), Destaque (cor de destaque do app) e Personalizada
//             (ColorPicker). A escolha é feita via Picker segmentado e o footer
//             muda explicando o que cada modo faz.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-05-12.
// ⌘

import SwiftUI
import WidgetKit
import GymNutshellCore

struct WidgetBackgroundSettingsView: View {

    // Modo selecionado, armazenado no App Group pro widget extension ler.
    @AppStorage(WidgetBackgroundStore.modeKey,
                store: UserDefaults(suiteName: "group.com.jonathaxs.gymnutshell"))
    private var mode: WidgetBackgroundMode = .accent

    // Cor de destaque atual, usada pelo preview quando mode == .accent.
    @AppStorage(AppAccentColor.storageKey) private var storedAccentRaw: String = AppAccentColor.blue.rawValue
    private var accentColor: Color {
        (AppAccentColor(rawValue: storedAccentRaw) ?? .blue).color
    }

    @State private var pickedColor: Color = .blue

    private static let defaultPickedColor: Color = Color(red: 0.0, green: 0.478, blue: 1.0)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Prévia com o anel real, no tamanho pequeno e médio.
                VStack(alignment: .leading, spacing: 8) {
                    AppSectionLabel(text: String(localized: "widgetBackground.preview", bundle: .gymNutshellCore))
                    HStack(spacing: 16) {
                        previewTile(size: 110)
                        previewTile(size: 110, wide: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                    // Previews puramente visuais, ocultos do VoiceOver.
                    .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: 12) {
                    AppSectionLabel(text: String(localized: "widgetBackground.mode.label", bundle: .gymNutshellCore))
                    optionCard(.system, title: String(localized: "widgetBackground.mode.system", bundle: .gymNutshellCore))
                    optionCard(.accent, title: String(localized: "widgetBackground.mode.accent", bundle: .gymNutshellCore))
                    optionCard(.custom, title: String(localized: "widgetBackground.mode.custom", bundle: .gymNutshellCore)) {
                        ColorPicker(
                            String(localized: "widgetBackground.picker", bundle: .gymNutshellCore),
                            selection: $pickedColor,
                            supportsOpacity: false
                        )
                    }
                }
            }
            .padding(.horizontal, AppStyle.horizontalPadding)
            .padding(.vertical)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(String(localized: "widgetBackground.title", bundle: .gymNutshellCore))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let saved = WidgetBackgroundStore.loadCustomColor() {
                pickedColor = saved.color
            } else {
                pickedColor = Self.defaultPickedColor
            }
        }
        .onChange(of: pickedColor) { _, newColor in
            persist(color: newColor)
        }
        .onChange(of: mode) { _, newMode in
            // Ao entrar no modo Personalizada pela primeira vez, garante que há cor
            // persistida pro widget renderizar mesmo antes do usuário tocar no picker.
            if newMode == .custom {
                persist(color: pickedColor)
            }
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    // MARK: - Footer dinâmico

    private func footerText(for mode: WidgetBackgroundMode) -> String {
        switch mode {
        case .system:
            return String(localized: "widgetBackground.footer.system", bundle: .gymNutshellCore)
        case .accent:
            return String(localized: "widgetBackground.footer.accent", bundle: .gymNutshellCore)
        case .custom:
            return String(localized: "widgetBackground.footer.custom", bundle: .gymNutshellCore)
        }
    }

    // MARK: - Card de opção

    private func optionCard<Extra: View>(
        _ value: WidgetBackgroundMode,
        title: String,
        @ViewBuilder extra: () -> Extra = { EmptyView() }
    ) -> some View {
        let isSelected = mode == value
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? accentColor : Color.secondary.opacity(0.5))
                    .accessibilityHidden(true)
            }
            Text(footerText(for: value))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if value == .custom && isSelected {
                extra()
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(isSelected: isSelected, accentColor: accentColor)
        .contentShape(RoundedRectangle(cornerRadius: AppStyle.cardRadius, style: .continuous))
        .tapButton {
            UISelectionFeedbackGenerator().selectionChanged()
            mode = value
        }
        .accessibilityElement(children: value == .custom && isSelected ? .contain : .combine)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected
                            ? String(localized: "a11y.selected", bundle: .gymNutshellCore)
                            : String(localized: "a11y.not.selected", bundle: .gymNutshellCore))
    }

    // MARK: - Preview tile

    @ViewBuilder
    private func previewTile(size: CGFloat, wide: Bool = false) -> some View {
        let width: CGFloat = wide ? size * 2.1 : size
        let isSystem = mode == .system
        let sourceColor: Color = mode == .accent ? accentColor : pickedColor
        let textColor: Color = isSystem ? .primary : .white
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(isSystem
                  ? AnyShapeStyle(Color(.secondarySystemGroupedBackground))
                  : AnyShapeStyle(WidgetBackground.gradient(from: sourceColor)))
            .frame(width: width, height: size)
            .overlay {
                HStack(spacing: 12) {
                    SegmentedProgressRing(progress: 0.62, lineWidth: size * 0.09, animated: false) {
                        Text("💪").font(.system(size: size * 0.26))
                    }
                    .frame(width: size * 0.62, height: size * 0.62)
                    if wide {
                        Text("62%")
                            .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                            .foregroundStyle(textColor)
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
            )
    }

    // MARK: - Persistência

    private func persist(color: Color) {
        let bg = backgroundModel(for: color)
        WidgetBackgroundStore.saveCustomColor(bg)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func backgroundModel(for color: Color) -> WidgetBackground {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return WidgetBackground(
            red: Double(r),
            green: Double(g),
            blue: Double(b),
            alpha: Double(a)
        )
    }
}
