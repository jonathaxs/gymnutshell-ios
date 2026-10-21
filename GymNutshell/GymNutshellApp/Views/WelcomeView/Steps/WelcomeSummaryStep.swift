// ⌘
//  GymNutshell/GymNutshellApp/Views/WelcomeView/Steps/WelcomeSummaryStep.swift
//
//  Propósito: Etapa do onboarding, exibe as metas diárias padrão organizadas por categoria, com
//             botões − / + pra ajustar cada valor, e permite adicionar opcionalmente Gordura e Creatina.
//             O aviso de que dá pra editar depois aparece no fim, depois das metas opcionais.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-10.
// ⌘

import SwiftUI
import GymNutshellCore

/// Última etapa do onboarding: mostra as metas organizadas por categoria.
/// Fixas têm − / +; opcionais têm Adicionar e, depois de adicionadas, − / + e a lixeira na mesma linha.
struct WelcomeSummaryStep: View {

    @Binding var goals: GoalsCalculator.Result?
    let measurementSystem: MeasurementSystem
    let accentColor: Color
    @Binding var includeFats: Bool
    @Binding var includeCreatine: Bool
    @Binding var scrolledToEnd: Bool
    var isWide: Bool = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {

                if !isWide {
                    WelcomeStepHeader(
                        emoji: "💪",
                        title: String(localized: "welcome.step.summary.title", bundle: .gymNutshellCore),
                        accentColor: accentColor
                    )
                }

                if let goals {

                    // MARK: Essencial
                    summaryCategory(GoalCategory.essencial) {
                        adjustableRow(icon: "💤", label: String(localized: "today.metric.sleep", bundle: .gymNutshellCore),
                                      keyPath: \.sleep, step: 1, range: 1...16) { "\($0)h" }
                        adjustableRow(icon: "💧", label: String(localized: "today.metric.water", bundle: .gymNutshellCore),
                                      keyPath: \.water, step: 250, range: 250...10000) {
                            measurementSystem == .us
                                ? "\(Int(UnitConverter.mlToFlOz(Double($0)).rounded())) fl oz"
                                : "\($0) ml"
                        }
                    }

                    // MARK: Nutrição
                    summaryCategory(GoalCategory.nutricao) {
                        adjustableRow(icon: "🍗", label: String(localized: "today.metric.protein", bundle: .gymNutshellCore),
                                      keyPath: \.protein, step: 5, range: 10...500) { "\($0)g" }
                        adjustableRow(icon: "🍞", label: String(localized: "today.metric.carbs", bundle: .gymNutshellCore),
                                      keyPath: \.carbs, step: 10, range: 10...1000) { "\($0)g" }
                        adjustableRow(icon: "🌾", label: String(localized: "today.metric.fiber", bundle: .gymNutshellCore),
                                      keyPath: \.fiber, step: 1, range: 5...100) { "\($0)g" }
                        OptionalTrackingGoalRow(
                            icon: "🧈",
                            label: String(localized: "today.metric.fats", bundle: .gymNutshellCore),
                            value: "\(goals.goodFat)g",
                            accentColor: accentColor,
                            isIncluded: $includeFats,
                            canDecrease: goals.goodFat - 5 >= 5,
                            canIncrease: goals.goodFat + 5 <= 300,
                            onDecrease: { adjust(\.goodFat, by: -5, range: 5...300) },
                            onIncrease: { adjust(\.goodFat, by: 5, range: 5...300) }
                        )
                    }

                    // MARK: Treino
                    summaryCategory(GoalCategory.treino) {
                        adjustableRow(icon: "🏋️", label: String(localized: "today.goals.workout", bundle: .gymNutshellCore),
                                      keyPath: \.workout, step: 15, range: 5...300) { "\($0) min" }
                        adjustableRow(icon: "🏃", label: String(localized: "today.goals.cardio", bundle: .gymNutshellCore),
                                      keyPath: \.cardio, step: 5, range: 5...180) { "\($0) min" }
                    }

                    // MARK: Suplemento
                    summaryCategory(GoalCategory.suplemento) {
                        OptionalTrackingGoalRow(
                            icon: "🧪",
                            label: String(localized: "today.goals.creatine", bundle: .gymNutshellCore),
                            value: "\(goals.creatine)g",
                            accentColor: accentColor,
                            isIncluded: $includeCreatine,
                            canDecrease: goals.creatine - 1 >= 1,
                            canIncrease: goals.creatine + 1 <= 20,
                            onDecrease: { adjust(\.creatine, by: -1, range: 1...20) },
                            onIncrease: { adjust(\.creatine, by: 1, range: 1...20) }
                        )
                    }

                    // Rodapé informativo, centralizado para alinhar com as metas.
                    // Sentinela de scroll fica dentro do VStack pra reduzir o espaçamento após a creatina.
                    VStack(alignment: .center, spacing: 10) {
                        Color.clear.frame(height: 1)
                            .onAppear { scrolledToEnd = true }

                        Text(String(localized: "welcome.summary.subtitle.customize", bundle: .gymNutshellCore))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.top, -12)
                }
            }
            .padding(.horizontal, AppStyle.horizontalPadding)
            .padding(.vertical)
        }
        // Botões − / + seguem a cor de destaque.
        .tint(accentColor)
    }

    // MARK: - Seção de categoria (não colapsável no onboarding)

    private func summaryCategory<Content: View>(
        _ category: GoalCategory,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            AppSectionLabel(text: category.displayName)
            AppGroupedCard {
                content()
            }
        }
    }

    // MARK: - Ajuste de valor

    /// Soma `delta` ao campo da meta, respeitando os limites.
    private func adjust(_ keyPath: WritableKeyPath<GoalsCalculator.Result, Int>, by delta: Int, range: ClosedRange<Int>) {
        guard var current = goals else { return }
        current[keyPath: keyPath] = min(max(current[keyPath: keyPath] + delta, range.lowerBound), range.upperBound)
        goals = current
        UISelectionFeedbackGenerator().selectionChanged()
    }

    // MARK: - Linha de meta ajustável com − / +

    private func adjustableRow(
        icon: String,
        label: String,
        keyPath: WritableKeyPath<GoalsCalculator.Result, Int>,
        step: Int,
        range: ClosedRange<Int>,
        format: (Int) -> String
    ) -> some View {
        let value = goals?[keyPath: keyPath] ?? 0
        return HStack(spacing: 12) {
            Text(icon)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(label)
                .font(.subheadline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 4)
            GoalStepper(
                valueText: format(value),
                label: label,
                color: accentColor,
                canDecrease: value - step >= range.lowerBound,
                canIncrease: value + step <= range.upperBound,
                onDecrease: { adjust(keyPath, by: -step, range: range) },
                onIncrease: { adjust(keyPath, by: step, range: range) }
            )
        }
        .padding(.leading, 16)
        .padding(.trailing, 12)
        .frame(minHeight: 60)
    }

}

// MARK: - Controle − / + de uma meta

private struct GoalStepper: View {

    let valueText: String
    let label: String
    /// Cor do objetivo escolhido (− / + pintados com ela).
    let color: Color
    let canDecrease: Bool
    let canIncrease: Bool
    let onDecrease: () -> Void
    let onIncrease: () -> Void
    /// Metas opcionais: lixeira entre o valor e o −, pra o − / + ficarem alinhados com os das metas fixas.
    var onRemove: (() -> Void)? = nil
    /// Metas opcionais: false = valor e botões encolhidos e invisíveis. Ao virar true eles surgem um a um
    /// (valor, lixeira, −, +); ao voltar pra false somem na ordem inversa.
    var revealed: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 8) {
            reveal(index: 0) {
                Text(valueText)
                    .font(.subheadline.bold())
                    .monospacedDigit()
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.trailing, 4)
                    .accessibilityLabel(label)
                    .accessibilityValue(valueText)
            }

            if let onRemove {
                reveal(index: 1) {
                    RoundStepButton(kind: .trash, size: 46, color: .red, action: onRemove)
                        .accessibilityLabel(String(format: String(localized: "a11y.welcome.optional.remove.label.format",
                                                                  bundle: .gymNutshellCore), label))
                        .accessibilityHint(String(localized: "a11y.welcome.optional.remove.hint", bundle: .gymNutshellCore))
                }
            }

            reveal(index: 2) {
                RoundStepButton(kind: .minus, size: 46, color: color, isEnabled: canDecrease, action: onDecrease)
                    .accessibilityLabel(String(format: String(localized: "a11y.welcome.goal.decrease.format", bundle: .gymNutshellCore), label))
            }
            reveal(index: 3) {
                RoundStepButton(kind: .plus, size: 46, color: color, isEnabled: canIncrease, action: onIncrease)
                    .accessibilityLabel(String(format: String(localized: "a11y.welcome.goal.increase.format", bundle: .gymNutshellCore), label))
            }
        }
    }

    /// Cada peça surge com uma mola, um pouco depois da anterior; some na ordem inversa.
    private func reveal<Content: View>(index: Int, @ViewBuilder content: () -> Content) -> some View {
        let delay = revealed ? Double(index) * 0.06 : Double(3 - index) * 0.04
        return content()
            .scaleEffect(revealed || reduceMotion ? 1 : 0.3)
            .opacity(revealed ? 1 : 0)
            .animation(reduceMotion ? .easeInOut(duration: 0.2)
                                    : .spring(response: 0.38, dampingFraction: 0.68).delay(delay),
                       value: revealed)
    }
}

// MARK: - Linha de meta de rastreio opcional

/// Fora da lista: nome + Adicionar, sem o valor. Na lista, tudo na mesma linha das metas fixas:
/// valor, lixeira vermelha (mesmo círculo de vidro) e − / +, alinhados com os das metas fixas.
private struct OptionalTrackingGoalRow: View {

    let icon: String
    let label: String
    let value: String
    let accentColor: Color
    @Binding var isIncluded: Bool
    let canDecrease: Bool
    let canIncrease: Bool
    let onDecrease: () -> Void
    let onIncrease: () -> Void

    /// Valor e botões já visíveis (separado de isIncluded pra animar a entrada e a saída em etapas).
    @State private var buttonsShown = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .frame(width: 24)
                .accessibilityHidden(true)

            // Sem Spacer: o nome ocupa a sobra da linha e só encolhe a fonte quando falta espaço
            // (com os 3 botões e "100g" a linha fica apertada nos iPhones mais estreitos).
            Text(label)
                .font(.subheadline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .leading)

            if isIncluded {
                GoalStepper(
                    valueText: value,
                    label: label,
                    color: accentColor,
                    canDecrease: canDecrease,
                    canIncrease: canIncrease,
                    onDecrease: onDecrease,
                    onIncrease: onIncrease,
                    onRemove: { setIncluded(false) },
                    revealed: buttonsShown
                )
            } else {
                addButton
                    .transition(reduceMotion ? .opacity
                                             : .scale(scale: 0.5, anchor: .trailing).combined(with: .opacity))
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 12)
        .frame(minHeight: 60)
        // Voltando pra esta etapa com a meta já incluída: botões visíveis, sem animar.
        .onAppear { buttonsShown = isIncluded }
    }

    /// Adicionar: o botão encolhe e some, e valor, lixeira, − e + surgem um a um no lugar dele.
    /// Lixeira: o caminho inverso, as peças somem da direita pra esquerda e o Adicionar volta crescendo.
    private func setIncluded(_ included: Bool) {
        UISelectionFeedbackGenerator().selectionChanged()
        if included {
            withAnimation(.snappy(duration: 0.25)) { isIncluded = true }
            DispatchQueue.main.async { buttonsShown = true }
        } else {
            buttonsShown = false
            DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.15 : 0.28)) {
                withAnimation(reduceMotion ? .easeInOut(duration: 0.2)
                                           : .spring(response: 0.4, dampingFraction: 0.72)) {
                    isIncluded = false
                }
            }
        }
    }

    private var addButton: some View {
        Button { setIncluded(true) } label: {
            Label(String(localized: "welcome.option.add", bundle: .gymNutshellCore), systemImage: "plus")
                .font(.subheadline.weight(.semibold))
        }
        .appProminentButton(accentColor, size: .regular)
        .accessibilityLabel(String(format: String(localized: "a11y.welcome.optional.add.label.format",
                                                  bundle: .gymNutshellCore), label))
        .accessibilityHint(String(localized: "a11y.welcome.optional.add.hint", bundle: .gymNutshellCore))
    }
}
