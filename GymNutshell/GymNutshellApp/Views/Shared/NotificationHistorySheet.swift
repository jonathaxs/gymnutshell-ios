// ⌘
//  GymNutshell/GymNutshellApp/Views/Shared/NotificationHistorySheet.swift
//
//  Propósito: Sheet compartilhada pelas 4 telas principais (Today, Achievements,
//             Statistics, Settings) que mostra o histórico de notificações de evento
//             dos últimos 3 dias. Tap numa entrada dispara o mesmo deep-link da
//             notificação original.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-04-24.
// ⌘

import SwiftUI
import UserNotifications
import GymNutshellCore

/// Lista agrupada por dia das notificações de evento disparadas nos últimos 3 dias.
struct NotificationHistorySheet: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Bindable private var store = NotificationHistoryStore.shared

    @State private var authStatus: UNAuthorizationStatus = .notDetermined
    @State private var showDeniedAlert = false
    @State private var editMode: EditMode = .inactive

    private var isAuthorized: Bool {
        authStatus == .authorized || authStatus == .provisional
    }

    private var grouped: [(date: Date, items: [NotificationHistoryEntry])] {
        let calendar = Calendar.current
        let buckets = Dictionary(grouping: store.entries) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }
        return buckets
            .map { (date: $0.key, items: $0.value.sorted { $0.timestamp > $1.timestamp }) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.entries.isEmpty {
                    emptyState
                } else {
                    List {
                        if !isAuthorized {
                            authorizeSection
                        }
                        ForEach(grouped, id: \.date) { group in
                            Section(header: Text(dayTitle(for: group.date))) {
                                ForEach(group.items) { entry in
                                    row(for: entry)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                delete(entry)
                                            } label: {
                                                Label(
                                                    String(localized: "notifications.history.delete",
                                                           bundle: .gymNutshellCore),
                                                    systemImage: "trash"
                                                )
                                            }
                                            // Força vermelho padrão iOS, o `.tint` do
                                            // NavigationSplitView estava sobrescrevendo o
                                            // vermelho do role `.destructive`.
                                            .tint(.red)
                                        }
                                }
                                .onDelete { offsets in
                                    for offset in offsets {
                                        delete(group.items[offset])
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .environment(\.editMode, $editMode)
            .navigationTitle(String(localized: "notifications.history.title", bundle: .gymNutshellCore))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    SheetCloseButton { dismiss() }
                }
                // Edit button manual, EditButton() do sistema não dispara o
                // binding de editMode de forma confiável dentro de sheet+NavigationStack.
                // Botão custom replicando o padrão da TrackingGoalsSettingsView.
                if !store.entries.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        SheetToolbarButton(title: editMode.isEditing
                                           ? String(localized: "common.done", bundle: .gymNutshellCore)
                                           : String(localized: "common.edit", bundle: .gymNutshellCore),
                                           systemImage: editMode.isEditing ? "checkmark" : "pencil") {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                editMode = editMode.isEditing ? .inactive : .active
                            }
                        }
                    }
                }
            }
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
    }

    @ViewBuilder
    private var authorizeSection: some View {
        Section {
            Button(String(localized: "settings.notifications.authorize.button", bundle: .gymNutshellCore)) {
                requestAuthorization()
            }
        } footer: {
            Text(String(localized: "settings.notifications.authorize.footer", bundle: .gymNutshellCore))
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(String(localized: "notifications.history.empty.title", bundle: .gymNutshellCore))
                .font(.headline)
                .multilineTextAlignment(.center)
            Text(String(localized: "notifications.history.empty.description", bundle: .gymNutshellCore))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if !isAuthorized {
                Button(String(localized: "settings.notifications.authorize.button", bundle: .gymNutshellCore)) {
                    requestAuthorization()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Apaga a entrada localmente e sincroniza com o Watch.
    private func delete(_ entry: NotificationHistoryEntry) {
        store.delete(id: entry.id)
        WatchConnectivityManager.shared.sendHistoryDelete(id: entry.id)
    }

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

    @ViewBuilder
    private func row(for entry: NotificationHistoryEntry) -> some View {
        let timeString = entry.timestamp.formatted(date: .omitted, time: .shortened)
        HStack(alignment: .top, spacing: 12) {
            icon(for: entry)
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.subheadline.weight(.semibold))
                Text(entry.body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(entry.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .tapButton {
            // No modo edit, o tap na linha não dispara deep-link, só o `-` do iOS age.
            guard !editMode.isEditing else { return }
            handleTap(entry)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: String(localized: "a11y.history.row.format",
                                                 bundle: .gymNutshellCore),
                                   entry.title, entry.body, timeString))
        .accessibilityHint(String(localized: "a11y.history.row.hint", bundle: .gymNutshellCore))
    }

    @ViewBuilder
    private func icon(for entry: NotificationHistoryEntry) -> some View {
        if let emoji = entry.kind?.emoji {
            Text(emoji).font(.title3)
        } else if let symbol = entry.kind?.systemIcon {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
        } else {
            Image(systemName: "bell")
                .font(.title3)
                .foregroundStyle(Color.accentColor)
        }
    }

    private func dayTitle(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return String(localized: "notifications.history.today", bundle: .gymNutshellCore)
        } else if calendar.isDateInYesterday(date) {
            return String(localized: "notifications.history.yesterday", bundle: .gymNutshellCore)
        } else {
            return AppDateFormatters.mediumDate.string(from: date)
        }
    }

    /// Dispara o mesmo deep-link que a notificação original acionaria.
    private func handleTap(_ entry: NotificationHistoryEntry) {
        guard let route = entry.route else { return }
        var userInfo: [String: Any] = ["route": route.rawValue]
        if let achievementDate = entry.achievementDate {
            userInfo["achievementDate"] = achievementDate.timeIntervalSince1970
        }
        dismiss()
        // Pequeno delay pra garantir que a sheet fechou antes do deep-link mudar de tab.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            NotificationCenter.default.post(
                name: .gaNotificationRoute,
                object: nil,
                userInfo: userInfo
            )
        }
    }
}
