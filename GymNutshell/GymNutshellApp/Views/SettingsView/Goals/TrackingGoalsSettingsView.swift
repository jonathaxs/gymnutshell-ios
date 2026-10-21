// ⌘
//  GymNutshell/GymNutshellApp/Views/SettingsView/Goals/TrackingGoalsSettingsView.swift
//
//  Propósito: Hub central pra gerenciar todas as metas diárias agrupadas por categoria ,
//             métricas fixas, objetivo fitness e metas de rastreio personalizadas criadas pelo usuário.
//             Cada categoria é colapsável (chevron estilo Finder).
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-11.
// ⌘

import SwiftUI
import GymNutshellCore

/// Exibe e gerencia todas as metas diárias agrupadas por categoria.
/// Cada categoria é colapsável via chevron no header da seção.
/// Metas opcionais removidas aparecem acinzentadas com o botão Adicionar; segurar uma opcional
/// incluída abre o balão com Excluir meta.
struct TrackingGoalsSettingsView: View {

    // MARK: - Estado

    @State private var customTrackingGoals: [CustomTrackingGoal] = []
    @State private var customCategories: [CustomGoalCategory] = []
    @State private var orderedGoalKeys: [String] = []
    @State private var orderedCategories: [GoalCategory] = GoalCategoryOrderStore.defaultOrder
    @State private var removedItems: Set<String> = []
    @State private var editMode: EditMode = .inactive
    @State private var isPresentingAddGoal: Bool = false

    // Cor de destaque, usada nos badges de obrigatoriedade das metas.
    @AppStorage(AppAccentColor.storageKey) private var storedColorRaw: String = AppAccentColor.blue.rawValue
    private var accentColor: Color { (AppAccentColor(rawValue: storedColorRaw) ?? .blue).color }

    // Sistema de medidas, controla exibição da unidade de água (ml vs fl oz).
    @AppStorage(UserProfile.measurementSystemKey) private var measurementSystem: MeasurementSystem = .metric

    // Estado de colapso das categorias na Settings.
    @AppStorage("settings.goal.collapsed") private var settingsCollapsedRaw: String = ""

    // MARK: - Colapso de categorias

    private var settingsCollapsedCategories: Set<String> {
        Set(settingsCollapsedRaw.split(separator: ",").map(String.init).filter { !$0.isEmpty })
    }

    private func isSettingsCategoryCollapsed(_ category: GoalCategory) -> Bool {
        settingsCollapsedCategories.contains(category.rawValue)
    }

    private func toggleSettingsCategory(_ category: GoalCategory) {
        var current = settingsCollapsedCategories
        if current.contains(category.rawValue) {
            current.remove(category.rawValue)
        } else {
            current.insert(category.rawValue)
        }
        settingsCollapsedRaw = current.joined(separator: ",")
    }

    // MARK: - Helpers de categoria

    private func fixedKeysForCategory(_ category: GoalCategory) -> [String] {
        orderedGoalKeys.filter { GoalCategory.defaultCategory(for: $0) == category }
    }

    private func customGoalsForCategory(_ category: GoalCategory) -> [CustomTrackingGoal] {
        customTrackingGoals.filter { $0.category == category }
    }

    private var uncategorizedCustomGoals: [CustomTrackingGoal] {
        customTrackingGoals.filter { $0.category == nil && $0.customCategoryId == nil }
    }

    private func customGoalsFor(customCategoryId: String) -> [CustomTrackingGoal] {
        customTrackingGoals.filter { $0.customCategoryId == customCategoryId }
    }

    // MARK: - Metadados

    // Retorna metadados de exibição pra uma chave de meta fixa.
    // O incremento usa o valor salvo pelo usuário em TrackingGoalDetailView, com fallback no padrão.
    private func meta(for key: String) -> (icon: String, unit: String, fallback: Int, increment: Int)? {
        switch key {
        case "tracking.workout":
            return ("🏋️", "min", DefaultGoals.workout,  storedIncrement(for: key, fallback: DefaultGoals.workoutIncrement))
        case "tracking.cardio":
            return ("🏃", "min",  DefaultGoals.cardio,   storedIncrement(for: key, fallback: DefaultGoals.cardioIncrement))
        case "tracking.sleep":
            return ("💤", "h",    DefaultGoals.sleep,    storedIncrement(for: key, fallback: 1))
        case "tracking.water":
            if measurementSystem == .us {
                return ("💧", "fl oz", DefaultGoals.water, storedIncrement(for: key, fallback: UnitConverter.flOzWaterStep))
            }
            return ("💧", "ml", DefaultGoals.water, storedIncrement(for: key, fallback: 250))
        case "tracking.protein":
            return ("🍗", "g", DefaultGoals.protein, storedIncrement(for: key, fallback: 20))
        case "tracking.carbs":
            return ("🍞", "g", DefaultGoals.carbs,   storedIncrement(for: key, fallback: 10))
        case "tracking.goodFat":
            return ("🧈", "g", DefaultGoals.goodFat, storedIncrement(for: key, fallback: 5))
        case "tracking.fiber":
            return ("🌾", "g", DefaultGoals.fiber,   storedIncrement(for: key, fallback: 5))
        case "tracking.creatine":
            return ("🧪", "g", DefaultGoals.creatine, storedIncrement(for: key, fallback: DefaultGoals.creatineIncrement))
        default: return nil
        }
    }

    private func storedIncrement(for key: String, fallback: Int) -> Int {
        let stored = UserDefaults.standard.integer(forKey: "\(key).increment")
        return stored > 0 ? stored : fallback
    }


    // Retorna o título de exibição localizado pra uma chave de meta fixa.
    private static func title(for key: String) -> String {
        switch key {
        case "tracking.workout":  return String(localized: "today.goals.workout", bundle: .gymNutshellCore)
        case "tracking.cardio":   return String(localized: "today.goals.cardio", bundle: .gymNutshellCore)
        case "tracking.sleep":    return String(localized: "settings.goal.sleep", bundle: .gymNutshellCore)
        case "tracking.water":    return String(localized: "settings.goal.water", bundle: .gymNutshellCore)
        case "tracking.protein":  return String(localized: "settings.goal.protein", bundle: .gymNutshellCore)
        case "tracking.carbs":    return String(localized: "settings.goal.carbs", bundle: .gymNutshellCore)
        case "tracking.goodFat":  return String(localized: "settings.goal.fats", bundle: .gymNutshellCore)
        case "tracking.fiber":    return String(localized: "settings.goal.fiber", bundle: .gymNutshellCore)
        case "tracking.creatine": return String(localized: "today.goals.creatine", bundle: .gymNutshellCore)
        default: return key
        }
    }

    // Retorna o valor a exibir pra uma meta, já convertido pra unidade do usuário.
    private func displayValue(key: String, fallback: Int) -> Int {
        let stored = UserDefaults.standard.integer(forKey: key)
        let raw = stored > 0 ? stored : fallback
        if key == "tracking.water", measurementSystem == .us {
            return Int(UnitConverter.mlToFlOz(Double(raw)).rounded())
        }
        return raw
    }

    // MARK: - Body

    var body: some View {
        List {
            // Atalho pra subpágina Categorias (ordem + edição de personalizadas).
            Section {
                NavigationLink {
                    CategoriesSettingsView()
                } label: {
                    Label(String(localized: "settings.goals.categories.title", bundle: .gymNutshellCore),
                          systemImage: "square.grid.2x2")
                        .foregroundStyle(.primary)
                }
            }

            ForEach(orderedCategories, id: \.self) { category in
                let fixedKeys = fixedKeysForCategory(category)
                let customGoals = customGoalsForCategory(category)

                // Só mostra a seção se houver metas nela (fixas ou custom).
                if !fixedKeys.isEmpty || !customGoals.isEmpty {
                    Section {
                        if !isSettingsCategoryCollapsed(category) {
                            // Metas fixas da categoria, suporta reordenação via drag no modo editar.
                            ForEach(fixedKeys, id: \.self) { key in
                                if let m = meta(for: key) {
                                    fixedGoalRow(key: key, meta: m)
                                }
                            }
                            .onMove { from, to in
                                moveGoalsWithinCategory(subset: fixedKeys, from: from, to: to)
                            }

                            // Metas personalizadas da categoria, reordenáveis dentro da categoria.
                            ForEach(customGoals) { trackingGoal in
                                customGoalRow(trackingGoal)
                            }
                            .onMove { from, to in
                                moveCustomGoalsWithinCategory(subset: customGoals, from: from, to: to)
                            }
                            .onDelete { offsets in
                                deleteCustomGoals(at: offsets, from: customGoals)
                            }
                        }
                    } header: {
                        settingsCategoryHeader(category)
                    }
                }
            }

            // Categorias criadas pelo usuário, cada uma vira uma seção abaixo das fixas.
            ForEach(customCategories) { customCategory in
                let goalsInCategory = customGoalsFor(customCategoryId: customCategory.id)
                if !goalsInCategory.isEmpty {
                    Section(customCategory.name) {
                        ForEach(goalsInCategory) { trackingGoal in
                            customGoalRow(trackingGoal)
                        }
                        .onMove { from, to in
                            moveCustomGoalsWithinCategory(subset: goalsInCategory, from: from, to: to)
                        }
                        .onDelete { offsets in
                            deleteCustomGoals(at: offsets, from: goalsInCategory)
                        }
                    }
                }
            }

            // Metas personalizadas sem categoria.
            if !uncategorizedCustomGoals.isEmpty {
                Section(String(localized: "settings.tracking.goals.section.custom", bundle: .gymNutshellCore)) {
                    ForEach(uncategorizedCustomGoals) { trackingGoal in
                        customGoalRow(trackingGoal)
                    }
                    .onDelete { offsets in
                        deleteCustomGoals(at: offsets, from: uncategorizedCustomGoals)
                    }
                }
            }
        }
        .environment(\.editMode, $editMode)
        .navigationTitle(String(localized: "settings.goals.title", bundle: .gymNutshellCore))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        isPresentingAddGoal = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(String(localized: "a11y.button.add.goal.label",
                                               bundle: .gymNutshellCore))
                    .accessibilityHint(String(localized: "a11y.button.add.goal.hint",
                                              bundle: .gymNutshellCore))

                    Button(editMode.isEditing
                           ? String(localized: "settings.tracking.goals.done", bundle: .gymNutshellCore)
                           : String(localized: "settings.tracking.goals.editMode", bundle: .gymNutshellCore)) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            editMode = editMode.isEditing ? .inactive : .active
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isPresentingAddGoal) {
            AddTrackingGoalView()
        }
        .onAppear {
            orderedGoalKeys = GoalOrderStore.load()
            orderedCategories = GoalCategoryOrderStore.load()
            customTrackingGoals = CustomTrackingGoalsStore.load()
            customCategories = CustomGoalCategoriesStore.load()
            removedItems = RemovedItemsStore.load()
        }
        .onChange(of: isPresentingAddGoal) { _, isPresenting in
            if !isPresenting {
                customTrackingGoals = CustomTrackingGoalsStore.load()
                customCategories = CustomGoalCategoriesStore.load()
            }
        }
    }

    // MARK: - Linha de meta personalizada

    @ViewBuilder
    private func customGoalRow(_ trackingGoal: CustomTrackingGoal) -> some View {
        NavigationLink {
            AddTrackingGoalView(editingGoal: trackingGoal, isSheet: false)
        } label: {
            HStack {
                Text(trackingGoal.emoji)
                VStack(alignment: .leading, spacing: 2) {
                    Text(trackingGoal.name)
                    Text("\(trackingGoal.goal) \(trackingGoal.unit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(String(localized: "settings.goals.custom.badge", bundle: .gymNutshellCore))
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
        }
    }

    // MARK: - Header de categoria (colapsável)

    @ViewBuilder
    private func settingsCategoryHeader(_ category: GoalCategory) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                toggleSettingsCategory(category)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isSettingsCategoryCollapsed(category) ? "chevron.right" : "chevron.down")
                    .font(.caption.weight(.semibold))
                    .frame(width: 12)
                    .accessibilityHidden(true)
                Text(category.displayName)
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .textCase(nil)
        .accessibilityLabel(A11y.categoryLabel(category.displayName))
        .accessibilityHint(A11y.categoryHint())
    }

    // MARK: - Linha de meta fixa

    @ViewBuilder
    private func fixedGoalRow(key: String, meta: (icon: String, unit: String, fallback: Int, increment: Int)) -> some View {
        let isRemoved = removedItems.contains(key)
        let isRemovable = RemovedItemsStore.removableTrackingKeys.contains(key)

        if isRemoved {
            HStack {
                Text(meta.icon).opacity(0.4)
                    .accessibilityHidden(true)
                Text(Self.title(for: key))
                    .foregroundStyle(.secondary)
                    .opacity(0.6)
                Spacer()
                // Mesmo botão Adicionar da tela Suas metas da Welcome.
                Button {
                    UISelectionFeedbackGenerator().selectionChanged()
                    withAnimation(.snappy(duration: 0.25)) {
                        RemovedItemsStore.restore(key)
                        removedItems = RemovedItemsStore.load()
                    }
                } label: {
                    // HStack em vez de Label: dentro da List o Label perde o ícone.
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text(String(localized: "welcome.option.add", bundle: .gymNutshellCore))
                    }
                    .font(.subheadline.weight(.semibold))
                }
                .appProminentButton(accentColor, size: .regular)
                .fixedSize()
                .accessibilityLabel(String(localized: "a11y.button.restore.goal.label",
                                           bundle: .gymNutshellCore))
            }
        } else {
            HStack {
                NavigationLink {
                    TrackingGoalDetailView(
                        icon: meta.icon,
                        title: Self.title(for: key),
                        unit: meta.unit,
                        key: key,
                        fallback: meta.fallback,
                        increment: meta.increment
                    )
                } label: {
                    HStack {
                        Text(meta.icon)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(Self.title(for: key))
                            Text("\(displayValue(key: key, fallback: meta.fallback)) \(meta.unit)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        // Selo de meta padrão do app no lugar do texto: preto (branco no escuro) nas fixas,
                        // cinza nas opcionais adicionadas (Gordura boa, Creatina).
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(isRemovable ? Color(.systemGray) : Color.primary)
                            .accessibilityLabel(String(localized: "settings.goals.default.a11y",
                                                       bundle: .gymNutshellCore))
                    }
                }
                // Segurar a meta opcional abre o balão com Excluir meta.
                .contextMenu {
                    if isRemovable {
                        Button(role: .destructive) {
                            withAnimation(.snappy(duration: 0.25)) {
                                RemovedItemsStore.remove(key)
                                removedItems = RemovedItemsStore.load()
                            }
                        } label: {
                            Label(String(localized: "settings.goals.remove", bundle: .gymNutshellCore),
                                  systemImage: "trash")
                        }
                    }
                }
                // Botão remover pra metas opcionais no modo editar.
                if editMode.isEditing, isRemovable {
                    Button {
                        RemovedItemsStore.remove(key)
                        removedItems = RemovedItemsStore.load()
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "a11y.button.remove.goal.label",
                                               bundle: .gymNutshellCore))
                }
            }
        }
    }

    // MARK: - Actions

    private func deleteCustomGoals(at offsets: IndexSet, from subset: [CustomTrackingGoal]) {
        let idsToDelete = offsets.map { subset[$0].id }
        customTrackingGoals.removeAll { idsToDelete.contains($0.id) }
        CustomTrackingGoalsStore.delete(ids: idsToDelete)
    }

    // Reordena metas personalizadas dentro de uma categoria sem alterar as demais.
    // Aplica o movimento no subset e recalcula as posições no array global.
    private func moveCustomGoalsWithinCategory(subset: [CustomTrackingGoal], from: IndexSet, to: Int) {
        var mutableSubset = subset
        mutableSubset.move(fromOffsets: from, toOffset: to)
        let subsetIds = subset.map(\.id)
        let subsetIndices = subsetIds.compactMap { id in
            customTrackingGoals.firstIndex(where: { $0.id == id })
        }
        var newOrder = customTrackingGoals
        for (i, idx) in subsetIndices.enumerated() {
            newOrder[idx] = mutableSubset[i]
        }
        customTrackingGoals = newOrder
        CustomTrackingGoalsStore.save(newOrder)
    }

    // Reordena metas dentro de uma categoria sem mover metas de outras categorias.
    // Aplica o movimento no subset e recalcula as posições no array global.
    private func moveGoalsWithinCategory(subset: [String], from: IndexSet, to: Int) {
        var mutableSubset = subset
        mutableSubset.move(fromOffsets: from, toOffset: to)
        let subsetIndices = subset.compactMap { orderedGoalKeys.firstIndex(of: $0) }
        var newOrder = orderedGoalKeys
        for (i, idx) in subsetIndices.enumerated() {
            newOrder[idx] = mutableSubset[i]
        }
        orderedGoalKeys = newOrder
        GoalOrderStore.save(newOrder)
        // Sinaliza o app pra reconstruir o WidgetSnapshot, caso contrário, os widgets
        // (especialmente o de Metas) ficam com a ordem antiga até o próximo intake change.
        NotificationCenter.default.post(name: .gymNutshellIntakeDidChange, object: nil)
    }
}
