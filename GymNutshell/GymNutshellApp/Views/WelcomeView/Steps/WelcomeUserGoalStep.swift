// ⌘
//  GymNutshell/GymNutshellApp/Views/WelcomeView/Steps/WelcomeUserGoalStep.swift
//
//  Propósito: Etapa do onboarding, permite ao usuário escolher o objetivo de fitness
//             (bulking, manutenção ou cutting) via cards selecionáveis. O sexo fica na etapa anterior.
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
                            accentColor: accentColor
                        )
                    }

                    UserGoalPickerView(selection: $userGoal)

                    Text(String(localized: "welcome.step.goal.info.editable", bundle: .gymNutshellCore))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, AppStyle.horizontalPadding)
                .padding(.vertical)
                .frame(maxWidth: .infinity, minHeight: isWide ? geo.size.height : 0, alignment: .center)
            }
        }
    }
}
