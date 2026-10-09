// ⌘
//  GymNutshell/GymNutshellApp/Views/Shared/CategorySymbolPicker.swift
//
//  Propósito: Seletor de ícone (SF Symbol) das categorias personalizadas. Grade com opções
//             curadas de fitness, comida, saúde e rotina. Usado na criação e na edição da categoria.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-10-08.
// ⌘

import SwiftUI
import GymNutshellCore

struct CategorySymbolPicker: View {

    @Binding var selection: String

    /// Opções disponíveis (todas existem no iOS 18).
    static let symbols: [String] = [
        "square.grid.2x2.fill", "star.fill", "heart.fill", "bolt.fill", "flame.fill", "leaf.fill",
        "figure.run", "figure.walk", "figure.strengthtraining.traditional", "figure.yoga", "figure.pool.swim", "figure.outdoor.cycle",
        "dumbbell.fill", "sportscourt.fill", "trophy.fill", "target", "timer", "stopwatch.fill",
        "fork.knife", "cup.and.saucer.fill", "carrot.fill", "drop.fill", "pills.fill", "cross.case.fill",
        "bed.double.fill", "moon.fill", "sun.max.fill", "brain.head.profile", "lungs.fill", "figure.mind.and.body",
        "book.fill", "pencil", "checkmark.seal.fill", "bell.fill", "calendar", "sparkles"
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Self.symbols, id: \.self) { symbol in
                let isSelected = symbol == selection
                Button {
                    UISelectionFeedbackGenerator().selectionChanged()
                    selection = symbol
                } label: {
                    Image(systemName: symbol)
                        .font(.title3)
                        .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(symbol)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
        .padding(.vertical, 4)
    }
}
