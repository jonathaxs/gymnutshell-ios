// ⌘
//  GymNutshell/GymNutshellApp/Views/WelcomeView/Steps/WelcomeControlStyleStep.swift
//
//  Propósito: Etapa do onboarding, o usuário escolhe se marca as metas deslizando (slider)
//             ou com botões − / +. Só a opção selecionada mostra a prévia do controle, animada:
//             o slider vai e volta sozinho e os botões − / + são "tocados" de exemplo.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-10-08.
// ⌘

import SwiftUI
import GymNutshellCore

/// Etapa do onboarding: dois cards selecionáveis (slider / − +); o selecionado abre a prévia do controle.
struct WelcomeControlStyleStep: View {

    @Binding var selection: ControlStyle
    let accentColor: Color
    var isWide: Bool = false

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    if !isWide {
                        WelcomeStepHeader(
                            emoji: "🎛️",
                            title: String(localized: "welcome.step.control.title", bundle: .gymNutshellCore),
                            subtitle: String(localized: "welcome.step.control.subtitle", bundle: .gymNutshellCore),
                            accentColor: accentColor
                        )
                    }

                    card(.slider,
                         title: String(localized: "welcome.control.slider", bundle: .gymNutshellCore),
                         desc: String(localized: "welcome.control.slider.desc", bundle: .gymNutshellCore)) {
                        SliderPreview(color: accentColor)
                    }

                    card(.stepper,
                         title: String(localized: "welcome.control.stepper", bundle: .gymNutshellCore),
                         desc: String(localized: "welcome.control.stepper.desc", bundle: .gymNutshellCore)) {
                        StepperPreview(color: accentColor)
                    }
                }
                .padding(.horizontal, AppStyle.horizontalPadding)
                .padding(.vertical)
                .frame(maxWidth: .infinity, minHeight: isWide ? geo.size.height : 0, alignment: .center)
            }
        }
    }

    // MARK: - Card de opção

    private func card<Preview: View>(
        _ style: ControlStyle,
        title: String,
        desc: String,
        @ViewBuilder preview: () -> Preview
    ) -> some View {
        let isSelected = selection == style
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? accentColor : Color.secondary.opacity(0.5))
                    .accessibilityHidden(true)
            }
            Text(desc)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if isSelected {
                preview()
                    .padding(.vertical, 6)
                    .accessibilityHidden(true)
                    .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .appCard(isSelected: isSelected, accentColor: accentColor)
        .contentShape(RoundedRectangle(cornerRadius: AppStyle.cardRadius, style: .continuous))
        .tapButton {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.snappy(duration: 0.35)) { selection = style }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected
                            ? String(localized: "a11y.selected", bundle: .gymNutshellCore)
                            : String(localized: "a11y.not.selected", bundle: .gymNutshellCore))
    }
}

// MARK: - Prévia do controle − / +

/// Barra à esquerda e os dois botões juntos à direita, como na Today. Sem toque: o + é "tocado"
/// três vezes enchendo a barra, depois o − três vezes esvaziando, em loop.
struct StepperPreview: View {

    let color: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var value: Double = 0.25
    @State private var pressed: RoundStepButton.Kind? = nil

    var body: some View {
        HStack(spacing: 14) {
            ProgressView(value: value)
                .tint(color)
            HStack(spacing: 8) {
                demoButton(.minus)
                demoButton(.plus)
            }
        }
        .allowsHitTesting(false)
        .task {
            guard !reduceMotion else { return }
            var tap = 0
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(0.7))
                let kind: RoundStepButton.Kind = (tap / 3) % 2 == 0 ? .plus : .minus
                withAnimation(.spring(response: 0.18, dampingFraction: 0.6)) { pressed = kind }
                try? await Task.sleep(for: .seconds(0.15))
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { pressed = nil }
                withAnimation(.easeInOut(duration: 0.3)) { value += kind == .plus ? 0.2 : -0.2 }
                tap += 1
            }
        }
    }

    /// Botão da prévia: encolhe e ganha um brilho da cor quando é "tocado".
    private func demoButton(_ kind: RoundStepButton.Kind) -> some View {
        RoundStepButton(kind: kind, size: 44, color: color) {}
            .overlay {
                Circle()
                    .fill(color.opacity(pressed == kind ? 0.25 : 0))
            }
            .scaleEffect(pressed == kind ? 0.85 : 1)
    }
}

/// Prévia do slider: o Slider nativo travado, pra ficar igual ao da Today em cada iOS
/// (vidro no iOS 26+, clássico no 18). O valor vai e volta sozinho, de leve.
struct SliderPreview: View {

    let color: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            Slider(value: .constant(reduceMotion ? 0.4 : value(at: context.date)))
                .tint(color)
        }
        .allowsHitTesting(false)
    }

    /// Onda suave entre 15% e 85%, num ciclo de 4 segundos.
    private func value(at date: Date) -> Double {
        let phase = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 4) / 4
        return 0.5 - 0.35 * cos(phase * 2 * .pi)
    }
}
