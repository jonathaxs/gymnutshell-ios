// ⌘
//  GymNutshell/GymNutshellApp/Views/TodayView/Components/TodayHeroView.swift
//
//  Propósito: Bloco hero da tela Hoje, no topo (retrato) ou na coluna esquerda (landscape/iPad).
//             Contém: data grande + sino e engrenagem (opcional), o anel de progresso com a % no centro,
//             depois do primeiro registro a conquista do dia ao lado, a frase do próximo nível e os
//             botões das páginas Histórico e Conquistas (+ troca lista/grade no iPhone em retrato).
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
    /// true no iPhone em retrato: mostra ao lado de Conquistas o botão que alterna lista/grade das metas.
    var showsViewModeToggle: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(AppRouter.self) private var router

    @AppStorage(AppAccentColor.storageKey) private var storedColorRaw: String = AppAccentColor.blue.rawValue
    private var accentColor: Color { (AppAccentColor(rawValue: storedColorRaw) ?? .blue).color }

    @AppStorage(TodayGoalsViewMode.storageKey) private var goalsViewModeRaw: String = TodayGoalsViewMode.list.rawValue

    // Sexo do usuário, usado pra nomes e emojis de tier com gênero correto.
    @AppStorage(UserProfile.sexKey) private var sex: String = "male"

    // Sheets de informação do tier e do anel de progresso.
    @State private var showTierSheet = false
    @State private var showRingSheet = false

    // Percentual inteiro (0-100) calculado a partir do progresso normalizado.
    private var dailyPercentage: Int {
        Int((dailyProgress * 100).rounded(.down))
    }

    /// Nada marcado ainda: anel sozinho no centro, sem conquista ao lado.
    private var hasStarted: Bool { dailyProgress > 0 }

    private var ringSize: CGFloat { verticalLayout ? 170 : 150 }

    // Próximo nível: quanto falta (em %) e qual tier. nil no nível máximo (90%+).
    private var nextLevel: (percent: Int, tier: DailyAchievement)? {
        if dailyPercentage >= 90 { return nil }
        if dailyPercentage >= 66 { return (90 - dailyPercentage, .level4) }
        if dailyPercentage >= 33 { return (66 - dailyPercentage, .level3) }
        return (33 - dailyPercentage, .level2)
    }

    private var nextLevelNumber: Int? {
        switch nextLevel?.tier {
        case .level2: return 2
        case .level3: return 3
        case .level4: return 4
        default:      return nil
        }
    }

    private var tierEmoji: String { selectedTheme.emoji(for: dailyAchievement, sex: sex) }
    private var tierName: String { selectedTheme.name(for: dailyAchievement, sex: sex) }

    var body: some View {
        content
            .sheet(isPresented: $showTierSheet) {
                NavigationStack {
                    TierInfoView(
                        theme: selectedTheme, sex: sex, isSheet: true,
                        nextLevelPercent: nextLevel?.percent,
                        nextLevelName: nextLevel.map { selectedTheme.name(for: $0.tier, sex: sex) } ?? "",
                        nextLevelNumber: nextLevelNumber,
                        isAtMaxLevel: dailyPercentage >= 90
                    )
                }
            }
            .sheet(isPresented: $showRingSheet) {
                NavigationStack {
                    ProgressRingInfoView(isSheet: true, currentPercent: dailyPercentage)
                }
            }
    }

    private var content: some View {
        VStack(spacing: 12) {

            // Topo: sino à esquerda, a data em fonte grande no meio e a engrenagem à direita.
            if showsHeader {
                AppTabHeader(title: formattedDate)
                    .padding(.horizontal, 4)
            }

            VStack(spacing: 16) {
                // O anel mantém a identidade no HStack: quando a conquista entra, ele só desliza.
                HStack(spacing: 36) {
                    TodayProgressRingView(progress: dailyProgress,
                                          onTap: { showRingSheet = true },
                                          size: ringSize,
                                          celebratesAfterOnboarding: true)

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

                pageButtons
            }
            .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.55, dampingFraction: 0.82),
                       value: hasStarted)
            .padding(.vertical, verticalLayout ? 8 : 4)
        }
    }

    // MARK: - Conquista ao lado do anel

    /// Rótulo, emoji grande e nome, centralizados entre si e da mesma altura do anel.
    private var achievementPanel: some View {
        VStack(spacing: 4) {
            // "Conquista do dia" numa linha só; encolhe um pouco se a largura do painel não der.
            Text(String(localized: "today.hero.achievement.label", bundle: .gymNutshellCore))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

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
        .frame(width: 130, height: ringSize)
        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.6), value: tierEmoji)
        .contentShape(Rectangle())
        .onTapGesture { showTierSheet = true }
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(String(format: String(localized: "today.tier.a11y.label", bundle: .gymNutshellCore),
                                   tierEmoji, tierName))
        .accessibilityHint(A11y.moreInfoHint())
    }

    // MARK: - Botões das páginas

    /// Histórico (com texto) e Conquistas (só o troféu) abrem como páginas por cima da Hoje.
    /// Os botões abraçam o conteúdo: a linha fica estreita e centralizada, perto da largura da frase acima.
    private var pageButtons: some View {
        HStack(spacing: 10) {
            if showsViewModeToggle {
                viewModeButton
            }
            recordsButton
            achievementsButton
        }
    }

    private var recordsButton: some View {
        Button {
            router.open(.statistics)
        } label: {
            Label(String(localized: "statistics.title", bundle: .gymNutshellCore),
                  systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
        }
        .appSecondaryButton(accentColor)
        .controlSize(.regular)
    }

    /// Largura do conteúdo dos botões só de ícone (redondos), enxuta pra linha ficar estreita e centralizada.
    private static let iconButtonWidth: CGFloat = 30
    private static let iconButtonHeight: CGFloat = 20

    private var achievementsButton: some View {
        Button {
            router.open(.achievements)
        } label: {
            Image(systemName: "trophy")
                .font(.title3.weight(.semibold))
                // Altura travada na do texto do Histórico: ícone maior sem aumentar o botão.
                .frame(width: Self.iconButtonWidth, height: Self.iconButtonHeight)
        }
        .appSecondaryButton(accentColor, circle: true)
        .controlSize(.regular)
        .accessibilityLabel(String(localized: "achievements.header.title", bundle: .gymNutshellCore))
    }

    /// Alterna entre lista e grade das metas (só no iPhone em retrato, onde o modo vale).
    private var viewModeButton: some View {
        let current = TodayGoalsViewMode(rawValue: goalsViewModeRaw) ?? .list
        let next: TodayGoalsViewMode = current == .list ? .grid : .list
        return Button {
            UISelectionFeedbackGenerator().selectionChanged()
            // Mola: os ícones da lista viram os círculos da grade (e voltam), o resto esmaece.
            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.5, dampingFraction: 0.82)) {
                goalsViewModeRaw = next.rawValue
            }
        } label: {
            // Ícone do modo pra onde vai: em lista, o de grade; em grade, o de lista.
            Image(systemName: next.symbolName)
                .font(.title3.weight(.semibold))
                // Altura travada na do texto do Histórico: ícone maior sem aumentar o botão.
                .frame(width: Self.iconButtonWidth, height: Self.iconButtonHeight)
                .contentTransition(.symbolEffect(.replace))
        }
        .appSecondaryButton(accentColor, circle: true)
        .controlSize(.regular)
        .accessibilityLabel(String(format: String(localized: "today.goals.viewMode.switch.a11y",
                                                  bundle: .gymNutshellCore), next.title))
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
        .onTapGesture { showTierSheet = true }
    }
}
