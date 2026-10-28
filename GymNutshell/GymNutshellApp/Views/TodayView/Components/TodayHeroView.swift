// ⌘
//  GymNutshell/GymNutshellApp/Views/TodayView/Components/TodayHeroView.swift
//
//  Propósito: Bloco hero da tela Hoje, no topo (retrato) ou na coluna esquerda (landscape/iPad).
//             Contém: data grande + sino e engrenagem (opcional), o anel de progresso com a % no centro,
//             depois do primeiro registro a conquista do dia ao lado e a frase do próximo nível.
//             Toques no anel, na conquista e na data abrem balões informativos (TodayInfoPopovers.swift). A linha de
//             botões (TodayPageButtons, em TodaySideRail.swift) é posicionada pela TodayView.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-29.
// ⌘

import SwiftUI
import GymNutshellCore

/// Bloco hero da TodayView. Antes de começar: anel centralizado com 0% e a dica embaixo.
/// No primeiro registro o anel desliza pra esquerda e a conquista (emoji + nome) entra ao lado.
struct TodayHeroView: View {

    let formattedDate: String
    let dailyAchievement: DailyAchievement
    let dailyProgress: Double
    let selectedTheme: AppTheme
    /// Quando true (iPad, sobra altura), o anel fica maior.
    var verticalLayout: Bool = false
    /// false no iPhone em retrato: a data + sino + engrenagem ficam fixos no topo da tela, fora do hero.
    var showsHeader: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Sexo do usuário, usado pra nomes e emojis de tier com gênero correto.
    @AppStorage(UserProfile.sexKey) private var sex: String = "male"

    // Balões de informação da conquista e do anel; o tema abre numa sheet a partir do balão da conquista.
    @State private var showTierInfo = false
    @State private var showRingInfo = false
    @State private var showThemeSheet = false

    @AppStorage(AppAccentColor.storageKey) private var storedColorRaw: String = AppAccentColor.blue.rawValue
    private var accentColor: Color { (AppAccentColor(rawValue: storedColorRaw) ?? .blue).color }

    // Percentual inteiro (0-100) calculado a partir do progresso normalizado.
    private var dailyPercentage: Int {
        Int((dailyProgress * 100).rounded(.down))
    }

    /// Nada marcado ainda: anel sozinho no centro, sem conquista ao lado.
    private var hasStarted: Bool { dailyProgress > 0 }

    private var ringSize: CGFloat { verticalLayout ? 170 : 150 }

    // Próximo nível: quanto falta (em %) e qual tier. nil no nível máximo (81%+).
    private var nextLevel: (percent: Int, tier: DailyAchievement)? {
        guard let next = DailyAchievement.from(percent: dailyPercentage).next else { return nil }
        return (next.minPercent - dailyPercentage, next)
    }

    private var tierEmoji: String { selectedTheme.emoji(for: dailyAchievement, sex: sex) }
    private var tierName: String { selectedTheme.name(for: dailyAchievement, sex: sex) }

    var body: some View {
        content
            .sheet(isPresented: $showThemeSheet) {
                NavigationStack {
                    ThemeSettingsView()
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button {
                                    showThemeSheet = false
                                } label: {
                                    Text(String(localized: "common.close", bundle: .gymNutshellCore))
                                        .foregroundStyle(accentColor)
                                }
                            }
                        }
                }
            }
    }

    /// Fecha o balão e, depois que ele some, abre o tema (duas apresentações juntas falham).
    private func openThemeFromTierInfo() {
        showTierInfo = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            showThemeSheet = true
        }
    }

    private var content: some View {
        VStack(spacing: 12) {

            // Topo: sino à esquerda, a data em fonte grande no meio e a engrenagem à direita.
            if showsHeader {
                AppTabHeader(title: formattedDate, showsDayInfo: true)
                    .padding(.horizontal, 4)
            }

            VStack(spacing: 16) {
                // O anel mantém a identidade no HStack: quando a conquista entra, ele só desliza.
                // Espaço curto: o emoji fica perto do anel e os dois juntos, centralizados com o resto da tela.
                HStack(spacing: 8) {
                    TodayProgressRingView(progress: dailyProgress,
                                          onTap: { showRingInfo = true },
                                          size: ringSize,
                                          celebratesAfterOnboarding: true)
                        .downwardPopover(isPresented: $showRingInfo) {
                            RingInfoPopover()
                        }

                    if hasStarted {
                        achievementPanel
                            .transition(reduceMotion
                                        ? .opacity
                                        : .opacity
                                            .combined(with: .scale(scale: 0.85, anchor: .leading))
                                            .combined(with: .offset(x: 24)))
                    }
                }
                .frame(maxWidth: .infinity)

                caption
            }
            .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.55, dampingFraction: 0.82),
                       value: hasStarted)
            .padding(.vertical, verticalLayout ? 8 : 4)
        }
    }

    // MARK: - Conquista ao lado do anel

    /// Emoji grande e nome, centralizados entre si e da mesma altura do anel.
    private var achievementPanel: some View {
        VStack(spacing: 4) {
            // Troca de nível: o emoji novo entra com escala.
            Text(tierEmoji)
                .font(.system(size: ringSize * 0.44))
                .id(tierEmoji)
                .transition(reduceMotion ? .opacity : .scale(scale: 0.4).combined(with: .opacity))

            Text(tierName)
                .font(.title3.weight(.bold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
                .id(tierName)
                .transition(.opacity)
        }
        // Largura só pro nome do nível caber; mais larga, sobra vão em volta do emoji e ele se afasta do anel.
        .frame(width: 116, height: ringSize)
        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.6), value: tierEmoji)
        .contentShape(Rectangle())
        .onTapGesture { showTierInfo = true }
        .downwardPopover(isPresented: $showTierInfo) {
            TierInfoPopover(theme: selectedTheme, sex: sex, accentColor: accentColor,
                            onChangeTheme: openThemeFromTierInfo)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(String(format: String(localized: "today.tier.a11y.label", bundle: .gymNutshellCore),
                                   tierEmoji, tierName))
        .accessibilityHint(A11y.moreInfoHint())
    }

    // MARK: - Frase abaixo

    /// Dica antes de começar; depois, quanto falta pro próximo nível;
    /// no nível máximo, um aviso de que já chegou lá.
    @ViewBuilder
    private var caption: some View {
        Group {
            if !hasStarted {
                Text(String(localized: "today.hero.caption.start", bundle: .gymNutshellCore))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            } else if let next = nextLevel {
                Text(String(format: String(localized: "today.hero.caption.nextLevel", bundle: .gymNutshellCore),
                            next.percent))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            } else {
                Text(String(localized: "today.hero.caption.max", bundle: .gymNutshellCore))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .transition(.opacity)
        .contentShape(Rectangle())
        // Antes de começar não há emoji pra ancorar o balão.
        .onTapGesture { if hasStarted { showTierInfo = true } }
    }
}
