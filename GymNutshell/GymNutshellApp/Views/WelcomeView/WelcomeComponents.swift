// ⌘
//  GymNutshell/GymNutshellApp/Views/WelcomeView/WelcomeComponents.swift
//
//  Propósito: Componentes de UI reutilizáveis compartilhados entre as etapas da WelcomeView.
//             Visual estilo iOS 26+ (Liquid Glass) com fallback pra iOS 18.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-10.
// ⌘

import SwiftUI

// MARK: - WelcomeStepHeader

/// Cabeçalho centralizado de cada etapa: emoji num círculo de vidro, título grande e subtítulo.
struct WelcomeStepHeader: View {

    let emoji: String
    let title: String
    var subtitle: String = ""
    /// Aviso pequeno logo abaixo do subtítulo (ex: "pode mudar depois em Ajustes").
    var note: String = ""
    var accentColor: Color = .accentColor

    var body: some View {
        VStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 44))
                .frame(width: 88, height: 88)
                .background(Circle().fill(accentColor.opacity(0.15)))
                .appGlass(in: Circle())
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

            if !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 4)
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
                .appCard()
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
