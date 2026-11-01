// ⌘
//  GymNutshell/GymNutshellApp/Views/SettingsView/Preferences/GoalsNotificationsSettingsView.swift
//
//  Propósito: Subpágina de notificações de Metas. Cada categoria (builtin ou custom)
//             vira uma Section recolhível (chevron estilo TrackingGoalsSettingsView),
//             respeitando a ordem unificada escolhida em Ajustes → Metas → Categorias.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-04-23.
// ⌘

import SwiftUI
import GymNutshellCore

struct GoalsNotificationsSettingsView: View {

    @State private var customGoals: [CustomTrackingGoal] = []
    @State private var categorySections: [MetaCategorySection] = []
    @State private var unassignedCustomGoals: [CustomTrackingGoal] = []
    @State private var hasCheckInGoals: Bool = false

    @AppStorage(NotificationPreferences.groupSupplementsKey) private var groupSupplements: Bool = false

    // Estado de colapso das categorias, chave separada das Metas pra não conflitar
    // com `settings.goal.collapsed` (usado em TrackingGoalsSettingsView).
    @AppStorage("settings.notifications.goals.collapsed") private var collapsedRaw: String = ""

    /// Subseção de Metas: uma categoria (builtin ou custom) com suas metas ordenadas.
    private struct MetaCategorySection: Identifiable {
        let id: String
        let title: String
        let kinds: [NotificationKind]
        let customs: [CustomTrackingGoal]
    }

    var body: some View {
        List {
            // Suplementos no mesmo horário: um aviso por suplemento (padrão) ou um só, agrupado.
            if hasCheckInGoals {
                Section {
                    Toggle(String(localized: "settings.notifications.group.title", bundle: .gymNutshellCore),
                           isOn: $groupSupplements)
                } footer: {
                    Text(String(localized: "settings.notifications.group.footer", bundle: .gymNutshellCore))
                }
            }

            ForEach(categorySections) { section in
                Section {
                    if !isCollapsed(section.id) {
                        ForEach(section.kinds) { kind in
                            NotificationRow(kind: kind)
                        }
                        ForEach(section.customs) { goal in
                            CustomNotificationRow(goal: goal)
                        }
                    }
                } header: {
                    collapsibleHeader(id: section.id, title: section.title)
                }
            }

            // Metas personalizadas sem categoria, sempre no final, também recolhível.
            if !unassignedCustomGoals.isEmpty {
                let unassignedId = "__unassigned__"
                Section {
                    if !isCollapsed(unassignedId) {
                        ForEach(unassignedCustomGoals) { goal in
                            CustomNotificationRow(goal: goal)
                        }
                    }
                } header: {
                    collapsibleHeader(
                        id: unassignedId,
                        title: String(localized: "settings.tracking.goals.section.custom", bundle: .gymNutshellCore)
                    )
                }
            }
        }
        .navigationTitle(String(localized: "settings.notifications.section.goals", bundle: .gymNutshellCore))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            customGoals = CustomTrackingGoalsStore.load()
            rebuildCategorySections()
        }
    }

    // MARK: - Header colapsável

    @ViewBuilder
    private func collapsibleHeader(id: String, title: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                toggleCollapsed(id)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isCollapsed(id) ? "chevron.right" : "chevron.down")
                    .font(.caption.weight(.semibold))
                    .frame(width: 12)
                    .accessibilityHidden(true)
                Text(title)
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .textCase(nil)
        .accessibilityLabel(title)
        .accessibilityHint(String(localized: "a11y.section.collapsible.hint", bundle: .gymNutshellCore))
    }

    // MARK: - Estado de colapso

    private var collapsedSet: Set<String> {
        Set(collapsedRaw.split(separator: "|").map(String.init).filter { !$0.isEmpty })
    }

    private func isCollapsed(_ id: String) -> Bool {
        collapsedSet.contains(id)
    }

    private func toggleCollapsed(_ id: String) {
        var current = collapsedSet
        if current.contains(id) {
            current.remove(id)
        } else {
            current.insert(id)
        }
        collapsedRaw = current.joined(separator: "|")
    }

    // MARK: - Montagem das subseções

    private func rebuildCategorySections() {
        // Filtra metas removidas pelo usuário em Hoje, sem isso elas continuam
        // listadas aqui mesmo após sumir da TodayView e do cálculo de progresso.
        let removed = RemovedItemsStore.load()
        let fixedOrder = GoalOrderStore.load().filter { !removed.contains($0) }

        // Kinds fixos agrupados por categoria, já na ordem do GoalOrderStore.
        var kindsByCategory: [GoalCategory: [NotificationKind]] = [:]
        for trackingKey in fixedOrder {
            guard
                let kind = NotificationKind.from(trackingOrderKey: trackingKey),
                let category = GoalCategory.defaultCategory(for: trackingKey)
            else { continue }
            kindsByCategory[category, default: []].append(kind)
        }

        // Metas personalizadas agrupadas por categoria builtin ou custom.
        var customsByBuiltin: [GoalCategory: [CustomTrackingGoal]] = [:]
        var customsByCustomId: [String: [CustomTrackingGoal]] = [:]
        var unassigned: [CustomTrackingGoal] = []
        for goal in customGoals {
            if let customId = goal.customCategoryId {
                customsByCustomId[customId, default: []].append(goal)
            } else if let cat = goal.category {
                customsByBuiltin[cat, default: []].append(goal)
            } else {
                unassigned.append(goal)
            }
        }

        // Monta as seções na ordem unificada (builtin + custom) escolhida pelo usuário.
        var sections: [MetaCategorySection] = []
        for item in UnifiedCategoryOrderStore.load() {
            switch item {
            case .builtin(let category):
                let kinds = kindsByCategory[category] ?? []
                let customs = customsByBuiltin[category] ?? []
                guard !kinds.isEmpty || !customs.isEmpty else { continue }
                sections.append(.init(
                    id: "builtin:\(category.rawValue)",
                    title: category.displayName,
                    kinds: kinds,
                    customs: customs
                ))
            case .custom(let category):
                let customs = customsByCustomId[category.id] ?? []
                guard !customs.isEmpty else { continue }
                sections.append(.init(
                    id: "custom:\(category.id)",
                    title: category.name,
                    kinds: [],
                    customs: customs
                ))
            }
        }
        categorySections = sections
        unassignedCustomGoals = unassigned

        let categories = CustomGoalCategoriesStore.load()
        hasCheckInGoals = !removed.contains("tracking.creatine")
            || customGoals.contains { $0.kind(in: categories) == .checkIn }
    }
}
