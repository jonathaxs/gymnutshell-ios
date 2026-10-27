// ⌘
//  GymNutshellWatch/WatchGoalEntry.swift
//
//  Propósito: Modelo leve usado para listar metas no Watch app.
//             Não persiste, é construído a cada render a partir das chaves
//             do GoalOrderStore.
// ⌘

import Foundation

/// Modelo leve só pra listar as metas no Watch, não persiste, é construído a cada render.
struct GoalEntry: Identifiable {
    let id: String
    let emoji: String
    /// Nome localizado da meta (ex: "Treino", "Água"), usado nos labels de a11y
    /// dos botões ± para o VoiceOver não falar só "Aumentar".
    let displayName: String
    let current: Int
    let goal: Int
    let unit: String
    let increment: Int
    let update: (Int) -> Void
    /// Categoria check-in (ex: Creatina em Suplemento): um toque alterna Pendente ↔ Feito, sem − / +.
    var isCheckIn: Bool = false
}
