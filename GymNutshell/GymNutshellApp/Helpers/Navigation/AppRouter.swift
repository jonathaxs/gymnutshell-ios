// ⌘
//  GymNutshell/GymNutshellApp/Helpers/Navigation/AppRouter.swift
//
//  Propósito: Roteador único do app. Guarda o caminho do NavigationStack raiz (MainView), a sheet
//             aberta por cima da Hoje (Registros ou Calendário) e o caminho dentro dela, e deixa
//             qualquer tela, widget ou notificação abrir uma página sem conhecer a hierarquia.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-10-13.
// ⌘

import SwiftUI

// MARK: - Rotas

/// Páginas que os NavigationStacks (raiz e da sheet) sabem abrir.
enum AppRoute: Hashable {
    case statistics
    case achievements
    case settings
    case settingsBackup
    /// Editar metas (aberta pelas Estatísticas, por Ajustes e pelo atalho da Hoje).
    case settingsGoals
    case settingsControls
    case userGoal
}

/// Telas que abrem em sheet por cima da Hoje. Só os Ajustes continuam como página.
enum AppSheet: String, Identifiable {
    case statistics
    case achievements

    var id: String { rawValue }
}

// MARK: - Roteador

/// Estado de navegação do app (MV: é um store, não um ViewModel). Injetado via `.environment`.
@Observable
final class AppRouter {

    var path: [AppRoute] = []

    /// Sheet aberta por cima da Hoje (nil = nenhuma).
    var sheet: AppSheet?

    /// Caminho dentro da sheet (ex.: Registros → Calendário de um dia).
    var sheetPath: [AppRoute] = []

    /// Com uma sheet aberta, empilha dentro dela. Sem sheet, Registros e Calendário abrem em
    /// sheet e o resto empilha no stack raiz. Ajustes sempre é página: fecha a sheet antes.
    func open(_ route: AppRoute) {
        if route == .settings {
            sheet = nil
            guard path.last != route else { return }
            path.append(route)
        } else if sheet != nil {
            guard sheetPath.last != route else { return }
            sheetPath.append(route)
        } else if route == .statistics {
            present(.statistics)
        } else if route == .achievements {
            present(.achievements)
        } else {
            guard path.last != route else { return }
            path.append(route)
        }
    }

    /// Abre a sheet do zero (sem páginas empilhadas dentro).
    func present(_ newSheet: AppSheet) {
        sheetPath = []
        sheet = newSheet
    }

    /// Troca todo o caminho (deep-links) e a sheet. Sem argumentos volta pra Hoje.
    func reset(to routes: [AppRoute] = [], sheet newSheet: AppSheet? = nil) {
        if path != routes { path = routes }
        if let newSheet {
            present(newSheet)
        } else {
            sheet = nil
        }
    }
}
