// ⌘
//  GymNutshell/GymNutshellApp/GymNutshellApp.swift
//
//  Propósito: Ponto de entrada do app; configura o SwiftData e gerencia o fluxo de onboarding.
//
//  Created by Jonathas Motta (@jonathaxs) on 2025-08-16.
// ⌘

import SwiftUI
import GymNutshellCore
import SwiftData
import WidgetKit

@main
struct GymNutshellApp: App {

    // AppDelegate registrado pra fornecer `supportedInterfaceOrientationsFor:` ,
    // sem isso o travamento de orientação escolhido em Ajustes → Orientação não
    // surte efeito. Não tem outra função.
    @UIApplicationDelegateAdaptor(GymNutshellAppDelegate.self) private var appDelegate

    // Observa o ciclo de vida pra reagendar notificações quando o app volta ao foreground.
    @Environment(\.scenePhase) private var scenePhase

    // Controla se o onboarding foi completado.
    // A WelcomeView é exibida até o usuário terminar o fluxo.
    @AppStorage(UserProfile.didCompleteOnboardingKey) private var didCompleteOnboarding: Bool = false

    // Se o container do SwiftData falhou na inicialização (disco cheio, DB corrompido, etc.).
    // Quando true, o app exibe uma tela de erro em vez de travar.
    private let containerInitFailed: Bool
    private let sharedModelContainer: ModelContainer

    init() {
        // Registra o delegate do UNUserNotificationCenter antes de qualquer notificação ser entregue.
        // Garante que o toque na notificação seja roteado pra tela certa mesmo em cold start.
        NotificationManager.shared.configure()

        // Ativa a sessão de WatchConnectivity pra sincronizar estado iPhone ↔ Watch.
        WatchConnectivityManager.shared.activate()

        // 1.1: apaga dados físicos da 1.0 e normaliza o sexo ("other" vira "male").
        UserProfile.migrateLegacyProfile()

        // Migração one-shot: chave antiga "profile.fitnessGoal" → nova "profile.userGoal".
        // Executa quando o usuário atualiza a versão; limpa a chave antiga depois de copiar.
        let defaults = UserDefaults.standard
        if defaults.object(forKey: UserProfile.userGoalKey) == nil,
           let legacy = defaults.string(forKey: "profile.fitnessGoal") {
            defaults.set(legacy, forKey: UserProfile.userGoalKey)
            defaults.removeObject(forKey: "profile.fitnessGoal")
        }

        // Migração one-shot: Fibra deixou de ser opcional. Usuários que removeram
        // no onboarding antigo precisam ter a chave restaurada pra meta aparecer.
        let removedSet = RemovedItemsStore.load()
        if removedSet.contains("tracking.fiber") {
            RemovedItemsStore.restore("tracking.fiber")
        }

        // Escreve o snapshot imediatamente pra o widget não mostrar placeholder no primeiro carregamento.
        WidgetSnapshotStore.save(WidgetSnapshot.buildCurrent())

        let schema = Schema([DailyRecord.self, StreakBonus.self])
        // URL explícita + cloudKitDatabase: .none evita que o iOS 17 tente subir
        // o mirror de CloudKit por causa do entitlement de iCloud Documents (backup).
        let storeURL = URL.applicationSupportDirectory.appending(path: "GymNutshell.store")
        let config = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        do {
            sharedModelContainer = try ModelContainer(for: schema, configurations: [config])
            containerInitFailed = false
        } catch {
            // Cai de volta pra um container em memória pra o app poder mostrar a tela de erro.
            // Os dados não serão salvos nesse estado, mas o app continua rodando.
            sharedModelContainer = try! ModelContainer(
                for: Schema([DailyRecord.self, StreakBonus.self]),
                configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
            )
            containerInitFailed = true
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if containerInitFailed {
                    DataStoreErrorView()
                } else if didCompleteOnboarding {
                    MainView()
                } else {
                    WelcomeView {
                        didCompleteOnboarding = true
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .gymNutshellIntakeDidChange)) { _ in
                sendWatchStats()
                updateWidgetSnapshot()
            }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                NotificationManager.shared.rescheduleAllActive()
                WatchConnectivityManager.shared.sendSnapshot()
                sendWatchStats()
                updateWidgetSnapshot()
            } else if phase == .background {
                WatchConnectivityManager.shared.sendSnapshot()
                sendWatchStats()
                updateWidgetSnapshot()
            }
        }
    }

    private func updateWidgetSnapshot() {
        // Busca os últimos ~35 dias pra alimentar o widget grande de calendário.
        // Fetch limit + sort decrescente mantém o trabalho barato mesmo com histórico longo.
        let ctx = sharedModelContainer.mainContext
        var descriptor = FetchDescriptor<DailyRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        descriptor.fetchLimit = 40
        let records = (try? ctx.fetch(descriptor)) ?? []

        let snapshot = WidgetSnapshot.buildCurrent(recentRecords: records)
        WidgetSnapshotStore.save(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func sendWatchStats() {
        let ctx = sharedModelContainer.mainContext
        let records = (try? ctx.fetch(
            FetchDescriptor<DailyRecord>(sortBy: [SortDescriptor(\.date)])
        )) ?? []
        let bonuses = (try? ctx.fetch(FetchDescriptor<StreakBonus>())) ?? []
        WatchConnectivityManager.shared.updateStatsSummary(
            WatchStatsSummary(records: records, bonuses: bonuses)
        )
    }
}

// MARK: - Tela de erro do banco de dados

// Exibida no raro caso em que o container do SwiftData não pode ser criado.
// Instrui o usuário a forçar fechar e reabrir o app.
private struct DataStoreErrorView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)

            Text(String(localized: "app.error.dataStore.title", bundle: .gymNutshellCore))
                .font(.title2.bold())

            Text(String(localized: "app.error.dataStore.message", bundle: .gymNutshellCore))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}
