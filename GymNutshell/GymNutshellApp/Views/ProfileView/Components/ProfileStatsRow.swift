// ⌘
//  GymNutshell/GymNutshellApp/Views/ProfileView/Components/ProfileStatsRow.swift
//
//  Propósito: Resumo da tela de Progresso, dois blocos com ícone: total de dias e total de pontos.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-28.
// ⌘

import SwiftUI
import GymNutshellCore

/// Dois blocos lado a lado mostrando o resumo de atividade do usuário.
struct ProfileStatsRow: View {

    let totalDays: Int
    let totalPoints: Int
    let accentColor: Color

    // Dias → calendário de hoje.
    var onDaysTap: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            tile(icon: "calendar", value: totalDays,
                 label: String(localized: "profile.stats.days", bundle: .gymNutshellCore))
                .contentShape(RoundedRectangle(cornerRadius: AppStyle.cardRadius, style: .continuous))
                .tapButton { onDaysTap?() }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(String(localized: "a11y.stats.days.label", bundle: .gymNutshellCore))
                .accessibilityValue(String(format: String(localized: "a11y.stats.days.value.format",
                                                         bundle: .gymNutshellCore), totalDays))
                .accessibilityHint(String(localized: "a11y.stats.days.hint", bundle: .gymNutshellCore))

            // Pontos mantém o efeito de escala; Dias não.
            tile(icon: "star.fill", value: totalPoints,
                 label: String(localized: "profile.stats.points", bundle: .gymNutshellCore))
                .pressScale(1.20, response: 0.25, dampingFraction: 0.50)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(String(localized: "a11y.stats.points.label", bundle: .gymNutshellCore))
                .accessibilityValue(String(format: String(localized: "a11y.stats.points.value.format",
                                                         bundle: .gymNutshellCore), totalPoints))
        }
    }

    private func tile(icon: String, value: Int, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(accentColor)
                .frame(height: 26)
                .accessibilityHidden(true)
            Text("\(value)")
                .font(.system(size: 28, weight: .bold, design: .rounded).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .appCard()
    }
}
