// ⌘
//  GymNutshell/GymNutshellApp/Views/TodayView/Components/StreakBonusInfoView.swift
//
//  Propósito: Explica os pontos (1 a 5 por dia, pelo nível) e os 4 bônus de sequência.
//             Aberta em Ajustes > Sobre, pela seção de bônus no Registro e pelas linhas de bônus
//             nas Conquistas.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-11-04.
// ⌘

import SwiftUI
import GymNutshellCore

struct StreakBonusInfoView: View {

    var isSheet: Bool = false

    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppTheme.storageKey) private var selectedTheme: AppTheme = .gym
    @AppStorage(UserProfile.sexKey) private var sex: String = "male"
    @AppStorage(AppAccentColor.storageKey) private var storedColorRaw: String = AppAccentColor.blue.rawValue
    private var accentColor: Color { (AppAccentColor(rawValue: storedColorRaw) ?? .blue).color }

    var body: some View {
        List {
            Section {
                Text(String(localized: "streak.bonus.info.intro", bundle: .gymNutshellCore))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }
            .listRowBackground(Color.clear)

            // Pontos por dia: o número do nível.
            Section(String(localized: "streak.bonus.info.section.daily", bundle: .gymNutshellCore)) {
                ForEach(DailyAchievement.allCases, id: \.self) { tier in
                    let name = selectedTheme.name(for: tier, sex: sex)
                    InfoPointsRow(emoji: selectedTheme.emoji(for: tier, sex: sex),
                                  title: name,
                                  detail: nil,
                                  points: tier.points,
                                  accentColor: accentColor)
                }
            }

            // Os 4 bônus de sequência.
            Section {
                ForEach(StreakBonusKind.allCases) { kind in
                    InfoPointsRow(emoji: kind.emoji,
                                  title: kind.title,
                                  detail: kind.detail,
                                  points: kind.points,
                                  accentColor: accentColor)
                }
            } header: {
                Text(String(localized: "streak.bonus.generic.title", bundle: .gymNutshellCore))
            } footer: {
                Text(String(localized: "streak.bonus.info.footer", bundle: .gymNutshellCore))
            }
        }
        .navigationTitle(String(localized: "settings.about.streakBonus", bundle: .gymNutshellCore))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isSheet {
                ToolbarItem(placement: .topBarLeading) {
                    SheetCloseButton { dismiss() }
                }
            }
        }
    }
}

/// Linha com emoji, nome, descrição opcional e os pontos à direita.
private struct InfoPointsRow: View {
    let emoji: String
    let title: String
    let detail: String?
    let points: Int
    let accentColor: Color

    var body: some View {
        let pointsText = String(format: String(localized: "points.plus.format", bundle: .gymNutshellCore), points)
        HStack(spacing: 14) {
            Text(emoji)
                .font(.title2)
                .frame(width: 36)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(pointsText)
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(accentColor)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel([title, detail, pointsText].compactMap { $0 }.joined(separator: ", "))
    }
}
