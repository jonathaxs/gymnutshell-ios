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
/// `kind` define o controle das metas dela na tela Hoje (padrão, com descanso ou check-in).
/// Diferente das categorias fixas, o tipo de uma categoria personalizada pode ser trocado depois.
public struct CustomGoalCategory: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public var name: String
    public var kind: CategoryKind
    /// Nome do SF Symbol exibido no bloco da categoria (tela Hoje). Campo novo da 2.0.
    public var symbolName: String

    /// Ícone usado quando a categoria não tem um escolhido (ex: criada na 1.0).
    public static let defaultSymbolName = "square.grid.2x2.fill"

    /// Atalho da 1.0: liga o botão ON/OFF de "dia de descanso" nas metas da categoria.
    /// Desligar só volta pro padrão se a categoria era "com descanso" (check-in fica como está).
    public var supportsRestDay: Bool {
        get { kind == .restDay }
        set {
            if newValue { kind = .restDay } else if kind == .restDay { kind = .standard }
        }
    }

    public init(id: String = UUID().uuidString,
                name: String,
                kind: CategoryKind,
                symbolName: String = CustomGoalCategory.defaultSymbolName) {
        self.id = id
        self.name = name
        self.kind = kind
        self.symbolName = symbolName
    }

    public init(id: String = UUID().uuidString,
                name: String,
                supportsRestDay: Bool,
                symbolName: String = CustomGoalCategory.defaultSymbolName) {
        self.init(id: id, name: name, kind: supportsRestDay ? .restDay : .standard, symbolName: symbolName)
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, kind, supportsRestDay, symbolName
    }

    // Decodificação manual: dados e backups da 1.0 não têm `symbolName` nem `kind`.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        if let decodedKind = try c.decodeIfPresent(CategoryKind.self, forKey: .kind) {
            kind = decodedKind
        } else {
            let rest = try c.decodeIfPresent(Bool.self, forKey: .supportsRestDay) ?? false
            kind = rest ? .restDay : .standard
        }
        symbolName = try c.decodeIfPresent(String.self, forKey: .symbolName) ?? Self.defaultSymbolName
    }

    // Grava `supportsRestDay` junto com `kind`, pra backup continuar abrindo em versões antigas e no Android.
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(kind, forKey: .kind)
        try c.encode(supportsRestDay, forKey: .supportsRestDay)
        try c.encode(symbolName, forKey: .symbolName)
    }
}
