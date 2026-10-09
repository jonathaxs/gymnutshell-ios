// ⌘
//  GymNutshell/GymNutshellApp/Views/SettingsView/Preferences/ColorSettingsView.swift
//
//  Propósito: Permite ao usuário escolher a cor de destaque do app independentemente do sexo.
//             O padrão é definido no onboarding com base no sexo, mas pode ser alterado livremente aqui.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-04-15.
// ⌘

import SwiftUI
import GymNutshellCore

struct ColorSettingsView: View {

    @AppStorage(AppAccentColor.storageKey) private var selectedColorRaw: String = AppAccentColor.blue.rawValue

    private var selectedColor: AppAccentColor {
        AppAccentColor(rawValue: selectedColorRaw) ?? .blue
    }

    // Grade 4 colunas, exibe todas as 8 cores com nome e checkmark.
    private let columns = [GridItem(.flexible()), GridItem(.flexible()),
                           GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Prévia ao vivo: muda de cor assim que o usuário toca numa opção.
                VStack(alignment: .leading, spacing: 8) {
                    AppSectionLabel(text: String(localized: "settings.color.preview", bundle: .gymNutshellCore))
                    ColorPreviewCard(color: selectedColor.color)
                        .animation(.easeInOut(duration: 0.25), value: selectedColorRaw)
                        // Prévia puramente visual, oculta do VoiceOver.
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: 8) {
                    AppSectionLabel(text: String(localized: "settings.color.subtitle", bundle: .gymNutshellCore))
                    grid
                        .padding(.vertical, 18)
                        .padding(.horizontal, 8)
                        .appCard()
                }
            }
            .padding(.horizontal, AppStyle.horizontalPadding)
            .padding(.vertical)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(String(localized: "settings.color.title", bundle: .gymNutshellCore))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(AppAccentColor.allCases, id: \.self) { accent in
                let isSelected = selectedColor == accent
                Button {
                    UISelectionFeedbackGenerator().selectionChanged()
                    selectedColorRaw = accent.rawValue
                } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(accent.color)
                                .frame(width: 52, height: 52)

                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.body.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? accent.color : Color.clear,
                                    lineWidth: 2.5
                                )
                                .padding(-4)
                        )

                        Text(accent.displayName)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.primary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accent.displayName)
                .accessibilityValue(isSelected
                                    ? String(localized: "a11y.selected", bundle: .gymNutshellCore)
                                    : String(localized: "a11y.not.selected", bundle: .gymNutshellCore))
                .accessibilityHint(String(localized: "a11y.color.hint", bundle: .gymNutshellCore))
            }
        }
    }
}

// MARK: - Prévia

/// Mini versão da Today com a cor escolhida: anel + %, dois botões de categoria e uma meta com − / +.
private struct ColorPreviewCard: View {

    let color: Color

    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 18) {
                SegmentedProgressRing(progress: 0.62, lineWidth: 10, animated: false) {
                    Text("💪").font(.system(size: 28))
                }
                .frame(width: 84, height: 84)

                VStack(alignment: .leading, spacing: 2) {
                    Text("62%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                    Text(String(localized: "settings.goal.water", bundle: .gymNutshellCore))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 10) {
                    categoryButton("heart.fill")
                    categoryButton("fork.knife")
                }
            }

            HStack(spacing: 14) {
                ProgressView(value: 0.62)
                    .tint(color)
                HStack(spacing: 8) {
                    RoundStepButton(kind: .minus, size: 44, color: color) {}
                    RoundStepButton(kind: .plus, size: 44, color: color) {}
                }
                .allowsHitTesting(false)
            }
        }
        .padding(18)
        .appCard()
    }

    private func categoryButton(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.title3.weight(.semibold))
            .foregroundStyle(color)
            .frame(width: 48, height: 48)
            .background(Circle().fill(Color(.tertiarySystemGroupedBackground)))
            .overlay(Circle().strokeBorder(color.opacity(0.35), lineWidth: 2))
    }
}
