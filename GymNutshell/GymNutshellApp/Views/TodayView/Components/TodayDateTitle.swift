// ⌘
//  GymNutshell/GymNutshellApp/Views/TodayView/Components/TodayDateTitle.swift
//
//  Propósito: Data grande da Hoje com a frase do dia logo abaixo (previsão do modelo ou média do dia
//             da semana). Tocar na data ou na frase abre o balão com a data completa e a explicação.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-11-12.
// ⌘

import SwiftUI
import SwiftData
import GymNutshellCore

struct TodayDateTitle: View {

    let title: String

    @Query(sort: \DailyRecord.date, order: .forward) private var records: [DailyRecord]
    @State private var insight: DayInsight?
    @State private var showDayInfo = false

    /// Muda quando vira o dia ou quando algum dia passado é criado/editado; aí treina de novo.
    private var refreshKey: String {
        let today = Calendar.current.startOfDay(for: .now)
        let past = records.filter { $0.date < today }
        return "\(today.timeIntervalSince1970)-\(past.count)-\(past.reduce(0) { $0 &+ $1.percent })"
    }

    var body: some View {
        Button { showDayInfo = true } label: {
            VStack(spacing: 2) {
                Text(title)
                    .font(.title.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                if let insight {
                    Text(Self.phrase(for: insight))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .transition(.opacity)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .adaptivePopover(isPresented: $showDayInfo) {
            DayInfoPopover(insight: insight)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityHint(A11y.moreInfoHint())
        .task(id: refreshKey) {
            // Treino fora da main thread: com muitos dias em build de debug passa de meio segundo.
            let days = records.map(TrainingDay.init(record:))
            let now = Date.now
            let result = await Task.detached(priority: .utility) {
                DayInsightBuilder.make(for: now, days: days)
            }.value
            withAnimation(.easeInOut(duration: 0.25)) { insight = result }
        }
    }

    /// Frase curta abaixo da data.
    static func phrase(for insight: DayInsight) -> String {
        switch insight.kind {
        case .model:
            return String(localized: insight.needsAttention ? "today.insight.attention" : "today.insight.steady",
                          bundle: .gymNutshellCore)
        case .weekday(let average, _):
            // Sem o nome do dia: a data logo acima já diz qual é.
            return String(format: String(localized: "today.insight.weekday", bundle: .gymNutshellCore), average)
        }
    }
}
