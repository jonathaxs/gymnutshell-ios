// ⌘
//  GymNutshell/GymNutshellApp/Views/WelcomeView/WelcomeComponents.swift
//
//  Propósito: Componentes de UI reutilizáveis compartilhados entre as etapas da WelcomeView.
//             Visual estilo iOS 26+ (Liquid Glass) com fallback pra iOS 18.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-10.
// ⌘

import SwiftUI

// MARK: - Medidas compartilhadas

enum WelcomeStyle {
    /// Raio dos cards das etapas (cantos contínuos, como no sistema).
    static let cardRadius: CGFloat = 22
    /// Espaço horizontal das etapas.
    static let horizontalPadding: CGFloat = 20
}

// MARK: - WelcomeStepHeader

/// Cabeçalho centralizado de cada etapa: emoji num círculo de vidro, título grande e subtítulo.
struct WelcomeStepHeader: View {

    let emoji: String
    let title: String
    var subtitle: String = ""
    var accentColor: Color = .accentColor

    var body: some View {
        VStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 44))
                .frame(width: 88, height: 88)
                .background(Circle().fill(accentColor.opacity(0.15)))
                .welcomeGlass(in: Circle())
                // Decorativo, o título logo abaixo já comunica a etapa.
                .accessibilityHidden(true)
                .padding(.bottom, 4)

            Text(title)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}

// MARK: - Rótulo de seção

/// Título pequeno acima de um card agrupado (ex: "Nutrição", "Sexo").
struct WelcomeSectionLabel: View {
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
struct WelcomeGroupedCard<Content: View>: View {

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
        .welcomeCard()
    }
}

// MARK: - Modificadores de estilo

extension View {

    /// Fundo de card das etapas. Selecionado ganha tom e borda da cor de destaque.
    func welcomeCard(isSelected: Bool = false, accentColor: Color = .accentColor) -> some View {
        let shape = RoundedRectangle(cornerRadius: WelcomeStyle.cardRadius, style: .continuous)
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
    func welcomeGlass<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: shape)
        } else {
            self.background(.ultraThinMaterial, in: shape)
        }
    }

    /// Botão principal em cápsula (vidro com cor no iOS 26+).
    @ViewBuilder
    func welcomeProminentButton(_ color: Color, size: ControlSize = .large) -> some View {
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

    /// Botão secundário em cápsula (vidro neutro no iOS 26+).
    @ViewBuilder
    func welcomeSecondaryButton(_ color: Color) -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glass)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .tint(color)
        } else {
            self.buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .tint(color)
        }
    }

    /// Botão redondo de vidro (ex: voltar no topo).
    @ViewBuilder
    func welcomeCircleButton() -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .tint(.primary)
        } else {
            self.buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .tint(.primary)
        }
    }
}

// MARK: - WelcomeField

/// Campo de texto com label e estilo consistente usado nas etapas de formulário do onboarding.
/// Aceita tipo de teclado, autocapitalização e binding externo de foco opcionais.
/// O binding de foco externo (Binding<Bool>) permite que o chamador controle
/// programaticamente o foco sem acesso direto ao @FocusState interno.
struct WelcomeField: View {

    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .words
    /// Binding externo para controle de foco, mantido em sincronia com o @FocusState interno.
    var externalFocus: Binding<Bool>? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()
                .focused($isFocused)
                .padding()
                .welcomeCard()
                // O Text("label") acima fica visível, mas é melhor o VoiceOver
                // anunciar o nome do campo junto do conteúdo focado, sem isso
                // só o placeholder é lido.
                .accessibilityLabel(label)
        }
        // Sincroniza: foco do TextField → binding externo.
        .onChange(of: isFocused) { _, newValue in
            externalFocus?.wrappedValue = newValue
        }
        // Sincroniza: binding externo → foco do TextField (Next/Done programático).
        .onChange(of: externalFocus?.wrappedValue ?? false) { _, newValue in
            guard externalFocus != nil, isFocused != newValue else { return }
            isFocused = newValue
        }
    }
}
