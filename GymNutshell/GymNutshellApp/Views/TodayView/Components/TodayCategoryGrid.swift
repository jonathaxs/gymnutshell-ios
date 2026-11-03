// ⌘
//  GymNutshell/GymNutshellApp/Views/TodayView/Components/TodayCategoryGrid.swift
//
//  Propósito: Grade de categorias da tela Hoje (modo "Grade", no retrato e no layout largo). Cada categoria vira um botão redondo de
//             vidro (iOS 26+) com ícone e mini anel de progresso, nome e contagem embaixo; tocar abre
//             um balão (popover) abaixo do botão com os controles das metas daquela categoria.
//             4 por linha; a última linha incompleta fica centralizada. O balão abre pro lado com mais
//             espaço; no iOS 18 é apresentado pelo UIKit, que respeita a seta (o SwiftUI ignorava).
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-10-08.
// ⌘

import SwiftUI
import GymNutshellCore

// MARK: - Modo de visualização das metas

/// Como a Hoje mostra as metas: lista agrupada (padrão) ou grade de botões com balão.
enum TodayGoalsViewMode: String, CaseIterable {
    case list
    case grid

    static let storageKey = "today.goals.viewMode"

    var symbolName: String { self == .list ? "list.bullet" : "square.grid.2x2" }

    var title: String {
        switch self {
        case .list: return String(localized: "today.goals.viewMode.list", bundle: .gymNutshellCore)
        case .grid: return String(localized: "today.goals.viewMode.grid", bundle: .gymNutshellCore)
        }
    }
}

/// Dados de um bloco da grade. O conteúdo do balão já vem renderizado pela TodayView.
struct TodayCategoryTile: Identifiable {
    let id: String
    let title: String
    let symbolName: String
    /// Média de progresso das metas da categoria (0...1).
    let progress: Double
    let completedCount: Int
    let totalCount: Int
    /// Cor própria da categoria (as fixas têm a sua); nil usa a cor de destaque.
    var tint: Color? = nil
    let content: AnyView
}

extension GoalCategory {
    /// Cor fixa de cada categoria na grade: Essencial vermelho, Nutrição verde, Treino laranja, Suplemento violeta.
    var tintColor: Color {
        switch self {
        case .essencial:  return AppAccentColor.red.color
        case .nutricao:   return AppAccentColor.green.color
        case .treino:     return AppAccentColor.orange.color
        case .suplemento: return AppAccentColor.purple.color
        }
    }
}

struct TodayCategoryGrid: View {

    let tiles: [TodayCategoryTile]
    let accentColor: Color

    @Environment(\.todayMorphNamespace) private var morphNamespace

    /// Bloco com o balão aberto (nil = nenhum).
    @State private var openTileId: String? = nil

    private let spacing: CGFloat = 8
    private let columns = 4
    /// Diâmetro máximo do botão; em telas estreitas ele encolhe pra caber na coluna.
    private static let maxCircleSize: CGFloat = 88

    var body: some View {
        // Agrupa em linhas de 4. A última linha com menos itens fica centralizada (mesma largura dos outros).
        let rows = stride(from: 0, to: tiles.count, by: columns).map {
            Array(tiles[$0..<min($0 + columns, tiles.count)])
        }

        GeometryReader { proxy in
            let tileWidth = (proxy.size.width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
            VStack(spacing: spacing) {
                ForEach(rows, id: \.first?.id) { row in
                    HStack(spacing: spacing) {
                        ForEach(row) { tile in
                            tileView(tile, circleSize: min(Self.maxCircleSize, tileWidth - 2))
                                .frame(width: tileWidth)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(height: gridHeight(rows: rows.count))
        // Abrir outra página (ex: deep-link) com o balão aberto: fecha o balão.
        .onDisappear { openTileId = nil }
    }

    // Altura fixa por linha pra o GeometryReader não colapsar.
    private static let tileHeight: CGFloat = 134

    private func gridHeight(rows: Int) -> CGFloat {
        CGFloat(rows) * Self.tileHeight + CGFloat(max(rows - 1, 0)) * spacing
    }

    // MARK: - Botão redondo

    private func tileView(_ tile: TodayCategoryTile, circleSize: CGFloat) -> some View {
        let isDone = tile.totalCount > 0 && tile.completedCount == tile.totalCount
        let tint = tile.tint ?? accentColor
        let isOpen = Binding(
            get: { openTileId == tile.id },
            set: { if !$0 { openTileId = nil } }
        )
        return Button {
            UISelectionFeedbackGenerator().selectionChanged()
            openTileId = tile.id
        } label: {
            VStack(spacing: 6) {
                // Ícone dentro de um mini anel com o progresso da categoria, sobre vidro.
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.18), lineWidth: 5)
                        .padding(6)
                    Circle()
                        .trim(from: 0, to: min(max(tile.progress, 0), 1))
                        .stroke(isDone ? Color.green : tint,
                                style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .padding(6)
                        .animation(.easeInOut(duration: 0.4), value: tile.progress)
                    Image(systemName: isDone ? "checkmark" : tile.symbolName)
                        .font(.system(size: circleSize * 0.32, weight: .semibold))
                        .foregroundStyle(isDone ? Color.green : tint)
                        .contentTransition(.symbolEffect(.replace))
                }
                .frame(width: circleSize, height: circleSize)
                .background(Circle().fill(Color(.secondarySystemGroupedBackground)))
                .circleGlass()
                // Na troca de modo, o círculo nasce do ícone do cabeçalho da lista (e volta pra ele).
                .todayMorph("icon-\(tile.id)", in: morphNamespace)

                Text(tile.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .todayMorph("title-\(tile.id)", in: morphNamespace, properties: .position)

                Text("\(tile.completedCount)/\(tile.totalCount)")
                    .font(.caption2.weight(.medium).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: Self.tileHeight, alignment: .top)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .pressScale(1.05, response: 0.25, dampingFraction: 0.6)
        // Balão abaixo do botão (ou acima, se embaixo não couber).
        .adaptivePopover(isPresented: isOpen) {
            popoverContent(tile)
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
        TodayCategoryPopover(tile: tile, accentColor: tile.tint ?? accentColor)
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

// MARK: - Balão que abre pro lado com mais espaço

/// Também usado no Visualizar das telas de Emoji (Welcome e Ajustes) e nos balões da Welcome e da Hoje.
extension View {

    /// Balão preso à view: abre pra baixo (seta no topo) e, quando falta espaço embaixo e sobra em cima
    /// (ex: última linha de uma lista rolada até o fim), abre pra cima. iOS 26+: popover do SwiftUI.
    /// iOS 18: o SwiftUI ignorava o arrowEdge, então o UIKit apresenta com a seta escolhida.
    func adaptivePopover<Content: View>(isPresented: Binding<Bool>,
                                        @ViewBuilder content: @escaping () -> Content) -> some View {
        modifier(AdaptivePopoverModifier(isPresented: isPresented, popoverContent: content))
    }
}

/// Espaço mínimo embaixo pra o balão abrir pra baixo sem ficar espremido.
private let popoverComfortableHeight: CGFloat = 360

/// Abre pra cima só quando embaixo tem pouco espaço e em cima tem mais.
private func popoverOpensUp(frame: CGRect, in window: UIWindow) -> Bool {
    let insets = window.safeAreaInsets
    let below = window.bounds.height - insets.bottom - frame.maxY
    let above = frame.minY - insets.top
    return below < popoverComfortableHeight && above > below
}

private struct AdaptivePopoverModifier<PopoverContent: View>: ViewModifier {

    @Binding var isPresented: Bool
    let popoverContent: () -> PopoverContent

    @State private var opensUp = false

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                // Acompanha a posição na tela (rolagem incluída) e decide o lado antes de abrir.
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
                    guard let window = UIApplication.shared.connectedScenes
                        .compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first else { return }
                    let up = popoverOpensUp(frame: frame, in: window)
                    if up != opensUp { opensUp = up }
                }
                .popover(isPresented: $isPresented,
                         attachmentAnchor: .point(opensUp ? .top : .bottom),
                         arrowEdge: opensUp ? .bottom : .top) {
                    popoverContent()
                        // Balão de verdade no iPhone, em vez de virar sheet.
                        .presentationCompactAdaptation(.popover)
                }
        } else {
            content.background(AdaptivePopoverPresenter(isPresented: $isPresented, content: popoverContent))
        }
    }
}

/// Apresenta o conteúdo num popover do UIKit preso à view, abrindo pro lado com mais espaço.
/// O tamanho acompanha o tamanho ideal do conteúdo (preferredContentSize).
private struct AdaptivePopoverPresenter<Content: View>: UIViewControllerRepresentable {

    @Binding var isPresented: Bool
    let content: () -> Content

    func makeCoordinator() -> Coordinator { Coordinator(isPresented: $isPresented) }

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        controller.view.isUserInteractionEnabled = false
        return controller
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {
        context.coordinator.isPresented = $isPresented
        let hosting = context.coordinator.hosting

        if isPresented {
            if let hosting {
                // Balão já aberto: atualiza as metas (valores mudam a cada toque).
                hosting.rootView = AnyView(content())
            } else if controller.presentedViewController == nil, let window = controller.view.window {
                let host = UIHostingController(rootView: AnyView(content()))
                host.sizingOptions = .preferredContentSize
                host.view.backgroundColor = .systemGroupedBackground
                host.modalPresentationStyle = .popover
                if let popover = host.popoverPresentationController {
                    popover.sourceView = controller.view
                    let bounds = controller.view.bounds
                    let up = popoverOpensUp(frame: controller.view.convert(bounds, to: window), in: window)
                    popover.sourceRect = CGRect(x: bounds.midX, y: up ? bounds.minY : bounds.maxY, width: 0, height: 0)
                    popover.permittedArrowDirections = up ? .down : .up
                    popover.delegate = context.coordinator
                }
                context.coordinator.hosting = host
                controller.present(host, animated: true)
            }
        } else if let hosting {
            context.coordinator.hosting = nil
            hosting.dismiss(animated: true)
        }
    }

    final class Coordinator: NSObject, UIPopoverPresentationControllerDelegate {
        var isPresented: Binding<Bool>
        var hosting: UIHostingController<AnyView>?

        init(isPresented: Binding<Bool>) { self.isPresented = isPresented }

        // Mantém o balão no iPhone (sem virar sheet).
        func adaptivePresentationStyle(for controller: UIPresentationController,
                                       traitCollection: UITraitCollection) -> UIModalPresentationStyle {
            .none
        }

        // Fechou tocando fora: avisa o SwiftUI.
        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            hosting = nil
            isPresented.wrappedValue = false
        }
    }
}

// MARK: - Vidro do botão redondo

private extension View {

    /// Vidro interativo no iOS 26+; nas versões anteriores o fundo sólido do card já basta.
    @ViewBuilder
    func circleGlass() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.interactive(), in: Circle())
        } else {
            self.overlay(Circle().strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1))
        }
    }
}
