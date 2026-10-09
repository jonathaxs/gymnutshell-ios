// ⌘
//  GymNutshell/GymNutshellApp/Views/MainView.swift
//
//  Propósito: Hospeda o TabView principal e roteia o usuário pras telas principais do app.
//             A seleção da aba é guardada em @AppStorage pra que outras views possam
//             navegar pra AchievementsView programaticamente.
//
//  Created by Jonathas Motta (@jonathaxs) on 2025-11-15.
// ⌘

import SwiftUI
import GymNutshellCore
import SwiftData

// MARK: - Índices das abas
// Constantes centralizadas pra outras views navegarem sem números mágicos.
extension MainView {
    enum Tab {
        static let today        = 0
        static let profile      = 1
        static let achievements = 2
        static let settings     = 3
    }
}

// MARK: - Tela principal
// Organiza as abas principais do app: Today, Statistics (profile), Achievements e Settings.
struct MainView: View {

    // Seleção de aba persistida, permite navegação entre abas via @AppStorage.
    @AppStorage(UserProfile.selectedTabKey) private var selectedTab: Int = 0

    // Cor de destaque, usada no tint da TabView pra colorir a aba selecionada.
    @AppStorage(AppAccentColor.storageKey) private var storedColorRaw: String = AppAccentColor.blue.rawValue
    private var accentColor: Color { (AppAccentColor(rawValue: storedColorRaw) ?? .blue).color }

    // Contexto SwiftData usado pra rodar migrações one-shot no primeiro lançamento.
    @Environment(\.modelContext) private var modelContext

    // Fase do app, dispara o backup automático quando o app volta pro foreground.
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView(selection: $selectedTab) {

            TodayView()
                .tabItem {
                    Image(systemName: "checkmark")
                }
                .tag(Tab.today)

            ProgressOverView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                }
                .tag(Tab.profile)

            AchievementsView()
                .tabItem {
                    Image(systemName: "trophy.fill")
                }
                .tag(Tab.achievements)

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(accentColor)
        .task {
            StreakBonusMigration.runIfNeeded(in: modelContext)
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
            case "today":        selectedTab = Tab.today
            case "achievements": selectedTab = Tab.achievements
            default: break
            }
        }
        // Deep-link a partir de notificações: troca a aba e republica sub-eventos pras filhas
        // (AchievementsView e SettingsView) ajustarem seu estado.
        .onReceive(NotificationCenter.default.publisher(for: .gaNotificationRoute)) { note in
            guard
                let raw = note.userInfo?["route"] as? String,
                let route = NotificationRoute(rawValue: raw)
            else { return }
            switch route {
            case .today:
                selectedTab = Tab.today
            case .achievementsToday:
                // Pré-seta o filtro de dia em hoje antes de abrir a aba, a AchievementsView
                // lê esses valores no onAppear e também escuta o sub-evento abaixo.
                // Se a notificação carrega a data da conquista, usa ela (senão cai pra hoje).
                let achievementTs = note.userInfo?["achievementDate"] as? Double
                    ?? Date().timeIntervalSince1970
                UserDefaults.standard.set("day", forKey: UserProfile.achievementsFilterModeKey)
                UserDefaults.standard.set(achievementTs, forKey: UserProfile.achievementsSelectedDateKey)
                selectedTab = Tab.achievements
                NotificationCenter.default.post(
                    name: .gaAchievementsShowToday,
                    object: nil,
                    userInfo: ["achievementDate": achievementTs]
                )
            case .backup:
                // Grava flag persistente, SettingsView pode ainda não estar montada
                // (TabView monta lazy). Ela lê a flag no .onAppear e empurra BackupSettingsView.
                UserDefaults.standard.set("backup", forKey: "pendingSettingsRoute")
                selectedTab = Tab.settings
                NotificationCenter.default.post(name: .gaSettingsShowBackup, object: nil)
            }
        }
    }
}

#Preview {
    MainView()
        .modelContainer(for: DailyRecord.self, inMemory: true)
}
