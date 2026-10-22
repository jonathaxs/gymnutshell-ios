// ⌘
//  GymNutshell/GymNutshellApp/Views/TodayView/Components/TodaySideRail.swift
//
//  Propósito: Botões de navegação da Hoje: Ajustes, Registros, Conquistas e a troca lista/grade. No iPhone
//             Duo viram itens da barra vertical do sistema (AppTabHeader); no iPad deitado a TodayView mostra
//             a coluna própria de vidro daqui (TodaySideRail), no mesmo estilo. Sem coluna, os mesmos botões
//             ficam numa linha (TodayPageButtons): abaixo do anel no iPhone, acima da data no iPad em pé.
//             O histórico de notificações saiu da Hoje e fica no sino dos Ajustes.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-10-21.
// ⌘

import SwiftUI
import GymNutshellCore

/// Os botões de navegação da Hoje. A ordem dos casos é a da coluna, de cima pra baixo.
enum TodayRailItem: CaseIterable, Identifiable {
    case settings, records, achievements, viewMode
    var id: Self { self }

    /// Ícone da página Registros (prancheta).
    static let recordsSymbol = "list.clipboard"
}

/// Um botão de navegação, só o ícone na cor de destaque.
struct TodayRailButton: View {

    let item: TodayRailItem
    /// Cheio na coluna (como a barra do sistema); só o contorno na linha de botões redondos.
    var filled: Bool = true
    /// Tamanho travado do ícone na linha de botões redondos (nil na coluna).
    var iconSize: CGSize? = nil

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
                .frame(width: iconSize?.width, height: iconSize?.height)
                .contentTransition(.symbolEffect(.replace))
        }
        .accessibilityLabel(a11yLabel)
    }

    private var symbolName: String {
        let fill = filled ? ".fill" : ""
        switch item {
        case .settings:     return "gearshape" + fill
        case .records:      return TodayRailItem.recordsSymbol + fill
        case .achievements: return "trophy" + fill
        // Ícone do modo pra onde vai: em lista, o de grade; em grade, o de lista.
        case .viewMode:     return nextViewMode.symbolName
        }
    }

    private var a11yLabel: String {
        switch item {
        case .settings:     return String(localized: "settings.header.title", bundle: .gymNutshellCore)
        case .records:      return String(localized: "statistics.title", bundle: .gymNutshellCore)
        case .achievements: return String(localized: "achievements.header.title", bundle: .gymNutshellCore)
        case .viewMode:
            return String(format: String(localized: "today.goals.viewMode.switch.a11y", bundle: .gymNutshellCore),
                          nextViewMode.title)
        }
    }

    private func action() {
        switch item {
        case .settings:     router.open(.settings)
        case .records:      router.open(.statistics)
        case .achievements: router.open(.achievements)
        case .viewMode:
            UISelectionFeedbackGenerator().selectionChanged()
            let next = nextViewMode
            // Mola: os ícones da lista viram os círculos da grade (e voltam), o resto esmaece.
            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.5, dampingFraction: 0.82)) {
                goalsViewModeRaw = next.rawValue
            }
        }
    }
}

/// Coluna própria da Hoje no iPad deitado: os botões empilhados numa cápsula de vidro, como a barra vertical
/// do iPhone Duo.
struct TodaySideRail: View {

    var body: some View {
        VStack(spacing: 4) {
            ForEach(TodayRailItem.allCases) { item in
                TodayRailButton(item: item)
                    .buttonStyle(.plain)
                    .frame(width: 48, height: 48)
                    .contentShape(Circle())
            }
        }
        .padding(6)
        .appGlass(in: Capsule())
    }
}

/// Os mesmos botões numa linha de botões redondos de vidro, na mesma ordem da coluna (Ajustes primeiro). No iPhone
/// fica abaixo do anel; no layout largo em pé, acima da data.
struct TodayPageButtons: View {

    @AppStorage(AppAccentColor.storageKey) private var storedColorRaw: String = AppAccentColor.blue.rawValue
    private var accentColor: Color { (AppAccentColor(rawValue: storedColorRaw) ?? .blue).color }

    /// Conteúdo de cada botão. Com quatro botões cabe folgado no 13 mini (~311 pt úteis).
    private static let iconSize = CGSize(width: 30, height: 20)

    var body: some View {
        HStack(spacing: 10) {
            ForEach(TodayRailItem.allCases) { item in
                TodayRailButton(item: item, filled: false, iconSize: Self.iconSize)
                    .appSecondaryButton(accentColor, circle: true)
                    .controlSize(.regular)
            }
        }
    }
}
