// ⌘
//  GymNutshell/GymNutshellApp/Views/Shared/UserGoalPickerView.swift
//
//  Propósito: Picker reutilizável baseado em cards pra selecionar um UserGoal.
//             Usado no WelcomeUserGoalStep (onboarding) e no UserGoalChangeView (settings).
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-11.
// ⌘

import SwiftUI
import GymNutshellCore

/// Exibe um card selecionável por opção de UserGoal.
/// O card selecionado é destacado e o binding é atualizado ao tocar.
struct UserGoalPickerView: View {

    @Binding var selection: UserGoal

    var body: some View {
        VStack(spacing: 12) {
            ForEach(UserGoal.allCases) { goal in
                goalCard(goal)
            }
        }
    }

    // MARK: - Card de objetivo

    private func goalCard(_ goal: UserGoal) -> some View {
        let isSelected = selection == goal

        let color = goalColor(goal)

        return Button {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.easeInOut(duration: 0.15)) {
                selection = goal
            }
        } label: {
            HStack(spacing: 14) {
                // Ícone do objetivo num quadrado arredondado com a cor do objetivo.
                Image(systemName: goalIcon(goal))
                    .font(.body.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(color, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.label)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(goalDescription(goal))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? color : Color.secondary.opacity(0.5))
                    .accessibilityHidden(true)
            }
            .padding()
            .appCard(isSelected: isSelected, accentColor: color)
            .contentShape(RoundedRectangle(cornerRadius: AppStyle.cardRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        // Combina nome + descrição num único label; estado de seleção entra no value.
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(goal.label + ", " + goalDescription(goal))
        .accessibilityValue(isSelected
                            ? String(localized: "a11y.selected", bundle: .gymNutshellCore)
                            : String(localized: "a11y.not.selected", bundle: .gymNutshellCore))
        .accessibilityHint(String(localized: "a11y.usergoal.hint", bundle: .gymNutshellCore))
    }

    private func goalColor(_ goal: UserGoal) -> Color {
        switch goal {
        case .bulking:     return .orange
        case .maintenance: return .accentColor
        case .cutting:     return .green
        }
    }

    private func goalIcon(_ goal: UserGoal) -> String {
        switch goal {
        case .bulking:     return "arrow.up.right"
        case .maintenance: return "equal"
        case .cutting:     return "arrow.down.right"
        }
    }

    private func goalDescription(_ goal: UserGoal) -> String {
        switch goal {
        case .bulking:      return String(localized: "welcome.goal.bulking.description", bundle: .gymNutshellCore)
        case .maintenance:  return String(localized: "welcome.goal.maintenance.description", bundle: .gymNutshellCore)
        case .cutting:      return String(localized: "welcome.goal.cutting.description", bundle: .gymNutshellCore)
        }
    }
}
