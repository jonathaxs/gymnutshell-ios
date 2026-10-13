// ⌘
//  GymNutshell/GymNutshellApp/Views/TodayView/Components/TodayGoalsGrid.swift
//
//  Propósito: Layout coluna-major do grid de metas em Hoje (modo wide).
//             Recebe células já renderizadas e distribui em N colunas calculadas
//             a partir da largura disponível, mantendo ordem topo→baixo por coluna.
//             Sem dependência do state do TodayView, só células + chave de animação.
// ⌘

import SwiftUI

/// Wrapper Identifiable pra alimentar o grid com células heterogêneas.
struct TodayGridCell: Identifiable {
    let id: String
    let view: AnyView

    init(id: String, @ViewBuilder view: () -> AnyView) {
        self.id = id
        self.view = view()
    }
}

/// Grid coluna-major usado pelo layout wide do TodayView.
///
/// Distribuição: itens caem de cima pra baixo na coluna 1, depois a 2, etc. Em vez
/// de LazyVGrid (que alinha por linha e cria gaps quando categorias têm alturas
/// diferentes), usa um HStack de VStacks, cada coluna sobe livremente sem ser
/// puxada pela mais alta da linha.
struct TodayGoalsGrid: View {
    let cells: [TodayGridCell]
    let animationKey: String

    var body: some View {
        GeometryReader { proxy in
            let cellMinWidth: CGFloat = 320
            let columnSpacing: CGFloat = 16
            let available = proxy.size.width
            // Cap nos itens disponíveis, sem isso, em janelas absurdamente largas
            // (4K macOS / Vision Pro) o número de colunas calculado é maior que o
            // de células, e a regra "remainder vai pras últimas colunas" empurra
            // todo o conteúdo pro lado direito da tela.
            let cellCount = cells.count
            let computed = max(1, Int((available + columnSpacing) / (cellMinWidth + columnSpacing)))
            let columnsCount = max(1, min(computed, cellCount))
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    gridColumns(count: columnsCount, spacing: columnSpacing)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer(minLength: 0)
                }
                .frame(minHeight: proxy.size.height)
                .padding(.vertical, 12)
                .padding(.trailing, 33)
            }
        }
        .animation(.easeInOut(duration: 0.28), value: animationKey)
    }

    // Cada coluna recebe um pedaço contínuo da lista (não intercalado), pra que
    // a ordem visual leia "topo→baixo, depois próxima coluna".
    // Distribuição: base = N/cols (chão), remainder = N % cols. As colunas finais
    // recebem o item extra, assim, ao adicionar uma nova categoria, ela cai na
    // coluna da direita (que tinha espaço útil) em vez de empurrar a coluna
    // esquerda pra ficar mais alta.
    @ViewBuilder
    private func gridColumns(count: Int, spacing: CGFloat) -> some View {
        let total = cells.count
        let base = total / count
        let remainder = total % count
        let perColumnCounts: [Int] = (0..<count).map { col in
            base + (col >= count - remainder ? 1 : 0)
        }
        HStack(alignment: .top, spacing: spacing) {
            ForEach(0..<count, id: \.self) { col in
                let start = perColumnCounts.prefix(col).reduce(0, +)
                let end = start + perColumnCounts[col]
                if start < end {
                    VStack(spacing: 20) {
                        ForEach(start..<end, id: \.self) { idx in
                            cells[idx].view
                        }
                    }
                    .frame(maxWidth: 460, alignment: .top)
                    .frame(maxWidth: .infinity, alignment: .top)
                } else {
                    Color.clear.frame(maxWidth: .infinity, maxHeight: 0)
                }
            }
        }
    }
}
