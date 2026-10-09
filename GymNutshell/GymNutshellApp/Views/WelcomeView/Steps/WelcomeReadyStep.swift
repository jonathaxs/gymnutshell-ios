// ⌘
//  GymNutshell/GymNutshellApp/Views/WelcomeView/Steps/WelcomeReadyStep.swift
//
//  Propósito: Última etapa do onboarding ("Tudo pronto"). Oferece pedir as permissões de
//             notificações e Apple Saúde. Recusar ou pular não bloqueia nada.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-10-08.
// ⌘

import SwiftUI
import UserNotifications
import GymNutshellCore

/// Etapa final: duas linhas de permissão opcionais. Cada botão dispara o pedido do sistema.
struct WelcomeReadyStep: View {

    let accentColor: Color
    var isWide: Bool = false


    @State private var notificationsState: PermissionCardState = .idle
    @State private var healthState: PermissionCardState = .idle

    // Chaves que a tela de Ajustes > Apple Saúde já usa.
    @AppStorage("healthkit.syncSleepEnabled") private var syncSleep: Bool = false
    @AppStorage("healthkit.autoWorkoutCheckin") private var autoWorkout: Bool = false

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    if !isWide {
                        WelcomeStepHeader(
                            emoji: "🚀",
                            title: String(localized: "welcome.step.ready.title", bundle: .gymNutshellCore),
                            subtitle: String(localized: "welcome.step.ready.subtitle", bundle: .gymNutshellCore),
                            accentColor: accentColor
                        )
                    }

                    PermissionCard(
                        icon: "bell.badge.fill",
                        iconColor: .red,
                        title: String(localized: "welcome.ready.notifications.title", bundle: .gymNutshellCore),
                        desc: String(localized: "welcome.ready.notifications.desc", bundle: .gymNutshellCore),
                        state: notificationsState,
                        accentColor: accentColor,
                        action: requestNotifications
                    )

                    // Aparelhos sem Apple Saúde (alguns iPads) não mostram a linha.
                    if HealthKitManager.isAvailable {
                        PermissionCard(
                            icon: "heart.fill",
                            iconColor: .pink,
                            title: String(localized: "welcome.ready.health.title", bundle: .gymNutshellCore),
                            desc: String(localized: "welcome.ready.health.desc", bundle: .gymNutshellCore),
                            state: healthState,
                            accentColor: accentColor,
                            action: requestHealth
                        )
                    }

                    Text(String(localized: "welcome.ready.footer", bundle: .gymNutshellCore))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, AppStyle.horizontalPadding)
                .padding(.vertical)
                .frame(maxWidth: .infinity, minHeight: isWide ? geo.size.height : 0, alignment: .center)
            }
        }
        .task {
            // Reflete o estado atual (ex: usuário voltou pra essa etapa depois de permitir).
            let status = await NotificationManager.shared.authorizationStatus()
            switch status {
            case .authorized, .provisional, .ephemeral: notificationsState = .allowed
            case .denied: notificationsState = .denied
            default: break
            }
        }
    }

    // MARK: - Pedidos

    private func requestNotifications() {
        Task {
            let granted = await NotificationManager.shared.requestAuthorization()
            await MainActor.run {
                notificationsState = granted ? .allowed : .denied
                if granted { NotificationManager.shared.applyDefaultEnabledKinds() }
            }
        }
    }

    private func requestHealth() {
        Task {
            _ = await HealthKitManager.shared.requestOnboardingAuthorization()
            await MainActor.run {
                // O Saúde não informa se a leitura foi negada; ligamos os recursos porque o usuário
                // tocou em Permitir. Dá pra desligar em Ajustes > Apple Saúde.
                syncSleep = true
                autoWorkout = true
                healthState = .requested
            }
        }
    }
}
