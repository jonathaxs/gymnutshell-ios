// ⌘
//  GymNutshell/GymNutshellApp/Views/WelcomeView/Components/WelcomeContextPanel.swift
//
//  Propósito: Painel contextual à esquerda no layout wide do onboarding ,
//             emoji + título + subtítulo da etapa atual, botões de ação no rodapé.
//             Owns o estado de restauração de backup via fileImporter.
// ⌘

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import GymNutshellCore

struct WelcomeContextPanel: View {
    let currentStep: WelcomeStep
    let sexColor: Color
    let continueButtonColor: Color
    let continueButtonLabel: String
    let isCurrentStepValid: Bool
    let onAdvance: () -> Void
    let onGoBack: () -> Void
    let onRestoreComplete: () -> Void
    let modelContext: ModelContext

    @State private var isPanelImporting: Bool = false
    @State private var panelRestoreError: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Emoji + título, anima junto com a transição de etapa.
            VStack(spacing: 16) {
                Spacer()
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
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal)

            // Botões de ação, variam conforme a etapa.
            VStack(spacing: 12) {
                if currentStep == .start {
                    Button(action: onAdvance) {
                        Text(String(localized: "welcome.start.new", bundle: .gymNutshellCore))
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .welcomeProminentButton(sexColor)
                    Button { isPanelImporting = true } label: {
                        Text(String(localized: "welcome.start.restore", bundle: .gymNutshellCore))
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .welcomeSecondaryButton(sexColor)
                } else {
                    WelcomeContinueButton(
                        label: continueButtonLabel,
                        color: continueButtonColor,
                        isEnabled: isCurrentStepValid,
                        action: onAdvance
                    )

                    Button(action: onGoBack) {
                        Text(String(localized: "welcome.button.back", bundle: .gymNutshellCore))
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .welcomeSecondaryButton(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .fileImporter(isPresented: $isPanelImporting, allowedContentTypes: [.json]) { result in
            if case .success(let url) = result { performRestore(from: url) }
        }
        .alert(
            String(localized: "settings.backup.error.title", bundle: .gymNutshellCore),
            isPresented: .init(get: { panelRestoreError != nil }, set: { if !$0 { panelRestoreError = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            if let msg = panelRestoreError { Text(msg) }
        }
    }

    // Restaura backup a partir de um arquivo selecionado no painel wide.
    private func performRestore(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            panelRestoreError = "Could not access the selected file."
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        do {
            let data = try Data(contentsOf: url)
            let payload = try BackupManager.decode(data)
            try BackupManager.applyPayload(payload, into: modelContext)
            UserDefaults.standard.set(true, forKey: UserProfile.didCompleteOnboardingKey)
            onRestoreComplete()
        } catch {
            panelRestoreError = error.localizedDescription
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
        .welcomeProminentButton(color)
        .disabled(!isEnabled)
    }
}

// MARK: - Progress bar (capsules), usada no topo do stepContent

struct WelcomeProgressBar: View {
    let currentStep: WelcomeStep
    let activeColor: Color

    var body: some View {
        let total = WelcomeStep.allCases.count
        let current = currentStep.rawValue + 1

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
