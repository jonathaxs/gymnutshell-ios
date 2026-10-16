// ⌘
//  GymNutshell/GymNutshellApp/Views/SettingsView/Preferences/ThemeInfoView.swift
//
//  Propósito: Sheet informativo exibido quando o usuário toca no botão (i) ao lado de um tema.
//             Mostra os quatro emojis de nível e os nomes localizados pra aquele tema.
//             Sempre apresentado como sheet (nunca via NavigationLink).
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-04-18.
// ⌘

import SwiftUI
import GymNutshellCore

/// Exibe os quatro níveis de conquista de um tema específico:
/// emoji, nome localizado (respeitando gênero) e faixa de porcentagem.
struct ThemeInfoView: View {

    let theme: AppTheme
    let sex: String
    // Permite sobrescrever a cor de destaque (usado no fluxo Welcome, antes do usuário salvar a escolha).
    var accentOverride: Color? = nil

    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppAccentColor.storageKey) private var storedColorRaw: String = AppAccentColor.blue.rawValue
    private var accentColor: Color {
        accentOverride ?? (AppAccentColor(rawValue: storedColorRaw) ?? .blue).color
    }

    private let tiers: [DailyAchievement] = DailyAchievement.allCases

    private func rangeLabel(for tier: DailyAchievement) -> String {
        tier.percentRange + String(localized: "tier.info.range.suffix", bundle: .gymNutshellCore)
    }

    private func tierLevel(for tier: DailyAchievement) -> Int {
        tier.number
    }

    var body: some View {
        List {
            Section(String(localized: "tier.info.section.levels", bundle: .gymNutshellCore)) {
                ForEach(tiers, id: \.self) { tier in
                    let name = theme.name(for: tier, sex: sex)
                    let range = rangeLabel(for: tier)
                    let level = tierLevel(for: tier)
                    HStack(spacing: 14) {
                        Text(theme.emoji(for: tier, sex: sex))
                            .font(.title2)
                            .frame(width: 36)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(name)
                                .font(.subheadline.weight(.semibold))
                            Text(range)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(String(localized: "ring.info.level.label", bundle: .gymNutshellCore) + "\(level)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(accentColor)
                    }
                    .padding(.vertical, 2)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(String(format: String(localized: "a11y.tierinfo.row.format",
                                                             bundle: .gymNutshellCore),
                                               name, range, level))
                }
            }
        }
        .navigationTitle(theme.displayName(sex: sex))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Text(String(localized: "common.close", bundle: .gymNutshellCore))
                        .foregroundStyle(accentColor)
                }
            }
        }
    }
}
