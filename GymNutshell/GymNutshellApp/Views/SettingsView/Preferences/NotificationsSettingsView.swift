// ⌘
//  GymNutshell/GymNutshellApp/Views/SettingsView/Preferences/NotificationsSettingsView.swift
//
//  Propósito: Página de Ajustes pra configurar todas as notificações do app.
//             Pede permissão do iOS, ativa/desativa por tipo, e abre uma sheet pra
//             editar o intervalo em minutos (pros kinds editáveis).
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-04-23.
// ⌘

import SwiftUI
import UserNotifications
import GymNutshellCore

// MARK: - NotificationsSettingsView

/// Tela principal de preferências de notificação.
/// Segue o padrão visual de `HealthSettingsView`, List + Section + navigationTitle inline.
struct NotificationsSettingsView: View {

    @Environment(\.openURL) private var openURL

    @State private var authStatus: UNAuthorizationStatus = .notDetermined
    @State private var showDeniedAlert = false

    @AppStorage(AppAccentColor.storageKey) private var storedColorRaw: String = AppAccentColor.blue.rawValue
    private var accentColor: Color { (AppAccentColor(rawValue: storedColorRaw) ?? .blue).color }

    private var isAuthorized: Bool {
        authStatus == .authorized || authStatus == .provisional
    }

    var body: some View {
        List {
            // MARK: Autorização
            if !isAuthorized {
                Section {
                    // Negado: o botão Permitir cai no alerta que leva aos Ajustes do iOS.
                    PermissionCard(
                        icon: "bell.badge.fill",
                        iconColor: .red,
                        title: String(localized: "welcome.ready.notifications.title", bundle: .gymNutshellCore),
                        desc: String(localized: "welcome.ready.notifications.desc", bundle: .gymNutshellCore),
                        state: .idle,
                        accentColor: accentColor,
                        action: requestAuthorization
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                } footer: {
                    Text(String(localized: "settings.notifications.authorize.footer", bundle: .gymNutshellCore))
                }
            }

            // MARK: Metas, subpágina dedicada com seções recolhíveis por categoria.
            Section {
                NavigationLink {
                    GoalsNotificationsSettingsView()
                } label: {
                    Label(String(localized: "settings.notifications.section.goals", bundle: .gymNutshellCore),
                          systemImage: "target")
                }
            }
            .disabled(!isAuthorized)

            // MARK: Sistema
            Section {
                NotificationRow(kind: .progress)
                NotificationRow(kind: .achievement)
                NotificationRow(kind: .streakBonus)
                NotificationRow(kind: .appleHealth)
                NotificationRow(kind: .backup)
            } header: {
                Text(String(localized: "settings.notifications.section.system", bundle: .gymNutshellCore))
            }
            .disabled(!isAuthorized)
        }
        .navigationTitle(String(localized: "settings.preference.notifications", bundle: .gymNutshellCore))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            authStatus = await NotificationManager.shared.authorizationStatus()
        }
        .alert(String(localized: "settings.notifications.denied.title", bundle: .gymNutshellCore), isPresented: $showDeniedAlert) {
            Button(String(localized: "common.cancel", bundle: .gymNutshellCore), role: .cancel) {}
            Button(String(localized: "settings.notifications.denied.open", bundle: .gymNutshellCore)) {
                if let url = NotificationManager.systemSettingsURL { openURL(url) }
            }
        } message: {
            Text(String(localized: "settings.notifications.denied.message", bundle: .gymNutshellCore))
        }
    }

    // MARK: - Permissão

    private func requestAuthorization() {
        Task {
            let granted = await NotificationManager.shared.requestAuthorization()
            let status = await NotificationManager.shared.authorizationStatus()
            await MainActor.run {
                authStatus = status
                if granted {
                    NotificationManager.shared.applyDefaultEnabledKinds()
                    NotificationManager.shared.rescheduleAllActive()
                } else if status == .denied {
                    showDeniedAlert = true
                }
            }
        }
    }
}

// MARK: - NotificationRow

/// Linha genérica para um `NotificationKind` fixo.
/// Usa @AppStorage direto no UserDefaults, isso elimina qualquer sincronização manual
/// (e o feedback loop que ela causava).
/// Internal (não-private) pra ser reutilizada em GoalsNotificationsSettingsView.
struct NotificationRow: View {
    let kind: NotificationKind

    @AppStorage private var isEnabled: Bool
    @State private var showEditSheet: Bool = false

    init(kind: NotificationKind) {
        self.kind = kind
        self._isEnabled = AppStorage(
            wrappedValue: false,
            "notifications.enabled.\(kind.rawValue)"
        )
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                titleLabel
                Text(NSLocalizedString(kind.descriptionKey, bundle: .gymNutshellCore, comment: ""))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                showEditSheet = true
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18, weight: .regular))
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(String(localized: "a11y.button.edit.notification.label",
                                       bundle: .gymNutshellCore))
            .accessibilityHint(String(localized: "a11y.button.edit.notification.hint",
                                      bundle: .gymNutshellCore))
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
        }
        .onChange(of: isEnabled) { _, newValue in
            if newValue {
                NotificationManager.shared.reschedule(kind: kind)
            } else {
                NotificationManager.shared.cancel(kind: kind)
            }
        }
        .sheet(isPresented: $showEditSheet) {
            NavigationStack {
                NotificationIntervalEditView(kind: kind)
            }
        }
    }

    // Metas usam emoji representativo (mesmo de TrackingGoalsSettingsView);
    // seção Sistema usa SF Symbol.
    @ViewBuilder
    private var titleLabel: some View {
        let title = NSLocalizedString(kind.titleKey, bundle: .gymNutshellCore, comment: "")
        if let emoji = kind.emoji {
            Text("\(emoji)  \(title)")
        } else if let icon = kind.systemIcon {
            Label(title, systemImage: icon)
        } else {
            Text(title)
        }
    }
}

// MARK: - CustomNotificationRow

/// Row de notificação para metas personalizadas.
/// Internal (não-private) pra ser reutilizada em GoalsNotificationsSettingsView.
struct CustomNotificationRow: View {
    let goal: CustomTrackingGoal

    @AppStorage private var isEnabled: Bool
    @State private var showEditSheet: Bool = false

    init(goal: CustomTrackingGoal) {
        self.goal = goal
        self._isEnabled = AppStorage(
            wrappedValue: false,
            "notifications.enabled.custom.\(goal.id.uuidString)"
        )
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(goal.emoji) \(goal.name)")
                Text(String(localized: "notifications.custom.description", bundle: .gymNutshellCore))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                showEditSheet = true
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18, weight: .regular))
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(String(localized: "a11y.button.edit.notification.label",
                                       bundle: .gymNutshellCore))
            .accessibilityHint(String(localized: "a11y.button.edit.notification.hint",
                                      bundle: .gymNutshellCore))
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
        }
        .onChange(of: isEnabled) { _, newValue in
            if newValue {
                NotificationManager.shared.rescheduleCustom(goal: goal, currentIntake: nil)
            } else {
                NotificationManager.shared.cancelCustom(id: goal.id)
            }
        }
        .sheet(isPresented: $showEditSheet) {
            NavigationStack {
                NotificationIntervalEditView(customGoal: goal)
            }
        }
    }
}
