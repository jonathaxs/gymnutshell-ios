// ⌘
//  GymNutshell/GymNutshellApp/Views/ProfileView/Components/ProfileRecentActivityView.swift
//
//  Propósito: Grade "Últimos 7 dias", mostra o emoji do nível (ou um ponto) pra cada um
//             dos últimos 7 dias do calendário. Tocar num dia dispara o callback onDayTap pra
//             que a ProfileView possa navegar até aquela data na AchievementsView.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-28.
// ⌘

import SwiftUI
import GymNutshellCore

/// Grade de atividade de sete dias com emoji por dia, número da data e inicial do dia da semana.
struct ProfileRecentActivityView: View {

    let entries: [(date: Date, record: DailyRecord?)]
    let selectedTheme: AppTheme
    let onDayTap: (Date) -> Void

    @AppStorage(UserProfile.sexKey) private var sex: String = "male"

    @AppStorage(AppAccentColor.storageKey) private var storedColorRaw: String = AppAccentColor.blue.rawValue
    private var accentColor: Color { (AppAccentColor(rawValue: storedColorRaw) ?? .blue).color }

    var body: some View {
        ProgressSection(title: String(localized: "profile.recent.section", bundle: .gymNutshellCore)) {
            // Células dos sete dias, tocar navega pra aquele dia na AchievementsView.
            HStack(spacing: 4) {
                ForEach(entries, id: \.date) { entry in
                    Button {
                        onDayTap(entry.date)
                    } label: {
                        dayCell(entry: entry)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel(a11yLabel(for: entry))
                    .accessibilityHint(String(localized: "a11y.recent.day.hint",
                                              bundle: .gymNutshellCore))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 14)
            .appCard()
        }
    }

    // Constrói o label de VoiceOver de cada dia: data por extenso + nome do tier
    // (ou "sem registro") + prefixo "hoje" quando aplicável.
    private func a11yLabel(for entry: (date: Date, record: DailyRecord?)) -> String {
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(entry.date)
        let dateString = A11y.spokenDate(for: entry.date)
        if let record = entry.record, record.percent > 0 {
            let tier = DailyAchievement.from(emoji: record.achievementEmoji)
            let tierName = selectedTheme.name(for: tier, sex: sex)
            let key = isToday ? "a11y.recent.day.today.format" : "a11y.recent.day.with.tier.format"
            let fmt = String(localized: String.LocalizationValue(key), bundle: .gymNutshellCore)
            return String(format: fmt, dateString, tierName)
        } else {
            let key = isToday ? "a11y.recent.day.today.empty.format" : "a11y.recent.day.empty.format"
            let fmt = String(localized: String.LocalizationValue(key), bundle: .gymNutshellCore)
            return String(format: fmt, dateString)
        }
    }

    private func dayCell(entry: (date: Date, record: DailyRecord?)) -> some View {
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(entry.date)
        let hasRecord = entry.record != nil && entry.record!.percent > 0
        let dayNumber = calendar.component(.day, from: entry.date)

        return VStack(spacing: 3) {
            ZStack {
                Circle()
                    .fill(hasRecord
                          ? accentColor.opacity(0.15)
                          : Color(.tertiarySystemBackground))
                    .frame(width: 38, height: 38)
                    .overlay {
                        if isToday {
                            Circle().stroke(accentColor, lineWidth: 2)
                        }
                    }
                Text(entry.record.map { selectedTheme.emoji(for: DailyAchievement.from(emoji: $0.achievementEmoji)) } ?? "·")
                    .font(.system(size: entry.record != nil ? 18 : 14))
            }
            Text("\(dayNumber)")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isToday ? accentColor : .primary)
            Text(weekdayInitial(for: entry.date))
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }

    // Símbolo do dia da semana em uma letra só, respeitando o locale (ex: "S", "T").
    private func weekdayInitial(for date: Date) -> String {
        AppDateFormatters.weekdayInitial.string(from: date)
    }
}
