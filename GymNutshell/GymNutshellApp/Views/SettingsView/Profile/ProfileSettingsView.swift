// ⌘
//  GymNutshell/GymNutshellApp/Views/SettingsView/Profile/ProfileSettingsView.swift
//
//  Propósito: Permite ao usuário editar o nome, o sexo (masculino/feminino, define cor e emojis)
//             e o exercício favorito. Na 1.1 não existem mais dados físicos (peso, altura, idade).
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-10-08.
// ⌘

import SwiftUI
import GymNutshellCore

/// Tela de settings pra editar o perfil básico do usuário.
/// Salva ao sair da tela; trocar o sexo não mexe nas metas nem na cor de destaque.
struct ProfileSettingsView: View {

    @State private var name: String = ""
    @State private var sex: String = "male"
    // Easter egg, exercício/grupo muscular favorito.
    @AppStorage(UserProfile.favoriteExerciseKey) private var favoriteExerciseRaw: String = FavoriteExercise.unknown.rawValue

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Sexo: define a coluna da tabela de metas, a cor e os emojis do app.
                VStack(alignment: .leading, spacing: 8) {
                    AppSectionLabel(text: String(localized: "welcome.field.sex", bundle: .gymNutshellCore))
                    SexPicker(sex: $sex)
                }

                // Campos opcionais: nome e exercício favorito.
                VStack(alignment: .leading, spacing: 8) {
                    AppSectionLabel(text: String(localized: "settings.profile.section.optional", bundle: .gymNutshellCore))
                    AppGroupedCard(dividerInset: 16) {
                        LabeledContent(String(localized: "settings.profile.name", bundle: .gymNutshellCore)) {
                            TextField(String(localized: "settings.profile.name.placeholder", bundle: .gymNutshellCore), text: $name)
                                .multilineTextAlignment(.trailing)
                                .submitLabel(.done)
                        }
                        .padding(.horizontal, 16)
                        .frame(minHeight: 52)

                        HStack {
                            Text(String(localized: "settings.profile.favoriteExercise", bundle: .gymNutshellCore))
                            Spacer()
                            Picker("", selection: $favoriteExerciseRaw) {
                                ForEach(FavoriteExercise.allCases) { exercise in
                                    Text(exercise.label).tag(exercise.rawValue)
                                }
                            }
                            .labelsHidden()
                        }
                        .padding(.horizontal, 16)
                        .frame(minHeight: 52)
                    }
                }
            }
            .padding(.horizontal, AppStyle.horizontalPadding)
            .padding(.vertical)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(String(localized: "settings.section.physicaldata", bundle: .gymNutshellCore))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            let defaults = UserDefaults.standard
            name = defaults.string(forKey: UserProfile.nameKey) ?? ""
            sex = UserProfile.normalizedSex(defaults.string(forKey: UserProfile.sexKey) ?? "")
        }
        .onDisappear { save() }
    }

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(name.trimmingCharacters(in: .whitespacesAndNewlines), forKey: UserProfile.nameKey)
        defaults.set(sex, forKey: UserProfile.sexKey)
    }
}
