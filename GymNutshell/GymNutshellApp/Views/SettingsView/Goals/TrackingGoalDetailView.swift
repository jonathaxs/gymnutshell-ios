// ⌘
//  GymNutshell/GymNutshellApp/Views/SettingsView/Goals/TrackingGoalDetailView.swift
//
//  Propósito: Edita o valor de uma única meta diária fixa (ex: Água, Proteína, Sono).
//             Lê o valor atual do UserDefaults e grava de volta quando o usuário salva.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-11.
// ⌘

import SwiftUI
import GymNutshellCore

/// Tela de detalhe pra editar uma meta fixa.
struct TrackingGoalDetailView: View {

    // MARK: - Configuração (passada pela TrackingGoalsSettingsView)

    let icon: String
    let title: String       // já localizado
    let unit: String
    let key: String         // chave do UserDefaults pra ler e escrever
    let fallback: Int       // valor usado se a chave nunca foi definida
    let increment: Int      // tamanho do passo pro Stepper

    @Environment(\.dismiss) private var dismiss

    // MARK: - Sistema de medidas

    @AppStorage(UserProfile.measurementSystemKey) private var measurementSystem: MeasurementSystem = .metric

    // Se essa meta precisa de conversão ml ↔ fl oz.
    private var isWaterImperial: Bool {
        key == "tracking.water" && measurementSystem == .us
    }

    // MARK: - Estado

    @State private var value: Int = 0
    @State private var currentIncrement: Int = 0

    // MARK: - Body

    var body: some View {
        Form {
            Section {
                stepRow(title: String(localized: "settings.goaldetail.stepper", bundle: .gymNutshellCore),
                        valueText: "\(value) \(unit)",
                        canDecrease: value - currentIncrement >= currentIncrement,
                        canIncrease: value + currentIncrement <= 99999,
                        onDecrease: { value -= currentIncrement },
                        onIncrease: { value += currentIncrement })

                stepRow(title: String(localized: "settings.goaldetail.increment.stepper", bundle: .gymNutshellCore),
                        valueText: "\(currentIncrement) \(unit)",
                        canDecrease: currentIncrement > 1,
                        canIncrease: currentIncrement < 99999,
                        onDecrease: { currentIncrement -= 1 },
                        onIncrease: { currentIncrement += 1 })
            } footer: {
                Text(String(localized: "settings.goaldetail.footer", bundle: .gymNutshellCore))
                + Text("\n")
                + Text(String(localized: "settings.goaldetail.increment.footer", bundle: .gymNutshellCore))
            }
        }
        .scrollContentBackground(.hidden)
        .frame(maxWidth: 600)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("\(icon) \(title)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(String(localized: "settings.goaldetail.save", bundle: .gymNutshellCore)) {
                    save()
                    dismiss()
                }
                .disabled(value < currentIncrement || currentIncrement < 1)
            }
        }
        .onAppear {
            load()
        }
    }

    // MARK: - Linha com − / +

    private func stepRow(title: String, valueText: String, canDecrease: Bool, canIncrease: Bool,
                         onDecrease: @escaping () -> Void, onIncrease: @escaping () -> Void) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(valueText)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: 8)
            RoundStepButton(kind: .minus, size: 46, isEnabled: canDecrease, action: onDecrease)
                .accessibilityLabel(String(format: String(localized: "a11y.welcome.goal.decrease.format", bundle: .gymNutshellCore), title))
            RoundStepButton(kind: .plus, size: 46, isEnabled: canIncrease, action: onIncrease)
                .accessibilityLabel(String(format: String(localized: "a11y.welcome.goal.increase.format", bundle: .gymNutshellCore), title))
        }
        .buttonStyle(.borderless)
    }

    // MARK: - Carregar / Salvar

    private func load() {
        let stored = UserDefaults.standard.integer(forKey: key)
        let rawValue = stored > 0 ? stored : fallback
        if isWaterImperial {
            value = Int(UnitConverter.mlToFlOz(Double(rawValue)).rounded())
        } else {
            value = rawValue
        }
        let storedIncrement = UserDefaults.standard.integer(forKey: "\(key).increment")
        currentIncrement = storedIncrement > 0 ? storedIncrement : increment
    }

    private func save() {
        if isWaterImperial {
            UserDefaults.standard.set(Int(UnitConverter.flOzToMl(Double(value)).rounded()), forKey: key)
        } else {
            UserDefaults.standard.set(value, forKey: key)
        }
        UserDefaults.standard.set(currentIncrement, forKey: "\(key).increment")
    }
}
