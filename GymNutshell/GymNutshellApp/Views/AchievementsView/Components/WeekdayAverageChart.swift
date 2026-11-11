// ⌘
//  GymNutshell/GymNutshellApp/Views/AchievementsView/Components/WeekdayAverageChart.swift
//
//  Propósito: Card com gráfico de barras da média de percentual por dia da semana na tela de Conquistas.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-11-11.
// ⌘

import SwiftUI
import Charts
import GymNutshellCore

/// Card que exibe a média de conclusão (%) por dia da semana usando Swift Charts.
struct WeekdayAverageChart: View {

    let averages: [WeekdayAverage]
    let accentColor: Color
    // Semana de segunda a domingo, igual ao calendário de Registros.
    var calendar: Calendar = StreakBonusCalculator.weekCalendar

    // Rótulo curto do eixo X (ex.: "dom", "seg"), sem ponto final.
    private func shortWeekdayLabel(for weekday: Int) -> String {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        guard (1...symbols.count).contains(weekday) else { return "\(weekday)" }
        return symbols[weekday - 1]
            .replacingOccurrences(of: ".", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Nome completo do dia da semana para leitura no VoiceOver.
    private func fullWeekdayLabel(for weekday: Int) -> String {
        let symbols = calendar.standaloneWeekdaySymbols
        guard (1...symbols.count).contains(weekday) else { return "\(weekday)" }
        return symbols[weekday - 1]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "achievements.weekday.title", bundle: .gymNutshellCore))
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Chart(averages) { item in
                BarMark(
                    x: .value("Dia", shortWeekdayLabel(for: item.weekday)),
                    y: .value("Média", item.average)
                )
                .foregroundStyle(accentColor)
                .cornerRadius(6)
                .accessibilityLabel(fullWeekdayLabel(for: item.weekday))
                .accessibilityValue("\(Int(item.average.rounded()))%")
            }
            .chartYScale(domain: 0...100)
            .frame(height: 160)

            Text(String(localized: "achievements.weekday.footer", bundle: .gymNutshellCore))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .appCard()
    }
}
