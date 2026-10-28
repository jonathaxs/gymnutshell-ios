// ⌘
//  GymNutshell/GymNutshellApp/Views/SettingsView/Goals/EditCustomGoalCategoryView.swift
//
//  Propósito: Formulário em sheet pra editar o nome, o tipo e o ícone de uma categoria criada pelo usuário.
//             Aberto pela TrackingGoalsSettingsView quando o usuário toca numa categoria personalizada
//             na seção de reordenação.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-04-20.
// ⌘

import SwiftUI
import GymNutshellCore

struct EditCustomGoalCategoryView: View {

    let original: CustomGoalCategory
    var onSave: (CustomGoalCategory) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var kind: CategoryKind
    @State private var symbolName: String

    init(category: CustomGoalCategory, onSave: @escaping (CustomGoalCategory) -> Void) {
        self.original = category
        self.onSave = onSave
        _name = State(initialValue: category.name)
        _kind = State(initialValue: category.kind)
        _symbolName = State(initialValue: category.symbolName)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
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
                    Text(kind.settingsFooter)
                }

                Section(String(localized: "settings.category.icon.section", bundle: .gymNutshellCore)) {
                    CategorySymbolPicker(selection: $symbolName)
                }
            }
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
            .navigationTitle(original.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    SheetCloseButton(title: String(localized: "settings.addgoal.cancel", bundle: .gymNutshellCore)) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    SheetConfirmButton(title: String(localized: "settings.addgoal.save", bundle: .gymNutshellCore)) {
                        let updated = CustomGoalCategory(
                            id: original.id,
                            name: trimmedName,
                            kind: kind,
                            symbolName: symbolName
                        )
                        CustomGoalCategoriesStore.upsert(updated)
                        onSave(updated)
                        dismiss()
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
        }
    }
}
