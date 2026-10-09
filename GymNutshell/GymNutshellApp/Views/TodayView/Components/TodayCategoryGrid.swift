// ⌘
//  GymNutshell/GymNutshellApp/Views/TodayView/Components/TodayCategoryGrid.swift
//
//  Propósito: Grade de categorias da tela Hoje (iPhone). Cada categoria vira um bloco com
//             ícone, nome e progresso; tocar abre um balão (popover) saindo do bloco com os
//             controles das metas daquela categoria. 2 colunas; linha com item único fica centralizada.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-10-08.
// ⌘

import SwiftUI
import GymNutshellCore

/// Dados de um bloco da grade. O conteúdo do balão já vem renderizado pela TodayView.
struct TodayCategoryTile: Identifiable {
    let id: String
    let title: String
    let symbolName: String
    /// Média de progresso das metas da categoria (0...1).
    let progress: Double
    let completedCount: Int
    let totalCount: Int
    let content: AnyView
}

struct TodayCategoryGrid: View {

    let tiles: [TodayCategoryTile]
    let accentColor: Color

    /// Bloco com o balão aberto (nil = nenhum).
    @State private var openTileId: String? = nil

    private let spacing: CGFloat = 12

    var body: some View {
        // Agrupa em linhas de 2. A última linha com 1 item fica centralizada (mesma largura dos outros).
        let rows = stride(from: 0, to: tiles.count, by: 2).map { Array(tiles[$0..<min($0 + 2, tiles.count)]) }

        GeometryReader { proxy in
            let tileWidth = (proxy.size.width - spacing) / 2
            VStack(spacing: spacing) {
                ForEach(rows, id: \.first?.id) { row in
                    HStack(spacing: spacing) {
                        ForEach(row) { tile in
                            tileView(tile)
                                .frame(width: tileWidth)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(height: gridHeight(rows: rows.count))
    }

    // Altura fixa por linha pra o GeometryReader não colapsar.
    private static let tileHeight: CGFloat = 128

    private func gridHeight(rows: Int) -> CGFloat {
        CGFloat(rows) * Self.tileHeight + CGFloat(max(rows - 1, 0)) * spacing
    }

    // MARK: - Bloco

    private func tileView(_ tile: TodayCategoryTile) -> some View {
        let isDone = tile.totalCount > 0 && tile.completedCount == tile.totalCount
        return Button {
            UISelectionFeedbackGenerator().selectionChanged()
            openTileId = tile.id
        } label: {
            VStack(spacing: 8) {
                // Ícone dentro de um mini anel com o progresso da categoria.
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.18), lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: min(max(tile.progress, 0), 1))
                        .stroke(isDone ? Color.green : accentColor,
                                style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.4), value: tile.progress)
                    Image(systemName: isDone ? "checkmark" : tile.symbolName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(isDone ? Color.green : accentColor)
                        .contentTransition(.symbolEffect(.replace))
                }
                .frame(width: 52, height: 52)

                Text(tile.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("\(tile.completedCount)/\(tile.totalCount)")
                    .font(.caption.weight(.medium).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: Self.tileHeight)
            .background(Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
        .pressScale(1.05, response: 0.25, dampingFraction: 0.6)
        .popover(isPresented: Binding(
            get: { openTileId == tile.id },
            set: { if !$0 { openTileId = nil } }
        )) {
            popoverContent(tile)
                // Balão de verdade no iPhone, em vez de virar sheet.
                .presentationCompactAdaptation(.popover)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(tile.title)
        .accessibilityValue(String(format: String(localized: "today.category.tile.a11y.value",
                                                  bundle: .gymNutshellCore),
                                   tile.completedCount, tile.totalCount))
        .accessibilityHint(String(localized: "today.category.tile.a11y.hint", bundle: .gymNutshellCore))
    }

    // MARK: - Balão

    private func popoverContent(_ tile: TodayCategoryTile) -> some View {
        TodayCategoryPopover(tile: tile, accentColor: accentColor)
    }
}

// MARK: - Conteúdo do balão

/// Título da categoria + metas. Mede a altura das metas pra o balão ter o tamanho certo:
/// cresce até caber tudo e, acima do limite (ou do espaço na tela), rola.
private struct TodayCategoryPopover: View {

    let tile: TodayCategoryTile
    let accentColor: Color

    @State private var contentHeight: CGFloat = 0

    private let headerHeight: CGFloat = 48
    private let maxHeight: CGFloat = 520

    private var desiredHeight: CGFloat {
        min(headerHeight + max(contentHeight, 80), maxHeight)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: tile.symbolName)
                    .foregroundStyle(accentColor)
                    .accessibilityHidden(true)
                Text(tile.title)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
            }
            .frame(maxWidth: .infinity)
            .frame(height: headerHeight)

            ScrollView {
                VStack(spacing: 10) {
                    tile.content
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        // Altura ideal = tudo visível (até o limite); mínima flexível pra encolher quando
        // a tela não tem espaço, mantendo o título e rolando as metas.
        .frame(width: 340)
        .frame(minHeight: headerHeight + 80,
               idealHeight: desiredHeight,
               maxHeight: desiredHeight)
        .background(Color(.systemGroupedBackground))
    }
}
