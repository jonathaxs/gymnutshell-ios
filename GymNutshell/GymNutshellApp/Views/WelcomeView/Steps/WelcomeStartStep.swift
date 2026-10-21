// ⌘
//  GymNutshell/GymNutshellApp/Views/WelcomeView/Steps/WelcomeStartStep.swift
//
//  Propósito: Primeira etapa do onboarding, permite ao usuário escolher entre iniciar um novo perfil
//             ou restaurar a partir de um arquivo de backup exportado anteriormente.
//             Layout: cabeçalho e, logo abaixo, o espaço dos botões Começar / Restaurar backup
//             (os botões são os do rodapé da WelcomeView, que sobem até aqui).
//             "Restaurar backup" abre um balão (WelcomeRestorePopover, preso ao botão na WelcomeView) com as
//             opções iCloud e arquivo JSON; a escolha chega aqui por `restoreRequest`.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-20.
// ⌘

import SwiftUI
import GymNutshellCore
import SwiftData
import UniformTypeIdentifiers

/// Primeira etapa do onboarding: o usuário escolhe entre começar do zero ou restaurar um backup.
/// No modo narrow: cabeçalho e botões centralizados na tela.
struct WelcomeStartStep: View {

    let onRestore: () -> Void
    /// Opção escolhida no balão de Restaurar backup; volta pra nil depois de tratada.
    @Binding var restoreRequest: WelcomeRestoreSource?
    var accentColor: Color = .accentColor
    var isWide: Bool = false

    @Environment(\.modelContext) private var modelContext

    @State private var isImporting = false
    @State private var iCloudRestoring = false
    @State private var errorMessage: String? = nil

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 28) {
                    // O esquilo que corre atrás da noz (nutshell), como o da Era do Gelo.
                    // No layout largo aparece também, pra o lado direito não ficar vazio.
                    WelcomeStepHeader(
                        emoji: "🐿️",
                        title: String(localized: "welcome.step.start.title", bundle: .gymNutshellCore),
                        accentColor: accentColor
                    )

                    if !isWide {
                        WelcomeButtonsSlot(step: .start)
                    }
                }
                .padding(.horizontal, AppStyle.horizontalPadding)
                .padding(.vertical)
                .frame(maxWidth: .infinity, minHeight: geo.size.height, alignment: .center)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .onChange(of: restoreRequest) { _, source in
            guard let source else { return }
            restoreRequest = nil
            switch source {
            case .iCloud:
                iCloudRestoring = true
                Task { await performICloudRestore() }
            case .file:
                // Espera o balão terminar de fechar antes de abrir o seletor de arquivos.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { isImporting = true }
            }
        }
        .overlay {
            if iCloudRestoring {
                restoringOverlay
            }
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) { result in
            if case .success(let url) = result { performLocalRestore(from: url) }
        }
        .alert(
            String(localized: "settings.backup.error.title", bundle: .gymNutshellCore),
            isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            if let msg = errorMessage { Text(msg) }
        }
    }

    // MARK: - Overlay "Restaurando backup do iCloud"

    // Cobre a tela enquanto o iCloud restore está em andamento.
    // O onRestore() só é chamado ao fim do performICloudRestore, por isso
    // o overlay precisa ficar visível depois que o balão fecha.
    private var restoringOverlay: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 14) {
                ProgressView()
                    .scaleEffect(1.3)
                Text(String(localized: "settings.backup.icloud.restoring", bundle: .gymNutshellCore))
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .transition(.opacity)
    }

    // MARK: - Restauração via iCloud

    private func performICloudRestore() async {
        iCloudRestoring = true
        do {
            guard let data = try await ICloudBackupManager.load() else {
                errorMessage = String(localized: "settings.backup.icloud.noBackup", bundle: .gymNutshellCore)
                iCloudRestoring = false
                return
            }
            let payload = try BackupManager.decode(data)
            try BackupManager.applyPayload(payload, into: modelContext)
            UserDefaults.standard.set(true, forKey: UserProfile.didCompleteOnboardingKey)
            iCloudRestoring = false
            onRestore()
        } catch {
            errorMessage = error.localizedDescription
            iCloudRestoring = false
        }
    }

    // MARK: - Restauração via arquivo local

    private func performLocalRestore(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            errorMessage = "Could not access the selected file."
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        do {
            let data = try Data(contentsOf: url)
            let payload = try BackupManager.decode(data)
            try BackupManager.applyPayload(payload, into: modelContext)
            UserDefaults.standard.set(true, forKey: UserProfile.didCompleteOnboardingKey)
            onRestore()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Balão de Restaurar backup

/// De onde restaurar o backup, escolhido no balão.
enum WelcomeRestoreSource {
    case iCloud, file
}

/// Balão que abre abaixo do botão Restaurar backup, no mesmo estilo do balão de Detalhes dos emojis.
struct WelcomeRestorePopover: View {

    var accentColor: Color
    let onPick: (WelcomeRestoreSource) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text(String(localized: "welcome.start.restore", bundle: .gymNutshellCore))
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
                .frame(maxWidth: .infinity)
                .frame(height: 48)

            VStack(spacing: 0) {
                row(String(localized: "settings.backup.icloud.restore", bundle: .gymNutshellCore),
                    systemImage: "icloud.and.arrow.down", source: .iCloud)
                    .disabled(!ICloudBackupManager.isSignedIn)
                    .opacity(ICloudBackupManager.isSignedIn ? 1 : 0.4)
                Divider().padding(.leading, 52)
                row(String(localized: "welcome.restore.importJSON", bundle: .gymNutshellCore),
                    systemImage: "doc.badge.arrow.up", source: .file)
            }
            .background(Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(width: 300)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color(.systemGroupedBackground))
    }

    private func row(_ title: String, systemImage: String, source: WelcomeRestoreSource) -> some View {
        Button {
            onPick(source)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(accentColor)
                    .frame(width: 28)
                Text(title)
                    .font(.body)
                    .foregroundStyle(Color.primary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
