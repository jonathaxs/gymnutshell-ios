// ⌘
//  GymNutshell/GymNutshellApp/Views/WelcomeView/Steps/WelcomeStartStep.swift
//
//  Propósito: Primeira etapa do onboarding, permite ao usuário escolher entre iniciar um novo perfil
//             ou restaurar a partir de um arquivo de backup exportado anteriormente.
//             Layout: cabeçalho + destaques com ícone no topo; subtítulo + botões fixados no rodapé.
//             "Restaurar backup" abre um sheet com as opções de restauração via iCloud e arquivo local.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-20.
// ⌘

import SwiftUI
import GymNutshellCore
import SwiftData
import UniformTypeIdentifiers

/// Primeira etapa do onboarding: o usuário escolhe entre começar do zero ou restaurar um backup.
/// No modo narrow: intro em ScrollView no topo, subtitle + botões fixos na base.
struct WelcomeStartStep: View {

    let onRestore: () -> Void
    let onNewProfile: () -> Void
    var accentColor: Color = .accentColor
    var isWide: Bool = false

    @Environment(\.modelContext) private var modelContext

    @State private var showRestoreSheet = false
    @State private var isImporting = false
    @State private var iCloudRestoring = false
    @State private var errorMessage: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 28) {
                        if !isWide {
                            WelcomeStepHeader(
                                emoji: "👋",
                                title: String(localized: "welcome.step.start.title", bundle: .gymNutshellCore),
                                accentColor: accentColor
                            )
                        }

                        // Destaques do app em linhas com ícone, no estilo das telas de boas-vindas do sistema.
                        VStack(alignment: .leading, spacing: 22) {
                            featureRow(icon: "figure.strengthtraining.traditional",
                                       text: String(localized: "welcome.start.feature.companion", bundle: .gymNutshellCore))
                            featureRow(icon: "checklist",
                                       text: String(localized: "welcome.start.feature.track", bundle: .gymNutshellCore))
                            featureRow(icon: "trophy.fill",
                                       text: String(localized: "welcome.start.feature.progress", bundle: .gymNutshellCore))
                        }
                        .padding(.horizontal, 8)
                    }
                    .padding(.horizontal, WelcomeStyle.horizontalPadding)
                    .padding(.vertical)
                    .frame(maxWidth: .infinity, minHeight: geo.size.height, alignment: .center)
                }
                .scrollBounceBehavior(.basedOnSize)
            }

            if !isWide {
                VStack(spacing: 14) {
                    Text(String(localized: "welcome.step.start.subtitle", bundle: .gymNutshellCore))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)

                    VStack(spacing: 10) {
                        Button(action: onNewProfile) {
                            Text(String(localized: "welcome.start.new", bundle: .gymNutshellCore))
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                        }
                        .welcomeProminentButton(accentColor)

                        Button { showRestoreSheet = true } label: {
                            Text(String(localized: "welcome.start.restore", bundle: .gymNutshellCore))
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                        }
                        .welcomeSecondaryButton(accentColor)
                    }
                }
                .padding(.horizontal, WelcomeStyle.horizontalPadding)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
        }
        .sheet(isPresented: $showRestoreSheet) {
            restoreSheet
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

    // MARK: - Linha de destaque

    private func featureRow(icon: String, text: String) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(accentColor)
                .frame(width: 40)
                .accessibilityHidden(true)
            Text(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    // MARK: - Sheet de restauração

    private var restoreSheet: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        iCloudRestoring = true
                        showRestoreSheet = false
                        Task { await performICloudRestore() }
                    } label: {
                        HStack {
                            Label(String(localized: "settings.backup.icloud.restore", bundle: .gymNutshellCore),
                                  systemImage: "icloud.and.arrow.down")
                            if iCloudRestoring {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(!ICloudBackupManager.isSignedIn || iCloudRestoring)

                    Button {
                        showRestoreSheet = false
                        isImporting = true
                    } label: {
                        Label(String(localized: "settings.backup.import", bundle: .gymNutshellCore),
                              systemImage: "doc.badge.arrow.up")
                    }
                }
            }
            .navigationTitle(String(localized: "welcome.start.restore", bundle: .gymNutshellCore))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "welcome.button.back", bundle: .gymNutshellCore)) {
                        showRestoreSheet = false
                    }
                }
            }
        }
    }

    // MARK: - Overlay "Restaurando backup do iCloud"

    // Cobre a tela enquanto o iCloud restore está em andamento.
    // O onRestore() só é chamado ao fim do performICloudRestore, por isso
    // o overlay precisa ficar visível depois que a sheet fecha.
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
