// ⌘
//  GymNutshell/GymNutshellApp/Views/Shared/CategoryKindPicker.swift
//
//  Propósito: Seletor do tipo de uma categoria personalizada (padrão, com descanso ou check-in).
//             Usado na criação e na edição da categoria, no lugar do antigo toggle de descanso.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-10-27.
// ⌘

import SwiftUI
import GymNutshellCore

struct CategoryKindPicker: View {

    @Binding var selection: CategoryKind

    var body: some View {
        Picker(String(localized: "settings.category.kind", bundle: .gymNutshellCore), selection: $selection) {
            ForEach(CategoryKind.allCases) { kind in
                Text(kind.displayName).tag(kind)
            }
        }
        .pickerStyle(.menu)
    }
}
