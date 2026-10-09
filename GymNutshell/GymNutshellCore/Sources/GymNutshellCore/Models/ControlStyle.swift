// ⌘
//  GymNutshellCore/Models/ControlStyle.swift
//
//  Propósito: Estilo global dos controles de registro das metas (slider ou botões − / +).
//             Escolhido na Welcome e editável em Ajustes.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-10-08.
// ⌘

import Foundation

/// Como o usuário marca o progresso de cada meta na tela Hoje.
public enum ControlStyle: String, CaseIterable, Identifiable, Sendable {
    case slider
    case stepper

    public var id: String { rawValue }

    public static let storageKey = "app.controlStyle"
    public static let `default`: ControlStyle = .slider
}
