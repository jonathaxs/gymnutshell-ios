// ⌘
//  GymNutshellCore/Models/NotificationRoute.swift
//
//  Propósito: Rotas suportadas pelas notificações, definem pra onde o app navega ao tocar.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-04-23.
// ⌘

import Foundation

/// Rotas suportadas pelas notificações, definem pra onde o app navega ao tocar.
public enum NotificationRoute: String, Sendable {
    case today              // TodayView
    case achievementsToday  // AchievementsView no dia de hoje, filtro "dia"
    case backup             // Ajustes → Backup
    case settingsGoals      // Ajustes → Metas (atalho da Today)
    case settingsControls   // Ajustes → Controles (atalho da Today)
}
