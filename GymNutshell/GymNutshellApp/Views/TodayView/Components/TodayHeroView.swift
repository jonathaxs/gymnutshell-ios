// ⌘
//  GymNutshell/GymNutshellApp/Views/TodayView/Components/TodayHeroView.swift
//
//  Propósito: Bloco hero fixo exibido no topo (retrato) ou na coluna esquerda (landscape).
//             Contém: botão de data e anel de progresso com o emoji da conquista no centro.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-29.
// ⌘

import SwiftUI
import GymNutshellCore

/// Bloco hero da TodayView, data, nível de conquista, anel de progresso e frase do próximo nível.
struct TodayHeroView: View {

    let formattedDate: String
    let dailyAchievement: DailyAchievement
    let dailyProgress: Double
    let selectedTheme: AppTheme
    /// Quando true (iPad, sobra altura), o anel fica maior.
    var verticalLayout: Bool = false

    // Sexo do usuário, usado pra nomes de tier com gênero correto.
    @AppStorage(UserProfile.sexKey) private var sex: String = "male"

    // Cor de destaque, segue a escolha do usuário em Settings > Cores.
    @AppStorage(AppAccentColor.storageKey) private var storedColorRaw: String = AppAccentColor.blue.rawValue
    private var accentColor: Color { (AppAccentColor(rawValue: storedColorRaw) ?? .blue).color }

    // Sheets de informação do tier, do anel de progresso e do histórico de notificações.
    @State private var showTierSheet = false
    @State private var showRingSheet = false
    @State private var showNotificationHistory = false

    // Percentual inteiro (0-100) calculado a partir do progresso normalizado.
    private var dailyPercentage: Int {
        Int((dailyProgress * 100).rounded(.down))
    }

    // Label de nível localizado pra um tier (ex: "Nível 2").
    private func tierLevelString(for tier: DailyAchievement) -> String {
        switch tier {
        case .level1: return String(localized: "today.tier.level.1", bundle: .gymNutshellCore)
        case .level2: return String(localized: "today.tier.level.2", bundle: .gymNutshellCore)
        case .level3: return String(localized: "today.tier.level.3", bundle: .gymNutshellCore)
        case .level4: return String(localized: "today.tier.level.4", bundle: .gymNutshellCore)
        }
    }

    // Saudação baseada no horário atual.
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return String(localized: "today.greeting.morning", bundle: .gymNutshellCore)
        case 12..<18: return String(localized: "today.greeting.afternoon", bundle: .gymNutshellCore)
        default: return String(localized: "today.greeting.night", bundle: .gymNutshellCore)
        }
    }

    // Componentes do próximo nível, (percent, tierName, levelNumber).
    // nil quando o usuário já está no nível máximo (90%+).
    private var nextLevelComponents: (percent: Int, name: String, level: Int)? {
        if dailyPercentage >= 90 { return nil }
        if dailyPercentage >= 66 {
            return (90 - dailyPercentage, selectedTheme.name(for: .level4, sex: sex), 4)
        } else if dailyPercentage >= 33 {
            return (66 - dailyPercentage, selectedTheme.name(for: .level3, sex: sex), 3)
        } else {
            return (33 - dailyPercentage, selectedTheme.name(for: .level2, sex: sex), 2)
        }
    }

    var body: some View {
        VStack(spacing: 12) {

            // Botão da data, abre o histórico de notificações.
            Button {
                showNotificationHistory = true
            } label: {
                Text(formattedDate)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(accentColor.opacity(0.33), lineWidth: 1.5)
                    }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: 330)
            .frame(maxWidth: .infinity, alignment: .center)
            .pressScale(1.20, response: 0.25, dampingFraction: 0.50)
            .accessibilityLabel(String(format: String(localized: "today.hero.date.a11y.label",
                                                     bundle: .gymNutshellCore), formattedDate))
            .accessibilityHint(String(localized: "today.hero.date.a11y.hint", bundle: .gymNutshellCore))

            // Anel de 5 segmentos com o emoji da conquista no centro e a porcentagem abaixo.
            // Substitui o par anel + bloco de conquista lado a lado da 1.0.
            TodayProgressRingView(progress: dailyProgress,
                                  achievement: dailyAchievement,
                                  theme: selectedTheme,
                                  onTap: { showRingSheet = true },
                                  onEmojiTap: { showTierSheet = true },
                                  size: verticalLayout ? 180 : 150)
                .frame(maxWidth: .infinity)
                .padding(.vertical, verticalLayout ? 8 : 4)

        }
        .sheet(isPresented: $showTierSheet) {
            NavigationStack {
                TierInfoView(
                    theme: selectedTheme, sex: sex, isSheet: true,
                    nextLevelPercent: nextLevelComponents?.percent,
                    nextLevelName: nextLevelComponents?.name ?? "",
                    nextLevelNumber: nextLevelComponents?.level,
                    isAtMaxLevel: dailyPercentage >= 90
                )
            }
        }
        .sheet(isPresented: $showRingSheet) {
            NavigationStack {
                ProgressRingInfoView(isSheet: true, currentPercent: dailyPercentage)
            }
        }
        .sheet(isPresented: $showNotificationHistory) {
            NotificationHistorySheet()
        }
    }
}
