// ⌘
//  GymNutshell/GymNutshellApp/Views/MainView.swift
//
//  Propósito: Hospeda o NavigationStack raiz (Hoje de raiz) e roteia o usuário pras páginas do app
//             pelo AppRouter: Histórico e Conquistas em sheet, Ajustes como página. Inclui os
//             deep-links de widgets e notificações.
//
//  Created by Jonathas Motta (@jonathaxs) on 2025-11-15.
// ⌘

import SwiftUI
import GymNutshellCore
import SwiftData

// MARK: - Tela principal
// Raiz do app: um NavigationStack com a Hoje de raiz. Histórico e Conquistas abrem em sheet e os Ajustes
// como página, pelo AppRouter (botões da Hoje, widgets e notificações).
struct MainView: View {

    // Cor de destaque, aplicada no stack raiz pra colorir botões e links de todas as páginas.
    @AppStorage(AppAccentColor.storageKey) private var storedColorRaw: String = AppAccentColor.blue.rawValue
    private var accentColor: Color { (AppAccentColor(rawValue: storedColorRaw) ?? .blue).color }

    // Contexto SwiftData usado pra rodar migrações one-shot no primeiro lançamento.
    @Environment(\.modelContext) private var modelContext

    // Fase do app, dispara o backup automático quando o app volta pro foreground.
    @Environment(\.scenePhase) private var scenePhase

    @State private var router = AppRouter()
    @State private var usesVerticalBar = false

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            TodayView()
                // A Hoje desenha o próprio cabeçalho; com a barra vertical (Duo dobrado) a barra fica
                // visível pra que o sino e a engrenagem apareçam na coluna lateral.
                .toolbar(usesVerticalBar ? .automatic : .hidden, for: .navigationBar)
                .environment(\.usesVerticalBar, usesVerticalBar)
                .navigationDestination(for: AppRoute.self) { route in
                    destination(for: route)
                }
        }
        .background(VerticalBarReader(isActive: $usesVerticalBar))
        // Histórico / Conquistas: cada sheet tem seu próprio stack (Histórico → dia nas Conquistas).
        .sheet(item: $router.sheet) { sheet in
            NavigationStack(path: $router.sheetPath) {
                sheetRoot(sheet)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(String(localized: "common.close", bundle: .gymNutshellCore)) {
                                router.sheet = nil
                            }
                        }
                    }
                    .navigationDestination(for: AppRoute.self) { route in
                        destination(for: route)
                    }
            }
            .environment(router)
            .tint(accentColor)
        }
        .environment(router)
        .tint(accentColor)
        .task {
            await AutoBackupService.performIfNeeded(modelContext: modelContext)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await AutoBackupService.performIfNeeded(modelContext: modelContext) }
            }
        }
        // Deep-links a partir dos widgets (esquema `gymnutshell://`).
        // Mantém a regra de roteamento centralizada aqui em vez de espalhar
        // pelos widget extensions, que só conhecem o URL.
        .onOpenURL { url in
            guard url.scheme == "gymnutshell" else { return }
            switch url.host {
            case "today":        router.reset()
            case "achievements": router.reset(sheet: .achievements)
            default: break
            }
        }
        // Deep-link a partir de notificações: troca o caminho do stack.
        .onReceive(NotificationCenter.default.publisher(for: .gaNotificationRoute)) { note in
            guard
                let raw = note.userInfo?["route"] as? String,
                let route = NotificationRoute(rawValue: raw)
            else { return }
            switch route {
            case .today:
                router.reset()
            case .achievementsToday:
                // Pré-seta o filtro de dia antes de abrir a página, a AchievementsView lê esses
                // valores no onAppear e também escuta o sub-evento abaixo (se já estiver aberta).
                // Se a notificação carrega a data da conquista, usa ela (senão cai pra hoje).
                let achievementTs = note.userInfo?["achievementDate"] as? Double
                    ?? Date().timeIntervalSince1970
                UserDefaults.standard.set("day", forKey: UserProfile.achievementsFilterModeKey)
                UserDefaults.standard.set(achievementTs, forKey: UserProfile.achievementsSelectedDateKey)
                router.reset(sheet: .achievements)
                NotificationCenter.default.post(
                    name: .gaAchievementsShowToday,
                    object: nil,
                    userInfo: ["achievementDate": achievementTs]
                )
            case .backup:
                router.reset(to: [.settings, .settingsBackup])
            case .settingsGoals:
                router.reset(to: [.settings, .settingsGoals])
            case .settingsControls:
                router.reset(to: [.settings, .settingsControls])
            }
        }
    }

    // MARK: - Destinos

    @ViewBuilder
    private func sheetRoot(_ sheet: AppSheet) -> some View {
        switch sheet {
        case .statistics:   ProgressOverView()
        case .achievements: AchievementsView()
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .statistics:       ProgressOverView()
        case .achievements:     AchievementsView()
        case .settings:         SettingsView()
        case .settingsBackup:   BackupSettingsView()
        case .settingsGoals:    TrackingGoalsSettingsView()
        case .settingsControls: ControlStyleSettingsView()
        case .userGoal:         UserGoalChangeView()
        }
    }
}

#Preview {
    MainView()
        .modelContainer(for: DailyRecord.self, inMemory: true)
}
