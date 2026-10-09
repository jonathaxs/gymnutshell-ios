// ⌘
//  GymNutshell/GymNutshellApp/Views/AchievementsView/Components/AchievementsCalendarSection.swift
//
//  Propósito: Cabeçalho de navegação mensal + MonthlyCalendarView pra tela de Conquistas.
//             Exibido só quando o filtro "Dia" está ativo.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-29.
// ⌘

import SwiftUI
import GymNutshellCore

/// Seção de calendário pra AchievementsView, título do mês, chevrons anterior/próximo e a grade de emojis.
struct AchievementsCalendarSection: View {

    let visibleMonthTitle: String
    let visibleMonthDate: Date
    @Binding var selectedDate: Date
    let emojiByDay: [Date: String]
    /// Nome localizado a falar no VoiceOver para cada data (tier do registro ou
    /// título do bônus). Default vazio para call sites que não montem esse mapa.
    var tierNameByDay: [Date: String] = [:]
    let onChangeMonth: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(String(localized: "achievements.calendar.title", bundle: .gymNutshellCore))
                    .font(.headline)
                    .accessibilityLabel(String(localized: "a11y.achievements.calendar.title", bundle: .gymNutshellCore))

                Spacer()

                Button {
                    onChangeMonth(-1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 28, height: 28)
                }
                .appCircleButton()
                .controlSize(.small)
                .accessibilityLabel(String(localized: "a11y.month.previous", bundle: .gymNutshellCore))

                Text(visibleMonthTitle)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.primary)

                Button {
                    onChangeMonth(1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 28, height: 28)
                }
                .appCircleButton()
                .controlSize(.small)
                .accessibilityLabel(String(localized: "a11y.month.next", bundle: .gymNutshellCore))
            }

            MonthlyCalendarView(
                monthDate: visibleMonthDate,
                selectedDate: $selectedDate,
                emojiByDay: emojiByDay,
                tierNameByDay: tierNameByDay
            )
            .frame(maxWidth: 400)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(16)
        .appCard()
    }
}
