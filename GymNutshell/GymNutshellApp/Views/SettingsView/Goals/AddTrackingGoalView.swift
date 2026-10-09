// ⌘
//  GymNutshell/GymNutshellApp/Views/SettingsView/Goals/AddTrackingGoalView.swift
//
//  Propósito: Formulário pra adicionar uma nova meta de rastreio opcional personalizada ou editar uma existente.
//             Usado como sheet (modo adicionar, com NavigationStack) ou destino de NavigationLink.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-11.
// ⌘

import SwiftUI
import GymNutshellCore
#if canImport(UIKit)
import UIKit
#endif

// Wrapper pra permitir que o Picker selecione categoria fixa ou personalizada.
enum CategorySelection: Hashable {
    case builtin(GoalCategory)
    case custom(String)
}

/// Tela de formulário pra criar ou editar uma meta de rastreio opcional personalizada.
///
/// - Passa `editingGoal` pra pré-preencher o formulário com os valores existentes.
/// - Define `isSheet: false` ao usar via NavigationLink pra pular o NavigationStack interno.
struct AddTrackingGoalView: View {

    // MARK: - Configuração

    let editingGoal: CustomTrackingGoal?
    let isSheet: Bool

    init(editingGoal: CustomTrackingGoal? = nil, isSheet: Bool = true) {
        self.editingGoal = editingGoal
        self.isSheet = isSheet
    }

    @Environment(\.dismiss) private var dismiss

    @AppStorage(AppAccentColor.storageKey) private var storedColorRaw: String = AppAccentColor.blue.rawValue
    private var accentColor: Color { (AppAccentColor(rawValue: storedColorRaw) ?? .blue).color }

    // MARK: - Campos de rascunho

    @State private var selectedCategory: CategorySelection? = .builtin(.essencial)
    @State private var emoji: String = ""
    @State private var name: String = ""
    @State private var unit: String = ""
    @State private var goalText: String = ""
    @State private var incrementText: String = ""

    // MARK: - Estado da nova categoria

    @State private var customCategories: [CustomGoalCategory] = []
    @State private var existingGoals: [CustomTrackingGoal] = []
    @State private var isCreatingNewCategory: Bool = false
    @State private var newCategoryName: String = ""
    @State private var newCategorySupportsRestDay: Bool = false
    @State private var newCategorySymbol: String = CustomGoalCategory.defaultSymbolName

    // True quando o usuário digitou algo que não é emoji, significa que o teclado
    // de emoji não está habilitado no iPhone/iPad (iOS cai no teclado padrão).
    @State private var isNonEmojiAttempt: Bool = false

    // MARK: - Helpers

    private var isEditing: Bool { editingGoal != nil }

    private var trimmedEmoji: String {
        String(emoji.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1))
    }

    private var trimmedNewCategoryName: String {
        newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static let reservedEmojis: Set<String> = ["🏋️","🏃","💤","💧","🍗","🍞","🧈","🌾","🧪"]
    private static let reservedNames: Set<String> = [
        "workout", "cardio", "sleep", "water", "protein", "carbs", "fats", "fiber", "creatine",
        "treino", "sono", "água", "proteína", "carboidratos", "gorduras", "fibra", "creatina"
    ]

    /// Emoji igual ao de uma meta fixa ou de outra meta personalizada existente.
    private var isEmojiConflict: Bool {
        guard !trimmedEmoji.isEmpty else { return false }
        if Self.reservedEmojis.contains(trimmedEmoji) { return true }
        return existingGoals.contains { goal in
            goal.id != editingGoal?.id && goal.emoji == trimmedEmoji
        }
    }

    /// Nome igual ao de uma meta fixa ou de outra meta personalizada existente.
    private var isNameConflict: Bool {
        let lowerName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !lowerName.isEmpty else { return false }
        if Self.reservedNames.contains(lowerName) { return true }
        return existingGoals.contains { goal in
            goal.id != editingGoal?.id && goal.name.lowercased() == lowerName
        }
    }

    /// True quando o nome digitado pra nova categoria bate com uma categoria fixa ou personalizada existente.
    private var isCategoryNameConflict: Bool {
        guard isCreatingNewCategory, !trimmedNewCategoryName.isEmpty else { return false }
        let lower = trimmedNewCategoryName.lowercased()
        if GoalCategory.allCases.contains(where: { $0.displayName.lowercased() == lower }) { return true }
        return customCategories.contains { $0.name.lowercased() == lower }
    }

    /// True quando o passo é maior que o alvo (ambos já digitados como inteiros válidos).
    private var isStepTooLarge: Bool {
        guard let goal = Int(goalText), goal > 0,
              let step = Int(incrementText), step > 0 else { return false }
        return step > goal
    }

    private var isValid: Bool {
        guard !trimmedEmoji.isEmpty else { return false }
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard !isEmojiConflict, !isNameConflict else { return false }
        guard !unit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard let goal = Int(goalText), goal > 0 else { return false }
        guard let step = Int(incrementText), step > 0, step <= goal else { return false }
        // Se o usuário optou por criar nova categoria, o nome é obrigatório e único.
        if isCreatingNewCategory {
            if trimmedNewCategoryName.isEmpty { return false }
            if isCategoryNameConflict { return false }
        }
        return true
    }

    // MARK: - Body

    var body: some View {
        if isSheet {
            NavigationStack { form }
        } else {
            form
        }
    }

    // MARK: - Conteúdo do formulário

    @ViewBuilder
    private var form: some View {
        Form {
            // Seleção de categoria, fixa ou personalizada.
            Section(String(localized: "settings.addgoal.section.category", bundle: .gymNutshellCore)) {
                Picker(String(localized: "settings.addgoal.section.category", bundle: .gymNutshellCore), selection: $selectedCategory) {
                    ForEach(GoalCategory.allCases, id: \.self) { category in
                        Text(category.displayName)
                            .tag(Optional<CategorySelection>.some(.builtin(category)))
                    }
                    ForEach(customCategories) { category in
                        Text(category.name)
                            .tag(Optional<CategorySelection>.some(.custom(category.id)))
                    }
                }
                .pickerStyle(.menu)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isCreatingNewCategory.toggle()
                        if !isCreatingNewCategory {
                            newCategoryName = ""
                            newCategorySupportsRestDay = false
                            newCategorySymbol = CustomGoalCategory.defaultSymbolName
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isCreatingNewCategory ? "minus.circle.fill" : "plus.circle.fill")
                        Text(String(localized: "settings.addgoal.category.new.button", bundle: .gymNutshellCore))
                    }
                    .foregroundStyle(accentColor)
                }
            }

            // Nova categoria, aparece acima da seção Ícone quando ativada.
            if isCreatingNewCategory {
                Section {
                    Toggle(String(localized: "settings.addgoal.category.new.restDay", bundle: .gymNutshellCore),
                           isOn: $newCategorySupportsRestDay)
                    TextField(String(localized: "settings.addgoal.category.new.name.placeholder", bundle: .gymNutshellCore),
                              text: $newCategoryName)
                    CategorySymbolPicker(selection: $newCategorySymbol)
                } header: {
                    Text(String(localized: "settings.addgoal.category.new.section", bundle: .gymNutshellCore))
                } footer: {
                    if isCategoryNameConflict {
                        Text(String(localized: "settings.addgoal.warning.category.duplicate", bundle: .gymNutshellCore))
                            .foregroundStyle(.red)
                    }
                }
            }

            Section {
                EmojiTextField(
                    placeholder: String(localized: "settings.addgoal.emoji.placeholder", bundle: .gymNutshellCore),
                    text: $emoji,
                    isNonEmojiAttempt: $isNonEmojiAttempt
                )
            } header: {
                Text(String(localized: "settings.addgoal.section.icon", bundle: .gymNutshellCore))
            } footer: {
                if isEmojiConflict {
                    Text(String(localized: "settings.addgoal.warning.emoji", bundle: .gymNutshellCore))
                        .foregroundStyle(.red)
                } else if isNonEmojiAttempt {
                    Text(String(localized: "settings.addgoal.warning.emoji.keyboard", bundle: .gymNutshellCore))
                        .foregroundStyle(.red)
                }
            }

            Section {
                TextField(String(localized: "settings.addgoal.name.placeholder", bundle: .gymNutshellCore), text: $name)
            } header: {
                Text(String(localized: "settings.addgoal.section.name", bundle: .gymNutshellCore))
            } footer: {
                if isNameConflict {
                    Text(String(localized: "settings.addgoal.warning.catalog", bundle: .gymNutshellCore))
                        .foregroundStyle(.red)
                }
            }

            Section(String(localized: "settings.addgoal.section.unit", bundle: .gymNutshellCore)) {
                TextField(String(localized: "settings.addgoal.unit.placeholder", bundle: .gymNutshellCore), text: $unit)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: unit) { _, newValue in
                        // Força primeiro caractere em minúsculo.
                        guard let first = newValue.first, first.isUppercase else { return }
                        unit = first.lowercased() + newValue.dropFirst()
                    }
            }

            Section(String(localized: "settings.addgoal.section.goal", bundle: .gymNutshellCore)) {
                TextField(String(localized: "settings.addgoal.goal.placeholder", bundle: .gymNutshellCore), text: $goalText)
                    .keyboardType(.numberPad)
            }

            Section {
                TextField(String(localized: "settings.addgoal.increment.placeholder", bundle: .gymNutshellCore), text: $incrementText)
                    .keyboardType(.numberPad)
            } header: {
                Text(String(localized: "settings.addgoal.section.increment", bundle: .gymNutshellCore))
            } footer: {
                if isStepTooLarge {
                    Text(String(localized: "settings.addgoal.warning.step", bundle: .gymNutshellCore))
                        .foregroundStyle(.red)
                }
            }
        }
        // O form preenche a largura do container, sem cap interno, o fundo cinza
        // do Form sempre chega nas bordas (iPad landscape, sheet no macOS, etc.).
        .frame(maxWidth: .infinity)
        .navigationTitle(editingGoal.map { "\($0.emoji) \($0.name)" } ?? String(localized: "settings.addgoal.title.new", bundle: .gymNutshellCore))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isSheet {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "settings.addgoal.cancel", bundle: .gymNutshellCore)) {
                        dismiss()
                    }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(String(localized: "settings.addgoal.save", bundle: .gymNutshellCore)) {
                    save()
                    dismiss()
                }
                .disabled(!isValid)
            }
        }
        .onAppear {
            customCategories = CustomGoalCategoriesStore.load()
            existingGoals = CustomTrackingGoalsStore.load()
            loadIfEditing()
        }
    }

    // MARK: - Carregar / Salvar

    private func loadIfEditing() {
        guard let trackingGoal = editingGoal else { return }
        if let customId = trackingGoal.customCategoryId {
            selectedCategory = .custom(customId)
        } else {
            selectedCategory = .builtin(trackingGoal.category ?? .essencial)
        }
        emoji = trackingGoal.emoji
        name = trackingGoal.name
        unit = trackingGoal.unit
        goalText = "\(trackingGoal.goal)"
        incrementText = "\(trackingGoal.increment)"
    }

    private func save() {
        // Resolve a categoria efetiva, cria a nova se o usuário preencheu o formulário.
        var resolvedSelection = selectedCategory
        if isCreatingNewCategory, !trimmedNewCategoryName.isEmpty {
            let newCategory = CustomGoalCategory(
                name: trimmedNewCategoryName,
                supportsRestDay: newCategorySupportsRestDay,
                symbolName: newCategorySymbol
            )
            CustomGoalCategoriesStore.upsert(newCategory)
            resolvedSelection = .custom(newCategory.id)
        }

        var builtin: GoalCategory? = nil
        var customId: String? = nil
        switch resolvedSelection {
        case .builtin(let category): builtin = category
        case .custom(let id):        customId = id
        case .none:                  break
        }

        let trackingGoal = CustomTrackingGoal(
            id: editingGoal?.id ?? UUID(),
            emoji: trimmedEmoji,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            unit: unit.trimmingCharacters(in: .whitespacesAndNewlines),
            goal: Int(goalText) ?? 1,
            increment: Int(incrementText) ?? 1,
            category: builtin,
            customCategoryId: customId
        )
        CustomTrackingGoalsStore.upsert(trackingGoal)
    }
}

// MARK: - EmojiTextField

#if canImport(UIKit)
/// TextField que força o teclado de emojis e limita o conteúdo a um único emoji.
/// Usado no campo Ícone da nova meta, pra eliminar texto arbitrário.
struct EmojiTextField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    /// Sinaliza quando o usuário digita um caractere não-emoji, indica que o teclado
    /// de emoji não está habilitado e o iOS caiu pro teclado padrão.
    @Binding var isNonEmojiAttempt: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, isNonEmojiAttempt: $isNonEmojiAttempt)
    }

    func makeUIView(context: Context) -> UITextField {
        let field = EmojiOnlyTextField()
        field.placeholder = placeholder
        field.textAlignment = .left
        field.font = .preferredFont(forTextStyle: .body)
        field.adjustsFontForContentSizeCategory = true
        field.autocorrectionType = .no
        field.smartDashesType = .no
        field.smartQuotesType = .no
        field.delegate = context.coordinator
        field.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged(_:)), for: .editingChanged)
        return field
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text { uiView.text = text }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        @Binding var isNonEmojiAttempt: Bool
        init(text: Binding<String>, isNonEmojiAttempt: Binding<Bool>) {
            _text = text
            _isNonEmojiAttempt = isNonEmojiAttempt
        }

        @objc func editingChanged(_ sender: UITextField) {
            // Guarda só o primeiro caractere, que o delegate já garantiu ser um emoji.
            let value = sender.text ?? ""
            let trimmed = String(value.prefix(1))
            if sender.text != trimmed { sender.text = trimmed }
            if text != trimmed { text = trimmed }
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            if string.isEmpty {
                // Apagar é sempre permitido; também reseta o aviso de teclado.
                DispatchQueue.main.async { self.isNonEmojiAttempt = false }
                return true
            }
            guard string.count == 1, string.containsEmoji else {
                // Entrada rejeitada, provavelmente teclado de emoji desativado.
                DispatchQueue.main.async { self.isNonEmojiAttempt = true }
                return false
            }
            DispatchQueue.main.async { self.isNonEmojiAttempt = false }
            textField.text = string
            text = string
            // Fecha o teclado pra ficar natural, um emoji basta.
            textField.resignFirstResponder()
            return false
        }
    }

    /// UITextField que força o teclado de emoji via `textInputMode`.
    private final class EmojiOnlyTextField: UITextField {
        override var textInputContextIdentifier: String? { "" }
        override var textInputMode: UITextInputMode? {
            UITextInputMode.activeInputModes.first { $0.primaryLanguage == "emoji" }
        }
    }
}

private extension String {
    /// True quando a string contém pelo menos um scalar considerado emoji.
    var containsEmoji: Bool {
        contains { scalar in
            scalar.unicodeScalars.contains { $0.properties.isEmojiPresentation || $0.properties.isEmoji && $0.value > 0x238C }
        }
    }
}
#endif
