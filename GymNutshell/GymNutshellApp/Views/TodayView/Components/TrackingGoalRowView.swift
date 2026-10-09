// ⌘
//  GymNutshell/GymNutshellApp/Views/TodayView/Components/TrackingGoalRowView.swift
//
//  Propósito: Linha em estilo de card pras metas de rastreio (acumulação numérica).
//             Mostra um slider pra entrada. Os tons de cor refletem o nível de progresso.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-19.
// ⌘

import SwiftUI
import GymNutshellCore

// MARK: - TrackingGoalRowView

// Uma meta de rastreio: card com tint colorido pelo progresso e um slider.
// Cor muda de vermelho→laranja→verde→azul conforme o usuário se aproxima da meta diária.
struct TrackingGoalRowView: View {

    let emoji: String
    let title: String
    let unit: String
    let increment: Int
    let goal: Int
    @Binding var value: Int

    // Quando não-nil, exibe botão OFF/ON à esquerda do valor (usado por Musculação/Cardio).
    // ON = dia de descanso: slider é substituído por texto "Dia de descanso" e conta como meta cumprida.
    var isRestDay: Binding<Bool>? = nil

    // Estilo global dos controles (slider ou − / +), escolhido na Welcome e editável em Ajustes.
    @AppStorage(ControlStyle.storageKey) private var controlStyleRaw: String = ControlStyle.default.rawValue
    private var controlStyle: ControlStyle { ControlStyle(rawValue: controlStyleRaw) ?? .default }

    @AppStorage(AppAccentColor.storageKey) private var storedColorRaw: String = AppAccentColor.blue.rawValue
    private var accentColor: Color { (AppAccentColor(rawValue: storedColorRaw) ?? .blue).color }

    // MARK: - Valores derivados

    private var safeGoal: Int { max(goal, 0) }
    private var safeStep: Int { max(increment, 1) }

    private var clampedProgress: Double {
        guard safeGoal > 0 else { return 0 }
        return min(Double(value) / Double(safeGoal), 1)
    }

    // MARK: - Cores baseadas no progresso

    private var progressTint: Color {
        ProgressColors.ring(for: clampedProgress)
    }

    // MARK: - Binding do slider

    // Faz a ponte entre o valor Int e o slider Double.
    // Encaixa nos passos de `increment`, limita em [0, goal], dispara haptic e anima.
    private var sliderBinding: Binding<Double> {
        Binding(
            get: { Double(value) },
            set: { newDouble in
                let clamped = snap(toNearest: newDouble)
                guard clamped != value else { return }
                UISelectionFeedbackGenerator().selectionChanged()
                withAnimation(.easeInOut(duration: 0.12)) {
                    value = clamped
                }
            }
        )
    }

    /// Snap pro alvo válido mais próximo.
    /// Inclui múltiplos do incremento até `safeGoal` E o próprio `safeGoal`, sem isso,
    /// metas que não são múltiplas do incremento (ex: 50 com passo 15) ficam inalcançáveis,
    /// porque o último múltiplo ≤ goal seria 45 e o slider clampa em goal.
    private func snap(toNearest raw: Double) -> Int {
        var targets = stride(from: 0, through: safeGoal, by: safeStep).map { $0 }
        if targets.last != safeGoal { targets.append(safeGoal) }
        let best = targets.min(by: { abs(Double($0) - raw) < abs(Double($1) - raw) }) ?? 0
        return min(max(best, 0), safeGoal)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // Cabeçalho. Estrutura intencional:
            //   1. HStack interno (emoji + título + valor textual) é combinado num
            //      único elemento de a11y, "Meta Água, 30 de 100 ml concluído".
            //   2. Botão rest day fica FORA desse subtree, como elemento focável
            //      independente, com seu próprio label (texto visível "ON"/"OFF")
            //      e hint. Sem isso, o botão era absorvido e virava "rotor action".
            HStack(alignment: .center, spacing: 6) {
                HStack(alignment: .center, spacing: 6) {
                    Text(emoji)
                        .font(.headline)
                        .accessibilityHidden(true)
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                        .layoutPriority(1)
                    Spacer(minLength: 6)
                    Text("\(value) / \(safeGoal) \(unit)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(String(format: String(localized: "a11y.goalrow.a11y.label",
                                                         bundle: .gymNutshellCore), title))
                .accessibilityValue(
                    isRestDay?.wrappedValue == true
                    ? A11y.goalRowRestDayValue()
                    : A11y.goalRowValue(current: value, goal: safeGoal, unit: unit)
                )

                if let rest = isRestDay {
                    restDayToggle(isOn: rest)
                }
            }

            // Dia de descanso: substitui o slider por um texto centralizado.
            if isRestDay?.wrappedValue == true {
                Text(String(localized: "today.restday.label", bundle: .gymNutshellCore))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 6)
                    // Já comunicado pelo value do header, esconde para não
                    // duplicar "dia de descanso" no VoiceOver.
                    .accessibilityHidden(true)
            } else if safeGoal > 0 {
                // Slider tem seu próprio label/value. Sem hint custom: o sistema
                // já anuncia "ajustável, deslize para cima ou para baixo".
                if controlStyle == .stepper {
                    stepperControl
                } else {
                    Slider(
                        value: sliderBinding,
                        in: 0...Double(safeGoal)
                    )
                    .tint(progressTint)
                    .accessibilityLabel(A11y.sliderLabel(for: title))
                    .accessibilityValue(A11y.goalRowValue(current: value, goal: safeGoal, unit: unit))
                }
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Controle − / +

    /// Alternativa ao slider: barra de progresso à esquerda e os botões − / + juntos à direita.
    /// Cada toque anda um passo (`increment`), sempre dentro de [0, goal].
    private var stepperControl: some View {
        HStack(spacing: 14) {
            ProgressView(value: clampedProgress)
                .tint(progressTint)
                .accessibilityHidden(true)

            HStack(spacing: 8) {
                RoundStepButton(kind: .minus, size: 48, color: accentColor, isEnabled: value > 0) {
                    step(by: -safeStep)
                }
                .accessibilityLabel(String(format: String(localized: "a11y.welcome.goal.decrease.format", bundle: .gymNutshellCore), title))

                RoundStepButton(kind: .plus, size: 48, color: accentColor, isEnabled: value < safeGoal) {
                    step(by: safeStep)
                }
                .accessibilityLabel(String(format: String(localized: "a11y.welcome.goal.increase.format", bundle: .gymNutshellCore), title))
            }
        }
    }

    private func step(by delta: Int) {
        let next = min(max(value + delta, 0), safeGoal)
        guard next != value else { return }
        UISelectionFeedbackGenerator().selectionChanged()
        withAnimation(.easeInOut(duration: 0.12)) { value = next }
    }

    // Botão ON/OFF para alternar modo "dia de descanso".
    // ON (cinza) → tap aciona descanso. OFF (accent) → tap volta slider com valor zerado.
    private func restDayToggle(isOn: Binding<Bool>) -> some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.easeInOut(duration: 0.15)) {
                if isOn.wrappedValue {
                    isOn.wrappedValue = false
                    value = 0
                } else {
                    isOn.wrappedValue = true
                }
            }
        } label: {
            Text(isOn.wrappedValue
                 ? String(localized: "today.restday.off", bundle: .gymNutshellCore)
                 : String(localized: "today.restday.on", bundle: .gymNutshellCore))
                .font(.caption.weight(.bold))
                .foregroundStyle(isOn.wrappedValue ? Color.secondary : accentColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(isOn.wrappedValue ? accentColor.opacity(0.25) : Color.secondary.opacity(0.20))
                )
        }
        .buttonStyle(.plain)
        // No macOS (iPad App on Mac) o Button respeita uma altura mínima do
        // sistema e estica o conteúdo, deixando o capsule "gordo e estreito".
        // .fixedSize força o botão a usar o tamanho intrínseco do label igual no iOS.
        .fixedSize()
        // Sem override de label: o texto visível ("ON"/"OFF") já vira o label
        // do Button automaticamente. Só adiciono o hint dinâmico.
        .accessibilityHint(A11y.restDayToggleHint(currentlyOn: isOn.wrappedValue))
    }
}
