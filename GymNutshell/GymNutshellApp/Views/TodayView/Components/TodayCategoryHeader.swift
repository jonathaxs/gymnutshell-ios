// ⌘
//  GymNutshell/GymNutshellApp/Views/TodayView/Components/TodayCategoryHeader.swift
//
//  Propósito: Cabeçalho colapsável de categoria em Hoje, no estilo de seção do iOS 26/27:
//             ícone da categoria, nome, contagem de metas concluídas e chevron que gira.
//             Compartilhado entre categorias fixas, criadas pelo usuário e "Outras".
// ⌘

import SwiftUI
import GymNutshellCore

extension EnvironmentValues {
    /// Namespace da troca lista ↔ grade na Hoje. nil = sem transformação.
    @Entry var todayMorphNamespace: Namespace.ID? = nil
}

extension View {
    /// Liga esta view à peça equivalente do outro modo (lista ↔ grade), pra ela se transformar na troca.
    @ViewBuilder
    /// Textos usam só `.position` pra não herdar a largura do outro modo (cortaria o nome no meio da animação).
    func todayMorph(_ id: String?, in namespace: Namespace.ID?,
                    properties: MatchedGeometryProperties = .frame) -> some View {
        if let id, let namespace {
            self.matchedGeometryEffect(id: id, in: namespace, properties: properties)
        } else {
            self
        }
    }
}

struct TodayCategoryHeader: View {
    let title: String
    let symbolName: String
    let completedCount: Int
    let totalCount: Int
    let collapsed: Bool
    let accentColor: Color
    let a11yLabel: String
    let a11yHint: String
    let onToggle: () -> Void
    /// Id da categoria pra transformação lista ↔ grade (nil = sem transformação).
    var morphId: String? = nil

    @Environment(\.todayMorphNamespace) private var morphNamespace

    private var isDone: Bool { totalCount > 0 && completedCount == totalCount }

    var body: some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.easeInOut(duration: 0.25)) {
                onToggle()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: symbolName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(accentColor)
                    .frame(width: 22)
                    .todayMorph(morphId.map { "icon-\($0)" }, in: morphNamespace)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .todayMorph(morphId.map { "title-\($0)" }, in: morphNamespace, properties: .position)
                Spacer(minLength: 8)
                // Contagem fica verde quando todas as metas da categoria foram cumpridas.
                Text("\(completedCount)/\(totalCount)")
                    .font(.subheadline.weight(.medium).monospacedDigit())
                    .foregroundStyle(isDone ? Color.green : Color.secondary)
                    .contentTransition(.numericText())
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(collapsed ? -90 : 0))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.25), value: completedCount)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(a11yLabel)
        .accessibilityValue(String(format: String(localized: "today.category.a11y.value",
                                                  bundle: .gymNutshellCore),
                                   completedCount, totalCount))
        .accessibilityHint(a11yHint)
    }
}
