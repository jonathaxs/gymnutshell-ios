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

    private enum PermissionState { case idle, allowed, requested, denied }

    @State private var notificationsState: PermissionState = .idle
    @State private var healthState: PermissionState = .idle

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
                            subtitle: String(localized: "welcome.step.ready.subtitle", bundle: .gymNutshellCore)
                        )
                    }

                    permissionRow(
                        icon: "bell.badge.fill",
                        title: String(localized: "welcome.ready.notifications.title", bundle: .gymNutshellCore),
                        desc: String(localized: "welcome.ready.notifications.desc", bundle: .gymNutshellCore),
                        state: notificationsState,
                        action: requestNotifications
                    )

                    // Aparelhos sem Apple Saúde (alguns iPads) não mostram a linha.
                    if HealthKitManager.isAvailable {
                        permissionRow(
                            icon: "heart.fill",
                            title: String(localized: "welcome.ready.health.title", bundle: .gymNutshellCore),
                            desc: String(localized: "welcome.ready.health.desc", bundle: .gymNutshellCore),
                            state: healthState,
                            action: requestHealth
                        )
                    }

                    Text(String(localized: "welcome.ready.footer", bundle: .gymNutshellCore))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding()
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

    // MARK: - Linha de permissão

    private func permissionRow(
        icon: String,
        title: String,
        desc: String,
        state: PermissionState,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(accentColor)
                .frame(width: 34)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(desc)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)

            switch state {
            case .idle:
                Button(String(localized: "welcome.ready.allow", bundle: .gymNutshellCore), action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(accentColor)
            case .allowed:
                Label(String(localized: "welcome.ready.allowed", bundle: .gymNutshellCore), systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.green)
            case .requested:
                Label(String(localized: "welcome.ready.requested", bundle: .gymNutshellCore), systemImage: "checkmark.circle")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            case .denied:
                Text(String(localized: "welcome.ready.denied", bundle: .gymNutshellCore))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
