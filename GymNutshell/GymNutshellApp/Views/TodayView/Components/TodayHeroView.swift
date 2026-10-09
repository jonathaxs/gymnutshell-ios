// ⌘
//  GymNutshell/GymNutshellApp/Views/TodayView/Components/TodayHeroView.swift
//
//  Propósito: Bloco hero fixo exibido no topo (retrato) ou na coluna esquerda (landscape).
//             Contém: saudação com a data, sino do histórico de notificações e o anel de progresso.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-29.
// ⌘

import SwiftUI
import GymNutshellCore

/// Bloco hero da TodayView: saudação, data, sino, anel de progresso e frase do próximo nível.
struct TodayHeroView: View {

    let formattedDate: String
    let dailyAchievement: DailyAchievement
    let dailyProgress: Double
    let selectedTheme: AppTheme
    /// Quando true (iPad, sobra altura), o anel fica maior.
    var verticalLayout: Bool = false
    /// iPhone em retrato: saudação em cima e um card com o anel à esquerda e a % com a frase à direita.
    var cardStyle: Bool = false

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

    // Frase abaixo do anel: dica no 0%, quanto falta pro próximo nível, ou o nome do nível no máximo.
    private var ringCaption: String {
        if dailyPercentage <= 0 {
            return String(localized: "today.hero.caption.start", bundle: .gymNutshellCore)
        }
        if let next = nextLevelComponents {
            return String(format: String(localized: "today.hero.caption.next", bundle: .gymNutshellCore),
                          next.percent, next.name)
        }
        return ""
    }

    // Frase ao lado do anel (card): a dica / quanto falta; no nível máximo, o nome do nível.
    private var cardCaption: String {
        ringCaption.isEmpty ? selectedTheme.name(for: dailyAchievement, sex: sex) : ringCaption
    }

    var body: some View {
        content
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

    // MARK: - Sino

    private var bellButton: some View {
        Button {
            showNotificationHistory = true
        } label: {
            Image(systemName: "bell.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(accentColor)
                .frame(width: 44, height: 44)
        }
        .appCircleButton()
        .accessibilityLabel(String(localized: "today.hero.bell.a11y.label", bundle: .gymNutshellCore))
        .accessibilityHint(String(localized: "today.hero.bell.a11y.hint", bundle: .gymNutshellCore))
    }

    // MARK: - Saudação + data

    private var greetingBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(greeting)
                .font(.largeTitle.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .accessibilityAddTraits(.isHeader)
            Text(formattedDate)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Card (iPhone em retrato)

    private var cardContent: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                greetingBlock
                bellButton
            }
            .padding(.horizontal, 4)

            HStack(spacing: 20) {
                TodayProgressRingView(progress: dailyProgress,
                                      achievement: dailyAchievement,
                                      theme: selectedTheme,
                                      onTap: { showRingSheet = true },
                                      onEmojiTap: { showTierSheet = true },
                                      size: 124,
                                      lineWidth: 14,
                                      showsLabels: false)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(dailyPercentage)%")
                        .font(.system(size: 46, weight: .bold, design: .rounded).monospacedDigit())
                        .contentTransition(.numericText())
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    Text(cardCaption)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture { showRingSheet = true }
                // Porcentagem + frase num único elemento de VoiceOver.
                .accessibilityElement(children: .ignore)
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel(String(localized: "today.ring.a11y.label", bundle: .gymNutshellCore))
                .accessibilityValue(String(format: String(localized: "today.ring.a11y.value",
                                                          bundle: .gymNutshellCore), dailyPercentage))
                .accessibilityHint(String(localized: "today.ring.a11y.hint", bundle: .gymNutshellCore))
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .appCard()
        }
    }

    @ViewBuilder
    private var content: some View {
        if cardStyle {
            cardContent
        } else {
            classicContent
        }
    }

    private var classicContent: some View {
        VStack(spacing: 12) {

            // Topo: saudação grande com a data pequena embaixo e o sino do histórico no canto.
            HStack(alignment: .center, spacing: 12) {
                greetingBlock
                bellButton
            }
            .padding(.horizontal, 4)

            // Anel de 5 segmentos com o emoji da conquista no centro e a porcentagem abaixo.
            // Substitui o par anel + bloco de conquista lado a lado da 1.0.
            TodayProgressRingView(progress: dailyProgress,
                                  achievement: dailyAchievement,
                                  theme: selectedTheme,
                                  onTap: { showRingSheet = true },
                                  onEmojiTap: { showTierSheet = true },
                                  caption: ringCaption,
                                  size: verticalLayout ? 180 : 150)
                .frame(maxWidth: .infinity)
                .padding(.vertical, verticalLayout ? 8 : 4)

        }
    }
}
