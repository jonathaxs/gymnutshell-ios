// ⌘
//  GymNutshell/GymNutshellApp/Views/SettingsView/Goals/EditCustomGoalCategoryView.swift
//
//  Propósito: Formulário em sheet pra criar ou editar uma categoria do usuário (nome, tipo e ícone).
//             Criar: pelo + das Metas (Nova categoria). Editar: pelo lápis na página Categorias.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-04-20.
// ⌘

import SwiftUI
import GymNutshellCore

struct EditCustomGoalCategoryView: View {

    /// nil = categoria nova.
    let original: CustomGoalCategory?
    var onSave: (CustomGoalCategory) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var kind: CategoryKind
    @State private var symbolName: String

    init(category: CustomGoalCategory? = nil, onSave: @escaping (CustomGoalCategory) -> Void = { _ in }) {
        self.original = category
        self.onSave = onSave
        _name = State(initialValue: category?.name ?? "")
        _kind = State(initialValue: category?.kind ?? .standard)
        _symbolName = State(initialValue: category?.symbolName ?? CustomGoalCategory.defaultSymbolName)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Nome igual ao de uma categoria fixa ou de outra personalizada.
    private var isNameConflict: Bool {
        let lower = trimmedName.lowercased()
        guard !lower.isEmpty else { return false }
        if GoalCategory.allCases.contains(where: { $0.displayName.lowercased() == lower }) { return true }
        return CustomGoalCategoriesStore.load().contains { $0.id != original?.id && $0.name.lowercased() == lower }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(String(localized: "settings.addgoal.category.new.name.placeholder", bundle: .gymNutshellCore),
                              text: $name)
                    // Categoria personalizada pode trocar de tipo a qualquer momento; os valores do dia ficam.
                    CategoryKindPicker(selection: $kind)
                } header: {
                    Text(String(localized: "settings.addgoal.category.new.section", bundle: .gymNutshellCore))
                } footer: {
                    if isNameConflict {
                        Text(String(localized: "settings.addgoal.warning.category.duplicate", bundle: .gymNutshellCore))
                            .foregroundStyle(.red)
                    } else {
                        Text(kind.settingsFooter)
                    }
                }

                Section(String(localized: "settings.category.icon.section", bundle: .gymNutshellCore)) {
                    CategorySymbolPicker(selection: $symbolName)
                }
            }
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
            .navigationTitle(original?.name
                             ?? String(localized: "settings.addgoal.category.new.button", bundle: .gymNutshellCore))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    SheetCloseButton(title: String(localized: "settings.addgoal.cancel", bundle: .gymNutshellCore)) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    SheetConfirmButton(title: String(localized: "settings.addgoal.save", bundle: .gymNutshellCore)) {
                        let updated = original.map {
                            CustomGoalCategory(id: $0.id, name: trimmedName, kind: kind, symbolName: symbolName)
                        } ?? CustomGoalCategory(name: trimmedName, kind: kind, symbolName: symbolName)
                        CustomGoalCategoriesStore.upsert(updated)
                        onSave(updated)
                        dismiss()
                    }
                    .disabled(trimmedName.isEmpty || isNameConflict)
                }
            }
        }
    }
}
