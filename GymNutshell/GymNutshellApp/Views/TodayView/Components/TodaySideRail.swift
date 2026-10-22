// ⌘
//  GymNutshell/GymNutshellApp/Views/TodayView/Components/TodaySideRail.swift
//
//  Propósito: Botões de navegação da Hoje numa coluna à direita: Ajustes, sino, Histórico, Conquistas e a
//             troca lista/grade, nessa ordem. No iPhone Duo dobrado viram itens da barra vertical do sistema
//             (AppTabHeader); no iPad deitado a TodayView mostra esta coluna própria, de vidro, no mesmo estilo.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-10-21.
// ⌘

import SwiftUI
import GymNutshellCore

extension EnvironmentValues {
    /// True quando a Hoje mostra a coluna própria à direita (iPad deitado). O cabeçalho esconde o sino e a engrenagem.
    @Entry var todaySideRail: Bool = false
}

/// Os botões da coluna, de cima pra baixo.
enum TodayRailItem: CaseIterable, Identifiable {
    case settings, notifications, records, achievements, viewMode
    var id: Self { self }
}

/// Um botão da coluna, só o ícone na cor de destaque. O sino só avisa quem mostra o histórico de notificações.
struct TodayRailButton: View {

    let item: TodayRailItem
    let onNotifications: () -> Void

    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage(AppAccentColor.storageKey) private var storedColorRaw: String = AppAccentColor.blue.rawValue
    private var accentColor: Color { (AppAccentColor(rawValue: storedColorRaw) ?? .blue).color }

    @AppStorage(TodayGoalsViewMode.storageKey) private var goalsViewModeRaw: String = TodayGoalsViewMode.list.rawValue

    /// Modo pra onde a troca vai: em lista, a grade; em grade, a lista.
    private var nextViewMode: TodayGoalsViewMode {
        (TodayGoalsViewMode(rawValue: goalsViewModeRaw) ?? .list) == .list ? .grid : .list
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: symbolName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(accentColor)
                .contentTransition(.symbolEffect(.replace))
        }
        .accessibilityLabel(a11yLabel)
    }

    private var symbolName: String {
        switch item {
        case .settings:      return "gearshape.fill"
        case .notifications: return "bell.fill"
        case .records:       return "clock.arrow.trianglehead.counterclockwise.rotate.90"
        case .achievements:  return "trophy.fill"
        case .viewMode:      return nextViewMode.symbolName
        }
    }

    private var a11yLabel: String {
        switch item {
        case .settings:      return String(localized: "settings.header.title", bundle: .gymNutshellCore)
        case .notifications: return String(localized: "today.hero.bell.a11y.label", bundle: .gymNutshellCore)
        case .records:       return String(localized: "statistics.title", bundle: .gymNutshellCore)
        case .achievements:  return String(localized: "achievements.header.title", bundle: .gymNutshellCore)
        case .viewMode:
            return String(format: String(localized: "today.goals.viewMode.switch.a11y", bundle: .gymNutshellCore),
                          nextViewMode.title)
        }
    }

    private func action() {
        switch item {
        case .settings:      router.open(.settings)
        case .notifications: onNotifications()
        case .records:       router.open(.statistics)
        case .achievements:  router.open(.achievements)
        case .viewMode:
            UISelectionFeedbackGenerator().selectionChanged()
            let next = nextViewMode
            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.5, dampingFraction: 0.82)) {
                goalsViewModeRaw = next.rawValue
            }
        }
    }
}

/// Coluna própria da Hoje no iPad deitado: os cinco botões empilhados numa cápsula de vidro, como a barra
/// vertical do iPhone Duo.
struct TodaySideRail: View {

    @State private var showNotificationHistory = false

    var body: some View {
        VStack(spacing: 4) {
            ForEach(TodayRailItem.allCases) { item in
                TodayRailButton(item: item) { showNotificationHistory = true }
                    .buttonStyle(.plain)
                    .frame(width: 48, height: 48)
                    .contentShape(Circle())
            }
        }
        .padding(6)
        .appGlass(in: Capsule())
        .sheet(isPresented: $showNotificationHistory) {
            NotificationHistorySheet()
        }
    }
}
