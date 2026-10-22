// ⌘
//  GymNutshell/GymNutshellApp/Views/WelcomeView/Components/WelcomeContextPanel.swift
//
//  Propósito: Painel contextual à esquerda no layout wide do onboarding ,
//             emoji + título + subtítulo da etapa atual, botões de ação no rodapé.
//             No Início só os botões, centralizados; ao avançar eles descem pro rodapé e o título entra.
// ⌘

import SwiftUI
import GymNutshellCore

struct WelcomeContextPanel: View {
    let currentStep: WelcomeStep
    let sexColor: Color
    let continueButtonColor: Color
    let continueButtonLabel: String
    let isCurrentStepValid: Bool
    let onAdvance: () -> Void
    let onGoBack: () -> Void
    /// Opção escolhida no balão de Restaurar backup; quem restaura é a WelcomeStartStep (à direita).
    @Binding var restoreRequest: WelcomeRestoreSource?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showRestoreOptions = false

    private var isStart: Bool { currentStep == .start }

    var body: some View {
        VStack(spacing: 0) {
            // Emoji + título da etapa. No Início fica vazio: o "Olá" e o esquilo já estão no conteúdo à direita.
            ZStack {
                if !isStart {
                    header
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal)

            buttons
                .frame(maxWidth: isStart ? 260 : .infinity)
                .padding(.horizontal)
                .padding(.bottom, isStart ? 0 : 32)

            // No Início um espaço igual ao de cima centraliza os botões; ao avançar ele some e os botões descem
            // pro rodapé.
            if isStart {
                Spacer(minLength: 0)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.55, dampingFraction: 0.85),
                   value: isStart)
    }

    private var header: some View {
        VStack(spacing: 16) {
            Text(currentStep.panelEmoji)
                .font(.system(size: 64))
                .animation(.easeInOut(duration: 0.3), value: currentStep)
                // Emoji decorativo, título logo abaixo já comunica a etapa.
                .accessibilityHidden(true)
            Text(currentStep.panelTitle)
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .animation(.easeInOut(duration: 0.3), value: currentStep)
            if let subtitle = currentStep.panelSubtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }

    /// Um só par de botões pra todas as etapas (como no rodapé do iPhone): Começar / Restaurar backup no Início,
    /// Continuar / Voltar nas demais.
    private var buttons: some View {
        VStack(spacing: 12) {
            WelcomeContinueButton(
                label: continueButtonLabel,
                color: continueButtonColor,
                isEnabled: isCurrentStepValid,
                action: onAdvance
            )

            Button {
                if isStart { showRestoreOptions = true } else { onGoBack() }
            } label: {
                Text(isStart
                     ? String(localized: "welcome.start.restore", bundle: .gymNutshellCore)
                     : String(localized: "welcome.button.back", bundle: .gymNutshellCore))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .appSecondaryButton(isStart ? sexColor : .secondary)
            // Restaurar backup abre um balão logo abaixo, como no iPhone.
            .downwardPopover(isPresented: $showRestoreOptions) {
                WelcomeRestorePopover(accentColor: sexColor) { source in
                    showRestoreOptions = false
                    restoreRequest = source
                }
            }
        }
    }
}

// MARK: - Botão Continuar (compartilhado pelo painel e pelo rodapé narrow)

struct WelcomeContinueButton: View {
    let label: String
    let color: Color
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        }
        .appProminentButton(color)
        .disabled(!isEnabled)
    }
}

// MARK: - Progress bar (capsules), usada no topo do stepContent

struct WelcomeProgressBar: View {
    let currentStep: WelcomeStep
    let activeColor: Color
    var steps: [WelcomeStep] = WelcomeStep.visible(includeUnits: false)

    var body: some View {
        let total = steps.count
        let current = (steps.firstIndex(of: currentStep) ?? 0) + 1

        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index < current ? activeColor : Color.secondary.opacity(0.25))
                    // A etapa atual fica um pouco mais longa, como nos indicadores do sistema.
                    .frame(maxWidth: index == current - 1 ? .infinity : nil)
                    .frame(width: index == current - 1 ? nil : 22, height: 6)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
            }
        }
        .frame(maxWidth: .infinity)
        // Capsules são puramente visuais, colapsa tudo num único elemento
        // de a11y que anuncia "Passo X de Y".
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(format: String(localized: "a11y.welcome.progress.format",
                                                 bundle: .gymNutshellCore), current, total))
    }
}
