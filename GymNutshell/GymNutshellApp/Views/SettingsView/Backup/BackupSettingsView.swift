// ⌘
//  GymNutshell/GymNutshellApp/Views/SettingsView/Backup/BackupSettingsView.swift
//
//  Propósito: Permite ao usuário gerenciar backups, tanto iCloud (sync via iCloud Drive)
//             quanto local (exportação/importação manual como arquivos JSON).
//             A seção do iCloud aparece primeiro; a seção local logo abaixo.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-12.
// ⌘

import SwiftUI
import GymNutshellCore
import SwiftData
import UniformTypeIdentifiers

// MARK: - Wrapper FileDocument pro fileExporter

/// Envolve um Data bruto pra poder ser exportado via o modifier fileExporter do SwiftUI.
struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Tela de backup

/// Tela de settings pra gerenciar backups no iCloud e locais.
struct BackupSettingsView: View {

    // MARK: - Environment e dados

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyRecord.date, order: .forward) private var records: [DailyRecord]

    // MARK: - Estado do backup local

    @State private var exportDocument: BackupDocument? = nil
    @State private var exportFilename: String = ""
    @State private var isExporting: Bool = false
    @State private var isImporting: Bool = false

    // Alert de confirmação de importação.
    @State private var isPresentingImportAlert: Bool = false
    @State private var pendingImportURL: URL? = nil

    // MARK: - Estado do iCloud

    @State private var iCloudAvailable: Bool = false
    @State private var iCloudLastBackup: Date? = nil
    @State private var iCloudSaving: Bool = false
    @State private var iCloudRestoring: Bool = false
    @State private var isPresentingICloudRestoreAlert: Bool = false

    // Toggle de backup automático diário, acionado na primeira abertura do app após a meia-noite.
    @AppStorage(AutoBackupService.enabledKey) private var autoBackupEnabled: Bool = false

    // MARK: - Alerts compartilhados

    @State private var showSuccess: Bool = false
    @State private var successMessage: String = ""
    @State private var errorMessage: String? = nil

    // MARK: - Body

    var body: some View {
        List {
            // Seção iCloud, aparece primeiro, acima do local.
            iCloudSection

            // Seção local, exportação/importação manual via arquivos JSON.
            localSection
        }
        .navigationTitle(String(localized: "settings.backup.nav.title", bundle: .gymNutshellCore))
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if iCloudRestoring {
                restoringOverlay
            }
        }
        .task {
            await refreshICloudStatus()
        }

        // File exporter, acionado depois que a exportação local dá certo.
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument ?? BackupDocument(data: Data()),
            contentType: .json,
            defaultFilename: exportFilename
        ) { _ in }

        // File importer, deixa o usuário escolher um arquivo de backup .json.
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json]
        ) { result in
            switch result {
            case .success(let url):
                pendingImportURL = url
                isPresentingImportAlert = true
            case .failure:
                break
            }
        }

        // Alert de confirmação antes de sobrescrever os dados (importação local).
        .alert(
            String(localized: "settings.backup.import.alert.title", bundle: .gymNutshellCore),
            isPresented: $isPresentingImportAlert
        ) {
            Button(String(localized: "settings.backup.import.alert.confirm", bundle: .gymNutshellCore), role: .destructive) {
                if let url = pendingImportURL { performLocalImport(from: url) }
            }
            Button(String(localized: "settings.backup.import.alert.cancel", bundle: .gymNutshellCore), role: .cancel) {}
        } message: {
            Text(String(localized: "settings.backup.import.alert.message", bundle: .gymNutshellCore))
        }

        // Alert de confirmação antes de restaurar do iCloud.
        .alert(
            String(localized: "settings.backup.import.alert.title", bundle: .gymNutshellCore),
            isPresented: $isPresentingICloudRestoreAlert
        ) {
            Button(String(localized: "settings.backup.import.alert.confirm", bundle: .gymNutshellCore), role: .destructive) {
                Task { await performICloudRestore() }
            }
            Button(String(localized: "settings.backup.import.alert.cancel", bundle: .gymNutshellCore), role: .cancel) {}
        } message: {
            Text(String(localized: "settings.backup.import.alert.message", bundle: .gymNutshellCore))
        }

        // Alert de sucesso.
        .alert(
            String(localized: "settings.backup.success.title", bundle: .gymNutshellCore),
            isPresented: $showSuccess
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(successMessage)
        }

        // Alert de erro.
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

    // MARK: - Overlay de restauração iCloud

    // Aparece por cima da tela enquanto o restore está em andamento,
    // pra dar um indicativo claro pro usuário do que está acontecendo.
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

    // MARK: - Seção iCloud

    private var iCloudSection: some View {
        Section {
            if iCloudAvailable {
                // Toggle de backup automático diário.
                Toggle(isOn: $autoBackupEnabled) {
                    Label(
                        String(localized: "settings.backup.icloud.auto.toggle", bundle: .gymNutshellCore),
                        systemImage: "clock.arrow.circlepath"
                    )
                }
                .disabled(iCloudSaving || iCloudRestoring)

                // Botão salvar no iCloud.
                Button {
                    Task { await saveToICloud() }
                } label: {
                    HStack {
                        Label(String(localized: "settings.backup.icloud.save", bundle: .gymNutshellCore), systemImage: "icloud.and.arrow.up")
                        if iCloudSaving {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(iCloudSaving || iCloudRestoring)

                // Botão restaurar do iCloud, sempre visível quando o iCloud está disponível.
                // Em device novo o arquivo pode existir só como placeholder (ainda não baixado),
                // por isso não dependemos de `iCloudLastBackup` pra exibir, performICloudRestore
                // dispara o download sob demanda e reporta erro caso não haja backup.
                Button {
                    isPresentingICloudRestoreAlert = true
                } label: {
                    HStack {
                        Label(String(localized: "settings.backup.icloud.restore", bundle: .gymNutshellCore), systemImage: "icloud.and.arrow.down")
                        if iCloudRestoring {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(iCloudSaving || iCloudRestoring)
            } else {
                // iCloud indisponível, exibe mensagem informativa.
                Label(String(localized: "settings.backup.icloud.unavailable", bundle: .gymNutshellCore), systemImage: "icloud.slash")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("iCloud")
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                if let date = iCloudLastBackup {
                    Text(String(localized: "settings.backup.icloud.lastBackup", bundle: .gymNutshellCore) + " " + date.formatted(date: .abbreviated, time: .shortened))
                } else if iCloudAvailable {
                    Text(String(localized: "settings.backup.icloud.noBackup", bundle: .gymNutshellCore))
                } else {
                    Text(String(localized: "settings.backup.icloud.footer.unavailable", bundle: .gymNutshellCore))
                }
                if iCloudAvailable && autoBackupEnabled {
                    Text(String(localized: "settings.backup.icloud.auto.footer", bundle: .gymNutshellCore))
                }
            }
        }
    }

    // MARK: - Seção local

    private var localSection: some View {
        Section {
            // Botão exportar, monta o JSON e abre o share sheet do sistema.
            Button {
                prepareExport()
            } label: {
                Label(String(localized: "settings.backup.export", bundle: .gymNutshellCore),
                      systemImage: "square.and.arrow.up")
            }

            // Botão importar, abre o document picker pra arquivos .json.
            Button {
                isImporting = true
            } label: {
                Label(String(localized: "settings.backup.import", bundle: .gymNutshellCore),
                      systemImage: "square.and.arrow.down")
            }
        } header: {
            Text(String(localized: "settings.backup.section.data", bundle: .gymNutshellCore))
        } footer: {
            Text(String(localized: "settings.backup.section.footer", bundle: .gymNutshellCore))
        }
    }

    // MARK: - Ações do iCloud

    private func refreshICloudStatus() async {
        // isSignedIn é uma verificação rápida (sem I/O).
        iCloudAvailable = ICloudBackupManager.isSignedIn
        // lastBackupDate resolve a URL do container fora da thread principal.
        iCloudLastBackup = await ICloudBackupManager.lastBackupDate()
    }

    private func saveToICloud() async {
        iCloudSaving = true
        do {
            let data = try BackupManager.export(records: records)
            try await ICloudBackupManager.save(data)
            await refreshICloudStatus()
            iCloudSaving = false
            successMessage = String(localized: "settings.backup.icloud.save.success", bundle: .gymNutshellCore)
            showSuccess = true
        } catch {
            iCloudSaving = false
            errorMessage = error.localizedDescription
        }
    }

    private func performICloudRestore() async {
        iCloudRestoring = true
        do {
            guard let data = try await ICloudBackupManager.load() else {
                iCloudRestoring = false
                errorMessage = String(localized: "settings.backup.icloud.noBackup", bundle: .gymNutshellCore)
                return
            }
            let payload = try BackupManager.decode(data)
            restorePayload(payload)
            await refreshICloudStatus()
            iCloudRestoring = false
            successMessage = String(localized: "settings.backup.success.message", bundle: .gymNutshellCore)
            showSuccess = true
        } catch {
            iCloudRestoring = false
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Exportação local

    private func prepareExport() {
        do {
            let data = try BackupManager.export(records: records)
            exportDocument = BackupDocument(data: data)
            exportFilename = BackupManager.suggestedFilename()
            isExporting = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Importação local

    private func performLocalImport(from url: URL) {
        // Acesso a recurso com escopo de segurança necessário pra arquivos fora do sandbox.
        guard url.startAccessingSecurityScopedResource() else {
            errorMessage = "Could not access the selected file."
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let data = try Data(contentsOf: url)
            let payload = try BackupManager.decode(data)
            restorePayload(payload)
            successMessage = String(localized: "settings.backup.success.message", bundle: .gymNutshellCore)
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Lógica de restauração compartilhada

    /// Restaura um BackupPayload no UserDefaults e no SwiftData.
    /// Usado tanto pela importação local quanto pela restauração do iCloud.
    /// Erros de delete do SwiftData são silenciosamente ignorados, comportamento
    /// preservado da implementação original.
    private func restorePayload(_ payload: BackupPayload) {
        try? BackupManager.applyPayload(payload, into: modelContext)
    }
}
