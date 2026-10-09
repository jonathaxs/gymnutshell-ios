// ⌘
//  GymNutshell/GymNutshellApp/Views/WelcomeView/Steps/WelcomeSummaryStep.swift
//
//  Propósito: Etapa do onboarding, exibe as metas diárias padrão organizadas por categoria, com
//             botões − / + pra ajustar cada valor, e permite adicionar opcionalmente Gordura e Creatina.
//             Os parágrafos informativos aparecem no fim, depois das metas opcionais.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-10.
// ⌘

import SwiftUI
import GymNutshellCore

/// Última etapa do onboarding: mostra as metas organizadas por categoria.
/// Fixas aparecem como linhas informativas; opcionais têm botão Adicionar/Remover.
struct WelcomeSummaryStep: View {

    @Binding var goals: GoalsCalculator.Result?
    let measurementSystem: MeasurementSystem
    let userGoal: UserGoal
    let accentColor: Color
    @Binding var includeFats: Bool
    @Binding var includeCreatine: Bool
    @Binding var scrolledToEnd: Bool
    var isWide: Bool = false

    private var goalColor: Color {
        switch userGoal {
        case .bulking:     return .orange
        case .maintenance: return .blue
        case .cutting:     return .green
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {

                if !isWide {
                    WelcomeStepHeader(
                        emoji: "✅",
                        title: String(localized: "welcome.step.summary.title", bundle: .gymNutshellCore),
                        subtitle: String(localized: "welcome.step.summary.subtitle", bundle: .gymNutshellCore),
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
                        adjustableRow(icon: "🔥", label: String(localized: "today.metric.calories", bundle: .gymNutshellCore),
                                      keyPath: \.calories, step: 50, range: 500...10000) { "\($0) kcal" }
                        adjustableRow(icon: "🍗", label: String(localized: "today.metric.protein", bundle: .gymNutshellCore),
                                      keyPath: \.protein, step: 5, range: 10...500) { "\($0)g" }
                        adjustableRow(icon: "🌾", label: String(localized: "today.metric.fiber", bundle: .gymNutshellCore),
                                      keyPath: \.fiber, step: 1, range: 5...100) { "\($0)g" }
                        adjustableRow(icon: "🍞", label: String(localized: "today.metric.carbs", bundle: .gymNutshellCore),
                                      keyPath: \.carbs, step: 10, range: 10...1000) { "\($0)g" }
                        OptionalTrackingGoalRow(
                            icon: "🧈",
                            label: String(localized: "today.metric.fats", bundle: .gymNutshellCore),
                            value: "\(goals.goodFat)g",
                            accentColor: accentColor,
                            isIncluded: $includeFats,
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
                            onDecrease: { adjust(\.creatine, by: -1, range: 1...20) },
                            onIncrease: { adjust(\.creatine, by: 1, range: 1...20) }
                        )
                    }

                    // Rodapé informativo, centralizado para alinhar com as metas.
                    // Sentinela de scroll fica dentro do VStack pra reduzir o espaçamento após a creatina.
                    VStack(alignment: .center, spacing: 10) {
                        Color.clear.frame(height: 1)
                            .onAppear { scrolledToEnd = true }

                        (Text(String(localized: "welcome.summary.subtitle.calculated.prefix", bundle: .gymNutshellCore))
                         + Text(userGoal.label).fontWeight(.semibold)
                         + Text(String(localized: "welcome.summary.subtitle.calculated.suffix", bundle: .gymNutshellCore)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)

                        Text(String(localized: "welcome.summary.subtitle.customize", bundle: .gymNutshellCore))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.top, -12)
                }
            }
            .padding(.horizontal, WelcomeStyle.horizontalPadding)
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
            WelcomeSectionLabel(text: category.displayName)
            WelcomeGroupedCard {
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
                canDecrease: value - step >= range.lowerBound,
                canIncrease: value + step <= range.upperBound,
                onDecrease: { adjust(keyPath, by: -step, range: range) },
                onIncrease: { adjust(keyPath, by: step, range: range) }
            )
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .frame(minHeight: 52)
    }

}

// MARK: - Controle − / + de uma meta

private struct GoalStepper: View {

    let valueText: String
    let label: String
    let canDecrease: Bool
    let canIncrease: Bool
    let onDecrease: () -> Void
    let onIncrease: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onDecrease) {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .frame(minWidth: 40, minHeight: 44)
            }
            .disabled(!canDecrease)
            .accessibilityLabel(String(format: String(localized: "a11y.welcome.goal.decrease.format", bundle: .gymNutshellCore), label))

            Text(valueText)
                .font(.subheadline.bold())
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize()
                .frame(minWidth: 64)
                .accessibilityLabel(label)
                .accessibilityValue(valueText)

            Button(action: onIncrease) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .frame(minWidth: 40, minHeight: 44)
            }
            .disabled(!canIncrease)
            .accessibilityLabel(String(format: String(localized: "a11y.welcome.goal.increase.format", bundle: .gymNutshellCore), label))
        }
        .buttonStyle(.borderless)
    }
}

// MARK: - Linha de meta de rastreio opcional

private struct OptionalTrackingGoalRow: View {

    let icon: String
    let label: String
    let value: String
    let accentColor: Color
    @Binding var isIncluded: Bool
    let onDecrease: () -> Void
    let onIncrease: () -> Void

    @State private var buttonScale: CGFloat = 1.0

    var body: some View {
        HStack {
            // Bloco informativo (emoji + nome + badge + valor) combina num único
            // elemento de a11y; botão Add/Remove fica FORA do combine pra ser
            // focável separadamente (mesmo padrão do TrackingGoalRow do Today).
            HStack(spacing: 12) {
                Text(icon)
                    .frame(width: 24)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.subheadline)
                    Text(String(localized: "welcome.summary.optional.badge", bundle: .gymNutshellCore))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(Capsule())
                }
                Spacer()
                Text(value)
                    .font(isIncluded ? .subheadline.bold() : .subheadline)
                    .foregroundStyle(.primary)
                    .monospacedDigit()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityValue(value)

            // − / + só aparecem quando a meta opcional está incluída.
            if isIncluded {
                HStack(spacing: 0) {
                    Button(action: onDecrease) {
                        Image(systemName: "minus.circle.fill").font(.title2).symbolRenderingMode(.hierarchical).frame(minWidth: 40, minHeight: 44)
                    }
                    .accessibilityLabel(String(format: String(localized: "a11y.welcome.goal.decrease.format", bundle: .gymNutshellCore), label))
                    Button(action: onIncrease) {
                        Image(systemName: "plus.circle.fill").font(.title2).symbolRenderingMode(.hierarchical).frame(minWidth: 40, minHeight: 44)
                    }
                    .accessibilityLabel(String(format: String(localized: "a11y.welcome.goal.increase.format", bundle: .gymNutshellCore), label))
                }
                .buttonStyle(.borderless)
            }

            Button {
                UISelectionFeedbackGenerator().selectionChanged()
                withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                    buttonScale = 1.4
                }
                withAnimation(.spring(response: 0.25, dampingFraction: 0.5).delay(0.12)) {
                    buttonScale = 1.0
                }
                isIncluded.toggle()
            } label: {
                Text(isIncluded
                     ? String(localized: "welcome.option.remove", bundle: .gymNutshellCore)
                     : String(localized: "welcome.option.add", bundle: .gymNutshellCore))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isIncluded ? .red : accentColor)
                    .scaleEffect(buttonScale)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(format: String(localized: isIncluded
                ? "a11y.welcome.optional.remove.label.format"
                : "a11y.welcome.optional.add.label.format", bundle: .gymNutshellCore), label))
            .accessibilityHint(String(localized: isIncluded
                ? "a11y.welcome.optional.remove.hint"
                : "a11y.welcome.optional.add.hint", bundle: .gymNutshellCore))
        }
        .padding(.leading, 16)
        .padding(.trailing, 12)
        .padding(.vertical, 8)
        .frame(minHeight: 52)
    }
}
