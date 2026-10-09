// ⌘
//  GymNutshellCore/Models/CustomGoalCategory.swift
//
//  Propósito: Categoria de meta criada pelo usuário. Criada a partir da AddTrackingGoalView
//             e persistida junto com CustomTrackingGoal via CustomGoalCategoriesStore.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-04-20.
// ⌘

import Foundation

/// Categoria de meta criada pelo usuário.
/// `supportsRestDay` liga o botão ON/OFF de "dia de descanso" em todas as metas que pertencerem a ela.
public struct CustomGoalCategory: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public var name: String
    public var supportsRestDay: Bool
    /// Nome do SF Symbol exibido no bloco da categoria (tela Hoje). Campo novo da 1.1.
    public var symbolName: String

    /// Ícone usado quando a categoria não tem um escolhido (ex: criada na 1.0).
    public static let defaultSymbolName = "square.grid.2x2.fill"

    public init(id: String = UUID().uuidString,
                name: String,
                supportsRestDay: Bool,
                symbolName: String = CustomGoalCategory.defaultSymbolName) {
        self.id = id
        self.name = name
        self.supportsRestDay = supportsRestDay
        self.symbolName = symbolName
    }

    // Decodificação manual: dados e backups da 1.0 não têm `symbolName`.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        supportsRestDay = try c.decode(Bool.self, forKey: .supportsRestDay)
        symbolName = try c.decodeIfPresent(String.self, forKey: .symbolName) ?? Self.defaultSymbolName
    }
}
