// ⌘
//  GymNutshell/GymNutshellApp/Views/TodayView/Components/TierInfoView.swift
//
//  Propósito: View informativa sobre o sistema de níveis de conquista.
//             Exibida como sheet quando o usuário toca no emoji do centro do anel e
//             também acessível em Configurações > Sobre > Conquista.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-04-15.
// ⌘

import SwiftUI
import GymNutshellCore

/// Exibe uma explicação completa do sistema de conquistas por tier:
/// emojis, nomes de nível, faixas de porcentagem e um botão pra alterar o tema.
struct TierInfoView: View {

    let theme: AppTheme
    let sex: String
    var isSheet: Bool = false

    // Contexto de progresso, passado pela TodayHeroView quando aberto como sheet.
    // nil quando acessado via Settings > Sobre (sem contexto de progresso atual).
    var nextLevelPercent: Int? = nil
    var nextLevelName: String = ""
    var nextLevelNumber: Int? = nil
    var isAtMaxLevel: Bool = false

    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppAccentColor.storageKey) private var storedColorRaw: String = AppAccentColor.blue.rawValue
    private var accentColor: Color { (AppAccentColor(rawValue: storedColorRaw) ?? .blue).color }

    // Tiers em ordem crescente de dificuldade.
    private let tiers: [DailyAchievement] = DailyAchievement.allCases

    // Faixa de porcentagem de cada tier.
    private func rangeLabel(for tier: DailyAchievement) -> String {
        let range: String
        switch tier {
        case .level1: range = "0 – 32%"
        case .level2: range = "33 – 65%"
        case .level3: range = "66 – 89%"
        case .level4: range = "90 – 100%"
        }
        return range + String(localized: "tier.info.range.suffix", bundle: .gymNutshellCore)
    }

    // Número do nível (1–4) pra exibir ao lado do nome.
    private func tierLevel(for tier: DailyAchievement) -> Int {
        switch tier {
        case .level1: return 1
        case .level2: return 2
        case .level3: return 3
        case .level4: return 4
        }
    }

    var body: some View {
        List {
            // Intro + frase de progresso na mesma seção pra reduzir o espaço entre eles.
            Section {
                Text(String(localized: "tier.info.intro", bundle: .gymNutshellCore))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)

                if isAtMaxLevel {
                    Text(String(localized: "today.max.level", bundle: .gymNutshellCore))
                        .font(.subheadline.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 4)
                } else if let percent = nextLevelPercent, let _ = nextLevelNumber {
                    (Text(String(localized: "info.next.prefix", bundle: .gymNutshellCore))
                     + Text("\(percent)")
                     + Text("%")
                     + Text(String(localized: "info.next.middle", bundle: .gymNutshellCore))
                     + Text("\n")
                     + Text(nextLevelName).foregroundStyle(.primary))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 4)
                }
            }
            .listRowBackground(Color.clear)

            // Seção "Conquistas" com os 4 tiers, "Nível X" no canto direito de cada linha.
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

            // Link pra Settings > Tema
            Section {
                NavigationLink {
                    ThemeSettingsView()
                } label: {
                    Label(String(localized: "tier.info.change.theme", bundle: .gymNutshellCore), systemImage: "paintpalette")
                }
            }
        }
        .navigationTitle(String(localized: "settings.about.achievement", bundle: .gymNutshellCore))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isSheet {
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
}
