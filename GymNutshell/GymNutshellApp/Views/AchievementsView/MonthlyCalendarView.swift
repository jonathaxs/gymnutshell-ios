// ⌘
//  GymNutshell/GymNutshellApp/Views/AchievementsView/MonthlyCalendarView.swift
//
//  Propósito: Grade de calendário mensal customizada usada pela AchievementsView.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-01-27.
// ⌘

import SwiftUI
import GymNutshellCore

/// View de calendário mensal leve que exibe um emoji por dia quando disponível.
/// Usada na AchievementsView pra indicar visualmente qual mascote foi conquistado em cada dia.
struct MonthlyCalendarView: View {

    /// Mês sendo exibido (qualquer data dentro do mês)
    let monthDate: Date

    /// Dia selecionado (compartilhado com a view pai)
    @Binding var selectedDate: Date

    /// Mapeamento de dia -> emoji (chaveado por startOfDay)
    let emojiByDay: [Date: String]

    /// Mapeamento de dia -> nome localizado a falar no VoiceOver (nome do tier
    /// quando há DailyRecord naquela data). Quando ausente, a célula é narrada como "sem registro".
    /// AchievementsView popula isso; outros call sites podem deixar vazio.
    var tierNameByDay: [Date: String] = [:]

    private let calendar = Calendar.current

    // Cor de destaque, segue a escolha do usuário em Settings > Cores.
    @AppStorage(AppAccentColor.storageKey) private var storedColorRaw: String = AppAccentColor.blue.rawValue
    private var accentColor: Color { (AppAccentColor(rawValue: storedColorRaw) ?? .blue).color }

    // Símbolos de dia da semana de uma letra, localizados e ordenados pelas configurações de calendário do usuário.
    private var weekdaySymbols: [String] {
        // shortStandaloneWeekdaySymbols é consciente do locale (ex.: "dom.", "seg.")
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let startIndex = (calendar.firstWeekday - 1) % symbols.count
        let ordered = Array(symbols[startIndex...] + symbols[..<startIndex])

        return ordered.map { symbol in
            let cleaned = symbol
                .replacingOccurrences(of: ".", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return String(cleaned.prefix(1)).uppercased()
        }
    }

    var body: some View {
        let days = daysInMonth(for: monthDate)

        VStack(spacing: 8) {
            // Cabeçalho dos dias da semana (D S T Q Q S S), decorativo;
            // ocultado do VoiceOver pra não falar "D, S, T..." em swipe.
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .accessibilityHidden(true)

            // Grid do mês
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                ForEach(days, id: \.self) { date in
                    dayCell(for: date)
                }
            }
        }
    }

    // MARK: - Célula do dia

    @ViewBuilder
    private func dayCell(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isInDisplayedMonth = calendar.isDate(date, equalTo: monthDate, toGranularity: .month)
        let isToday = calendar.isDateInToday(date)
        let isFuture = date > Date() && !isToday
        let dayNumber = calendar.component(.day, from: date)
        let dayKey = calendar.startOfDay(for: date)
        let emoji = emojiByDay[dayKey]
        let tierName = tierNameByDay[dayKey]

        VStack(spacing: 4) {
            Text("\(dayNumber)")
                .font(.callout.weight(.semibold))
                .foregroundStyle(isSelected ? .white : (isInDisplayedMonth ? .primary : .secondary))
                .opacity(isInDisplayedMonth || isSelected ? 1 : 0.45)

            if let emoji {
                Text(emoji)
                    .font(.callout)
                    .opacity(isInDisplayedMonth || isSelected ? 1 : 0.45)
            }
        }
        .frame(height: 44)
        .frame(maxWidth: .infinity)
        .background(isSelected ? accentColor : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .opacity(isInDisplayedMonth || isSelected ? 1 : 0.65)
        .contentShape(Rectangle())
        .tapButton {
            guard isInDisplayedMonth else { return }
            selectedDate = date
        }
        // Acessibilidade, célula vira UM elemento focável; dias fora do mês
        // visível ficam ocultos pra reduzir ruído na varredura por swipe.
        .accessibilityElement(children: .ignore)
        .accessibilityHidden(!isInDisplayedMonth)
        .accessibilityLabel(A11y.calendarDayValue(date: date,
                                                  tierName: tierName,
                                                  isToday: isToday,
                                                  isFuture: isFuture,
                                                  isSelected: isSelected))
    }

    // MARK: - Helpers

    /// Retorna todas as datas pra renderizar na grade do mês (incluindo dias vazios iniciais).
    private func daysInMonth(for date: Date) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start)
        else {
            return []
        }

        let start = firstWeek.start
        let end = monthInterval.end

        var days: [Date] = []
        var current = start

        while current < end {
            days.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
        }

        return days
    }
}
