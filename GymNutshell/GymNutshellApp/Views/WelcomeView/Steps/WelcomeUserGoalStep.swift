// ⌘
//  GymNutshell/GymNutshellApp/Views/WelcomeView/Steps/WelcomeUserGoalStep.swift
//
//  Propósito: Etapa do onboarding, permite ao usuário escolher o sexo (masculino/feminino) e o
//             objetivo de fitness (bulking, manutenção ou cutting) via cards selecionáveis.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-10.
// ⌘

import SwiftUI
import GymNutshellCore

/// Etapa do onboarding: exibe um card pra cada opção de UserGoal.
/// O card selecionado fica destacado e é devolvido via binding pra WelcomeView.
/// A UI dos cards é gerenciada pela UserGoalPickerView compartilhada.
struct WelcomeUserGoalStep: View {

    @Binding var userGoal: UserGoal
    @Binding var sex: String
    var accentColor: Color = .accentColor
    var isWide: Bool = false

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    if !isWide {
                        WelcomeStepHeader(
                            emoji: "🎯",
                            title: String(localized: "welcome.step.goal.title", bundle: .gymNutshellCore),
                            subtitle: String(localized: "welcome.step.goal.info.choose", bundle: .gymNutshellCore),
                            accentColor: accentColor
                        )
                    }

                    // Seletor de sexo: define a coluna da tabela de metas, a cor e os emojis do app.
                    VStack(alignment: .leading, spacing: 8) {
                        WelcomeSectionLabel(text: String(localized: "welcome.field.sex", bundle: .gymNutshellCore))
                        HStack(spacing: 12) {
                            sexTile("female", icon: "figure.stand.dress",
                                    label: String(localized: "welcome.field.sex.female", bundle: .gymNutshellCore))
                            sexTile("male", icon: "figure.stand",
                                    label: String(localized: "welcome.field.sex.male", bundle: .gymNutshellCore))
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        WelcomeSectionLabel(text: String(localized: "welcome.field.goal", bundle: .gymNutshellCore))
                        UserGoalPickerView(selection: $userGoal)
                    }

                    Text(String(localized: "welcome.step.goal.info.editable", bundle: .gymNutshellCore))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, WelcomeStyle.horizontalPadding)
                .padding(.vertical)
                .frame(maxWidth: .infinity, minHeight: isWide ? geo.size.height : 0, alignment: .center)
            }
        }
    }

    // MARK: - Bloco de sexo

    private func sexTile(_ value: String, icon: String, label: String) -> some View {
        let isSelected = sex == value
        // A cor do bloco segue a cor que o app vai usar pra esse sexo.
        let tileColor = AppAccentColor.defaultForSex(value).color
        return VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(isSelected ? tileColor : .secondary)
                .accessibilityHidden(true)
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .welcomeCard(isSelected: isSelected, accentColor: tileColor)
        .contentShape(RoundedRectangle(cornerRadius: WelcomeStyle.cardRadius, style: .continuous))
        .tapButton {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.easeInOut(duration: 0.2)) { sex = value }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(isSelected
                            ? String(localized: "a11y.selected", bundle: .gymNutshellCore)
                            : String(localized: "a11y.not.selected", bundle: .gymNutshellCore))
    }
}
