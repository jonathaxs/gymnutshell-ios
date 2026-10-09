// ⌘
//  GymNutshell/GymNutshellApp/Views/SettingsView/Goals/UserGoalChangeView.swift
//
//  Propósito: Permite ao usuário trocar o objetivo fitness principal. As metas de calorias, proteína,
//             carboidrato, gordura boa e fibra podem ser recalculadas na mesma proporção da tabela
//             (a partir dos valores atuais, que ele pode ter personalizado) ou mantidas como estão.
//             Água, sono, treino, cardio, creatina e metas personalizadas nunca mudam.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-11.
// ⌘

import SwiftUI
import GymNutshellCore

/// Tela de settings pra alterar o objetivo fitness principal (Bulking / Manutenção / Cutting).
/// Mostra uma prévia "atual → nova" por meta e dois botões: salvar e recalcular, ou só trocar o objetivo.
struct UserGoalChangeView: View {

    @Environment(\.dismiss) private var dismiss

    // MARK: - Cor de destaque

    @AppStorage(AppAccentColor.storageKey) private var storedColorRaw: String = AppAccentColor.blue.rawValue
    private var accentColor: Color { (AppAccentColor(rawValue: storedColorRaw) ?? .blue).color }

    // MARK: - Estado

    @State private var selectedGoal: UserGoal = .maintenance

    // MARK: - Helpers

    // Sexo do perfil: define a coluna da tabela de metas padrão.
    private var sex: String { UserDefaults.standard.string(forKey: UserProfile.sexKey) ?? "male" }

    private var savedGoalRaw: String {
        UserDefaults.standard.string(forKey: UserProfile.userGoalKey) ?? UserGoal.maintenance.rawValue
    }

    // Objetivo salvo (vazio ou desconhecido = manutenção).
    private var savedGoal: UserGoal { UserGoal(rawValue: savedGoalRaw) ?? .maintenance }

    // Os botões só ficam ativos se o usuário mudou a seleção de fato.
    private var hasChanged: Bool { selectedGoal != savedGoal }

    private var currentGoals: GoalsCalculator.Result { GoalsProvider.current }

    private var rescaledGoals: GoalsCalculator.Result {
        GoalsCalculator.rescale(current: currentGoals, sex: sex, from: savedGoal, to: selectedGoal)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                VStack(alignment: .leading, spacing: 8) {
                    AppSectionLabel(text: String(localized: "settings.goalchange.section.pick", bundle: .gymNutshellCore))
                    UserGoalPickerView(selection: $selectedGoal)
                    Text(String(localized: "settings.goalchange.section.pick.footer", bundle: .gymNutshellCore))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                }

                // Prévia: aparece assim que o usuário escolhe um objetivo diferente.
                if hasChanged {
                    VStack(alignment: .leading, spacing: 8) {
                        AppSectionLabel(text: String(localized: "settings.goalchange.section.preview", bundle: .gymNutshellCore))
                        AppGroupedCard(dividerInset: 16) {
                            previewRow("settings.goal.calories", \.calories, unit: " kcal")
                            previewRow("settings.goal.protein", \.protein, unit: " g")
                            previewRow("settings.goal.carbs", \.carbs, unit: " g")
                            previewRow("settings.goal.fats", \.goodFat, unit: " g")
                            previewRow("settings.goal.fiber", \.fiber, unit: " g")
                        }
                    }
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, AppStyle.horizontalPadding)
            .padding(.vertical)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
            .animation(.easeInOut(duration: 0.2), value: hasChanged)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .safeAreaInset(edge: .bottom) { actionButtons }
        .navigationTitle(String(localized: "settings.goalchange.title", bundle: .gymNutshellCore))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Carrega o objetivo salvo pra o picker refletir o estado real.
            selectedGoal = savedGoal
        }
    }

    // MARK: - Prévia

    /// Linha "Calorias   2650 → 3050 kcal  +15%".
    private func previewRow(_ labelKey: String, _ keyPath: KeyPath<GoalsCalculator.Result, Int>, unit: String) -> some View {
        let old = currentGoals[keyPath: keyPath]
        let new = rescaledGoals[keyPath: keyPath]
        let percent = old > 0 ? Int((Double(new - old) / Double(old) * 100).rounded()) : 0
        let percentText = percent == 0 ? "0%" : String(format: "%+d%%", percent)
        let percentColor: Color = percent > 0 ? .green : (percent < 0 ? .orange : .secondary)
        return HStack(spacing: 8) {
            Text(NSLocalizedString(labelKey, bundle: .gymNutshellCore, comment: ""))
            Spacer(minLength: 8)
            Text("\(old) → \(new)\(unit)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
            Text(percentText)
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(percentColor)
                .frame(minWidth: 40, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 48)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Botões

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                save(recalculate: true)
            } label: {
                Text(String(localized: "settings.goalchange.save.recalc", bundle: .gymNutshellCore))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .appProminentButton(accentColor)

            Button {
                save(recalculate: false)
            } label: {
                Text(String(localized: "settings.goalchange.save.keep", bundle: .gymNutshellCore))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .appSecondaryButton(accentColor)
        }
        .disabled(!hasChanged)
        .padding(.horizontal, AppStyle.horizontalPadding)
        .padding(.vertical, 12)
        .frame(maxWidth: 600)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Ações

    private func save(recalculate: Bool) {
        guard hasChanged else { return }
        let newGoals = rescaledGoals
        UserDefaults.standard.set(selectedGoal.rawValue, forKey: UserProfile.userGoalKey)
        if recalculate { GoalsProvider.save(newGoals) }
        dismiss()
    }
}
