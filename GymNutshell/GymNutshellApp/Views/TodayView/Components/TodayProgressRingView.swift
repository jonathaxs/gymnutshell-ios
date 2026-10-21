// ⌘
//  GymNutshell/GymNutshellApp/Views/TodayView/Components/TodayProgressRingView.swift
//
//  Propósito: Anel de progresso do bloco hero da TodayView. Usa o anel de 5 segmentos
//             (SegmentedProgressRing) com as cores já visíveis, bem lavadas, que acendem conforme
//             o progresso. A porcentagem fica sempre no centro (apagada enquanto está em 0).
//             A conquista do dia e a frase do próximo nível ficam por conta do TodayHeroView.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-19.
// ⌘

import SwiftUI
import GymNutshellCore

// MARK: - TodayProgressRingView

struct TodayProgressRingView: View {

    let progress: Double
    /// Toque no anel: abre a sheet de informação do anel.
    var onTap: (() -> Void)? = nil

    var size: CGFloat = 150
    var lineWidth: CGFloat = 16
    /// true no anel do hero: ao entrar vindo da Welcome, o anel enche passando pelas cores e volta.
    var celebratesAfterOnboarding: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @GestureState private var isPressed: Bool = false

    // Progresso forçado durante a comemoração (nil = mostra o progresso real).
    @State private var celebrationProgress: Double? = nil

    // MARK: - Valores derivados

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    private var percentage: Int {
        // Truncação pra paridade com dailyPercentage (TodayView), widget do iPhone
        // e Watch, todos usam .rounded(.down). "9%" significa "pelo menos 9% feito".
        Int((clampedProgress * 100).rounded(.down))
    }

    /// Nada marcado ainda: a % fica apagada.
    private var hasStarted: Bool { clampedProgress > 0 }

    // MARK: - Comemoração pós-Welcome

    /// Depois do "Vamos lá": o anel enche (pulsando ao virar de cor) e volta ao progresso real.
    private func celebrateIfNeeded() {
        guard celebratesAfterOnboarding,
              UserDefaults.standard.bool(forKey: UserProfile.pendingRingCelebrationKey) else { return }
        UserDefaults.standard.removeObject(forKey: UserProfile.pendingRingCelebrationKey)
        guard !reduceMotion else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            celebrationProgress = 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                celebrationProgress = nil
            }
        }
    }

    // MARK: - Body

    var body: some View {
        SegmentedProgressRing(progress: celebrationProgress ?? clampedProgress,
                              lineWidth: lineWidth,
                              tintedTrack: true) {
            Text("\(percentage)%")
                .font(.system(size: size * 0.22, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(hasStarted ? Color.primary : Color.secondary)
                .contentTransition(.numericText())
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: percentage)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .padding(lineWidth)
        }
        .frame(width: size, height: size)
        // Expande ao pressionar, puramente visual.
        .scaleEffect(isPressed ? 1.06 : 1.0)
        .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.50), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .updating($isPressed) { _, state, _ in state = true }
        )
        .onTapGesture { onTap?() }
        .onAppear(perform: celebrateIfNeeded)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(String(localized: "today.ring.a11y.label", bundle: .gymNutshellCore))
        .accessibilityValue(String(format: String(localized: "today.ring.a11y.value",
                                                  bundle: .gymNutshellCore), percentage))
        .accessibilityHint(String(localized: "today.ring.a11y.hint", bundle: .gymNutshellCore))
    }
}
