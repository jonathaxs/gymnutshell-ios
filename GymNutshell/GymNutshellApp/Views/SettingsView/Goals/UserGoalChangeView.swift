// ⌘
//  GymNutshell/GymNutshellApp/Views/SettingsView/Goals/UserGoalChangeView.swift
//
//  Propósito: Permite ao usuário trocar o objetivo fitness principal e pré-visualizar
//             as novas metas calculadas antes de salvar. Só as 6 metas fixas são recalculadas;
//             as metas de rastreio personalizadas não são afetadas.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-11.
// ⌘

import SwiftUI
import GymNutshellCore

/// Tela de settings pra alterar o objetivo fitness principal (Bulking / Manutenção / Cutting).
/// Mostra uma prévia em tempo real das metas recalculadas assim que a seleção muda.
/// Salvar persiste o novo objetivo e atualiza os valores do GoalsProvider.
struct UserGoalChangeView: View {

    @Environment(\.dismiss) private var dismiss

    // MARK: - Sistema de medidas

    @AppStorage(UserProfile.measurementSystemKey) private var measurementSystem: MeasurementSystem = .metric

    // MARK: - Estado

    @State private var selectedGoal: UserGoal = .maintenance
    @State private var previewGoals: GoalsCalculator.Result? = nil

    // MARK: - Helpers

    // Sexo do perfil: define a coluna da tabela de metas padrão.
    private var sex: String { UserDefaults.standard.string(forKey: UserProfile.sexKey) ?? "male" }

    private var savedGoalRaw: String {
        UserDefaults.standard.string(forKey: UserProfile.userGoalKey) ?? UserGoal.maintenance.rawValue
    }

    // O botão Salvar só fica ativo se o usuário mudou a seleção de fato.
    private var hasChanged: Bool {
        selectedGoal.rawValue != savedGoalRaw
    }

    // MARK: - Body

    var body: some View {
        List {
            // Card picker pra selecionar o novo objetivo.
            // O footer explica que mudar o objetivo recalcula as métricas fixas do Gym Nutshell.
            Section {
                UserGoalPickerView(selection: $selectedGoal)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } header: {
                Text(String(localized: "settings.goalchange.section.pick", bundle: .gymNutshellCore))
            } footer: {
                Text(String(localized: "settings.goalchange.section.pick.footer", bundle: .gymNutshellCore))
            }

            // Seção de prévia: aparece assim que o usuário escolhe um objetivo diferente.
            if let goals = previewGoals {
                Section(String(localized: "settings.goalchange.section.preview", bundle: .gymNutshellCore)) {
                    // Água é exibida em fl oz pra usuários US, ml pra todo mundo.
                    let waterDisplay = measurementSystem == .us
                        ? "\(Int(UnitConverter.mlToFlOz(Double(goals.water)).rounded())) fl oz"
                        : "\(goals.water) ml"
                    LabeledContent(String(localized: "settings.goal.water", bundle: .gymNutshellCore),   value: waterDisplay)
                    LabeledContent(String(localized: "settings.goal.calories", bundle: .gymNutshellCore), value: "\(goals.calories) kcal")
                    LabeledContent(String(localized: "settings.goal.protein", bundle: .gymNutshellCore), value: "\(goals.protein) g")
                    LabeledContent(String(localized: "settings.goal.carbs", bundle: .gymNutshellCore),   value: "\(goals.carbs) g")
                    LabeledContent(String(localized: "settings.goal.fats", bundle: .gymNutshellCore),    value: "\(goals.goodFat) g")
                    LabeledContent(String(localized: "settings.goal.fiber", bundle: .gymNutshellCore),   value: "\(goals.fiber) g")
                }
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(String(localized: "settings.goalchange.title", bundle: .gymNutshellCore))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(String(localized: "settings.goalchange.save", bundle: .gymNutshellCore)) {
                    save()
                    dismiss()
                }
                .disabled(!hasChanged)
            }
        }
        .onAppear {
            // Carrega o objetivo salvo pra o picker refletir o estado real.
            selectedGoal = UserGoal(rawValue: savedGoalRaw) ?? .maintenance
        }
        .onChange(of: selectedGoal) { _, newGoal in
            // Recalcula e mostra a prévia só quando a seleção mudou de verdade.
            previewGoals = hasChanged
                ? GoalsCalculator.calculate(sex: sex, goal: newGoal)
                : nil
        }
    }

    // MARK: - Ações

    private func save() {
        guard let goals = previewGoals else { return }
        UserDefaults.standard.set(selectedGoal.rawValue, forKey: UserProfile.userGoalKey)
        GoalsProvider.save(goals)
    }
}
