// ⌘
//  GymNutshell/GymNutshellApp/Views/SettingsView/Profile/DayInsightInfoView.swift
//
//  Propósito: Explica a frase do dia (abaixo da data na Hoje): o que o modelo olha, quando a previsão
//             aparece e que tudo é calculado no aparelho. Aberta em Ajustes > Sobre.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-11-17.
// ⌘

import SwiftUI
import GymNutshellCore

struct DayInsightInfoView: View {

    @AppStorage(AppAccentColor.storageKey) private var storedColorRaw: String = AppAccentColor.blue.rawValue
    private var accentColor: Color { (AppAccentColor(rawValue: storedColorRaw) ?? .blue).color }

    /// Passos da explicação, na ordem: o que lê, o que calcula, quando mostra e quando começa.
    private var steps: [(symbol: String, text: String)] {
        [
            ("clock.arrow.circlepath",
             String(localized: "dayInsight.info.history", bundle: .gymNutshellCore)),
            ("percent",
             String(format: String(localized: "dayInsight.info.chance", bundle: .gymNutshellCore),
                    RiskModel.defaultWeakThreshold)),
            ("checkmark.seal",
             String(localized: "dayInsight.info.check", bundle: .gymNutshellCore)),
            ("calendar",
             String(format: String(localized: "dayInsight.info.days", bundle: .gymNutshellCore),
                    RiskModel.minimumDays)),
        ]
    }

    var body: some View {
        List {
            Section {
                Text(String(localized: "dayInsight.info.intro", bundle: .gymNutshellCore))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }
            .listRowBackground(Color.clear)

            Section {
                ForEach(steps, id: \.symbol) { step in
                    HStack(alignment: .firstTextBaseline, spacing: 14) {
                        Image(systemName: step.symbol)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(accentColor)
                            .frame(width: 28)
                            .accessibilityHidden(true)
                        Text(step.text)
                            .font(.subheadline)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text(String(localized: "dayInsight.info.section.how", bundle: .gymNutshellCore))
            } footer: {
                Text(String(localized: "dayInsight.info.footer", bundle: .gymNutshellCore))
            }
        }
        .navigationTitle(String(localized: "settings.about.dayInsight", bundle: .gymNutshellCore))
        .navigationBarTitleDisplayMode(.inline)
    }
}
