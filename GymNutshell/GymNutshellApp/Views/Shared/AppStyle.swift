// ⌘
//  GymNutshell/GymNutshellApp/Views/Shared/AppStyle.swift
//
//  Propósito: Camada de estilo única do app (visual iOS 26/27): medidas, cards sólidos, vidro só nos
//             controles e componentes reutilizáveis (botões -/+, cartão de permissão, escolha de sexo,
//             ícone em quadrado colorido). Nasceu na Welcome e vale pro app inteiro.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-10-09.
// ⌘

import SwiftUI
import GymNutshellCore

// MARK: - Medidas compartilhadas

enum AppStyle {
    /// Raio dos cards das etapas (cantos contínuos, como no sistema).
    static let cardRadius: CGFloat = 22
    /// Espaço horizontal das etapas.
    static let horizontalPadding: CGFloat = 20
}

// MARK: - Rótulo de seção

/// Título pequeno acima de um card agrupado (ex: "Nutrição", "Sexo").
struct AppSectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Card agrupado com divisores

/// Card no estilo lista agrupada: junta as linhas num bloco só, com divisor entre elas.
struct AppGroupedCard<Content: View>: View {

    /// Recuo do divisor, alinhado ao texto (depois do ícone).
    var dividerInset: CGFloat = 52
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            Group(subviews: content) { subviews in
                ForEach(subviews) { subview in
                    if subview.id != subviews.first?.id {
                        Divider().padding(.leading, dividerInset)
                    }
                    subview
                }
            }
        }
        .appCard()
    }
}

// MARK: - Modificadores de estilo

extension View {

    /// Fundo de card das etapas. Selecionado ganha tom e borda da cor de destaque.
    func appCard(isSelected: Bool = false, accentColor: Color = .accentColor) -> some View {
        let shape = RoundedRectangle(cornerRadius: AppStyle.cardRadius, style: .continuous)
        return self
            .background {
                ZStack {
                    shape.fill(Color(.secondarySystemGroupedBackground))
                    if isSelected { shape.fill(accentColor.opacity(0.12)) }
                }
            }
            .overlay {
                shape.strokeBorder(isSelected ? accentColor : .clear, lineWidth: 2)
            }
            .clipShape(shape)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    /// Vidro (Liquid Glass) no iOS 26+; material translúcido nas versões anteriores.
    @ViewBuilder
    func appGlass<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: shape)
        } else {
            self.background(.ultraThinMaterial, in: shape)
        }
    }

    /// Botão principal em cápsula (vidro com cor no iOS 26+).
    @ViewBuilder
    func appProminentButton(_ color: Color, size: ControlSize = .large) -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glassProminent)
                .buttonBorderShape(.capsule)
                .controlSize(size)
                .tint(color)
        } else {
            self.buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(size)
                .tint(color)
        }
    }

    /// Botão secundário em cápsula (vidro neutro no iOS 26+). `circle` deixa redondo (botões só de ícone).
    @ViewBuilder
    func appSecondaryButton(_ color: Color, circle: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glass)
                .buttonBorderShape(circle ? .circle : .capsule)
                .controlSize(.large)
                .tint(color)
        } else {
            self.buttonStyle(.bordered)
                .buttonBorderShape(circle ? .circle : .capsule)
                .controlSize(.large)
                .tint(color)
        }
    }

    /// Botão redondo de vidro (ex: voltar no topo). O tamanho vem do conteúdo; `fallbackPadding`
    /// só vale antes do iOS 26, onde o botão é um círculo sólido sem o respiro do vidro.
    @ViewBuilder
    func appCircleButton(fallbackPadding: CGFloat = 0) -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .tint(.primary)
        } else {
            self.buttonStyle(.plain)
                .padding(fallbackPadding)
                .background(Circle().fill(Color(.tertiarySystemFill)))
        }
    }
}

// MARK: - AppTabHeader

/// Cabeçalho da Hoje: só o título grande (a data). Os botões de navegação ficam na linha de botões (TodayPageButtons).
/// As outras páginas usam a barra de navegação nativa.
/// Com a barra vertical do sistema (iPhone Duo), Ajustes, Registros, Conquistas e a troca lista/grade viram
/// itens da toolbar, nessa ordem, e o sistema os põe na coluna lateral abaixo da barra de status.
struct AppTabHeader: View {

    let title: String

    @Environment(\.usesVerticalBar) private var usesVerticalBar

    var body: some View {
        Text(title)
            .font(.title.weight(.bold))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity, alignment: .center)
            .accessibilityAddTraits(.isHeader)
            .toolbar {
                if usesVerticalBar {
                    // Um grupo só, pra coluna seguir esta ordem de cima pra baixo.
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        ForEach(TodayRailItem.allCases) { item in
                            TodayRailButton(item: item)
                        }
                    }
                }
            }
    }
}

// MARK: - Barra vertical (iPhone Duo)

extension EnvironmentValues {
    /// True quando o sistema põe as barras na coluna vertical ao lado da tela (iPhone Duo dobrado, iOS 27.1+).
    @Entry var usesVerticalBar: Bool = false
}

/// Lê do UIKit se a cena usa a barra vertical e avisa quando muda (dobrar/desdobrar o Duo).
/// Fora do Duo o `verticalBarEdge` é sempre `.unspecified`, então nada muda nos outros aparelhos.
struct VerticalBarReader: UIViewRepresentable {
    @Binding var isActive: Bool

    func makeUIView(context: Context) -> ReaderView {
        let view = ReaderView()
        view.onChange = { isActive = $0 }
        return view
    }

    func updateUIView(_ uiView: ReaderView, context: Context) {
        uiView.onChange = { isActive = $0 }
    }

    final class ReaderView: UIView {
        var onChange: ((Bool) -> Void)?

        override init(frame: CGRect) {
            super.init(frame: frame)
            isUserInteractionEnabled = false
            if #available(iOS 27.1, *) {
                registerForTraitChanges(UITraitCollection.systemTraitsAffectingVerticalBarEdge) { (view: ReaderView, _) in
                    view.report()
                }
            }
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) não usado") }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            report()
        }

        private func report() {
            guard #available(iOS 27.1, *), window != nil else { return }
            let active = traitCollection.verticalBarEdge != .unspecified
            // Fora do ciclo de atualização da view, pra não mexer em @State durante o render.
            DispatchQueue.main.async { [weak self] in self?.onChange?(active) }
        }
    }
}

// MARK: - IconBadge

/// SF Symbol branco num quadrado colorido, como nos Ajustes do sistema.
struct IconBadge: View {

    let systemName: String
    let color: Color
    var size: CGFloat = 30

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.5, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(color.gradient, in: RoundedRectangle(cornerRadius: size * 0.27, style: .continuous))
            .accessibilityHidden(true)
    }
}

// MARK: - GlassIcon

/// Ícone das linhas de Ajustes: símbolo na cor da página dentro de um círculo de vidro,
/// no mesmo espírito dos botões redondos da Hoje (sino e engrenagem).
struct GlassIcon: View {

    let systemName: String
    let color: Color
    var size: CGFloat = 32

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.46, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(Circle().fill(color.opacity(0.14)))
            .appGlass(in: Circle())
            .accessibilityHidden(true)
    }
}

// MARK: - RoundStepButton

/// Botão redondo de vidro com -, + ou lixeira, usado nas metas e nos controles de registro.
struct RoundStepButton: View {

    enum Kind {
        case minus, plus, trash

        var symbolName: String {
            switch self {
            case .minus: return "minus"
            case .plus:  return "plus"
            case .trash: return "trash"
            }
        }
    }

    let kind: Kind
    var size: CGFloat = 44
    var color: Color = .accentColor
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        let icon = Image(systemName: kind.symbolName)
            .font(.system(size: size * 0.4, weight: .bold))
            .foregroundStyle(color)
            .frame(width: size, height: size)
        // No iOS 26+ o estilo .glass soma respiro em volta do botão; aqui o vidro vai direto
        // no círculo, com o tamanho exato pedido.
        return Group {
            if #available(iOS 26.0, *) {
                Button(action: action) { icon }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: Circle())
            } else {
                Button(action: action) { icon }
                    .appCircleButton()
            }
        }
        .tint(color)
        .disabled(!isEnabled)
    }
}

// MARK: - PermissionCard

/// Estado de um pedido de permissão.
enum PermissionCardState { case idle, allowed, requested, denied }

/// Linha de permissão: ícone colorido, título, descrição e botão Permitir (ou o estado).
struct PermissionCard: View {

    let icon: String
    let iconColor: Color
    let title: String
    let desc: String
    let state: PermissionCardState
    var accentColor: Color = .accentColor
    let action: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            IconBadge(systemName: icon, color: iconColor, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(desc)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)

            switch state {
            case .idle:
                Button(action: action) {
                    Text(String(localized: "welcome.ready.allow", bundle: .gymNutshellCore))
                        .font(.subheadline.weight(.semibold))
                }
                .appProminentButton(accentColor, size: .regular)
            case .allowed:
                Label(String(localized: "welcome.ready.allowed", bundle: .gymNutshellCore), systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.green)
            case .requested:
                Label(String(localized: "welcome.ready.requested", bundle: .gymNutshellCore), systemImage: "checkmark.circle")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            case .denied:
                Text(String(localized: "welcome.ready.denied", bundle: .gymNutshellCore))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .appCard()
    }
}

// MARK: - SexPicker

/// Dois blocos selecionáveis (feminino e masculino), na cor padrão de cada sexo.
struct SexPicker: View {

    @Binding var sex: String

    var body: some View {
        HStack(spacing: 12) {
            tile("female", icon: "figure.stand.dress",
                 label: String(localized: "welcome.field.sex.female", bundle: .gymNutshellCore))
            tile("male", icon: "figure.stand",
                 label: String(localized: "welcome.field.sex.male", bundle: .gymNutshellCore))
        }
    }

    private func tile(_ value: String, icon: String, label: String) -> some View {
        let isSelected = sex == value
        // A cor do bloco segue a cor que o app vai usar pra esse sexo.
        let tileColor = AppAccentColor.defaultForSex(value).color
        return VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(isSelected ? tileColor : .secondary)
                .accessibilityHidden(true)
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .appCard(isSelected: isSelected, accentColor: tileColor)
        .contentShape(RoundedRectangle(cornerRadius: AppStyle.cardRadius, style: .continuous))
        .tapButton {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.easeInOut(duration: 0.2)) { sex = value }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(isSelected
                            ? String(localized: "a11y.selected", bundle: .gymNutshellCore)
                            : String(localized: "a11y.not.selected", bundle: .gymNutshellCore))
    }
}
