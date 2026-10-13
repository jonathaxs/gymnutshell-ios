// ⌘
//  GymNutshell/GymNutshellApp/Helpers/Navigation/AppRouter.swift
//
//  Propósito: Roteador único do app. Guarda o caminho do NavigationStack raiz (MainView) e deixa
//             qualquer tela, widget ou notificação abrir uma página sem conhecer a hierarquia.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-10-13.
// ⌘

import SwiftUI

// MARK: - Rotas

/// Páginas que o NavigationStack raiz sabe abrir por cima da Hoje.
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

// MARK: - Roteador

/// Estado de navegação do app (MV: é um store, não um ViewModel). Injetado via `.environment`.
@Observable
final class AppRouter {

    var path: [AppRoute] = []

    /// Empilha a página por cima da atual (não repete se já é a do topo).
    func open(_ route: AppRoute) {
        guard path.last != route else { return }
        path.append(route)
    }

    /// Troca todo o caminho (deep-links). Lista vazia volta pra Hoje.
    func reset(to routes: [AppRoute] = []) {
        guard path != routes else { return }
        path = routes
    }
}
