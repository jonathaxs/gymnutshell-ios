// ⌘
//  GymNutshell/GymNutshellApp/Views/WelcomeView/Steps/WelcomeAboutStep.swift
//
//  Propósito: Etapa "Sobre você" do onboarding: sexo (masculino/feminino) e exercício favorito.
//             O sexo define a coluna da tabela de metas, a cor de destaque e os emojis do app;
//             o exercício favorito é opcional e começa em "Não sei".
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-10-13.
// ⌘

import SwiftUI
import GymNutshellCore

/// Etapa do onboarding: os dois blocos do SexPicker e o menu de exercício favorito,
/// devolvidos via binding pra WelcomeView.
struct WelcomeAboutStep: View {

    @Binding var sex: String
    @Binding var favoriteExercise: FavoriteExercise
    var accentColor: Color = .accentColor
    var isWide: Bool = false

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    if !isWide {
                        WelcomeStepHeader(
                            emoji: "👤",
                            title: String(localized: "welcome.step.about.title", bundle: .gymNutshellCore),
                            accentColor: accentColor
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        AppSectionLabel(text: String(localized: "welcome.field.sex", bundle: .gymNutshellCore))
                        SexPicker(sex: $sex)
                    }

                    // Mesmo menu de Ajustes > Seus dados.
                    AppGroupedCard {
                        HStack {
                            Text(String(localized: "settings.profile.favoriteExercise", bundle: .gymNutshellCore))
                            Spacer()
                            Picker("", selection: $favoriteExercise) {
                                ForEach(FavoriteExercise.allCases) { exercise in
                                    Text(exercise.label).tag(exercise)
                                }
                            }
                            .labelsHidden()
                            .tint(accentColor)
                        }
                        .padding(.horizontal, 16)
                        .frame(minHeight: 52)
                    }
                }
                .padding(.horizontal, AppStyle.horizontalPadding)
                .padding(.vertical)
                .frame(maxWidth: .infinity, minHeight: isWide ? geo.size.height : 0, alignment: .center)
            }
        }
    }
}
