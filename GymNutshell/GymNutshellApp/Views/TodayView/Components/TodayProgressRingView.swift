// ⌘
//  GymNutshell/GymNutshellApp/Views/TodayView/Components/TodayProgressRingView.swift
//
//  Propósito: Anel de progresso do bloco hero da TodayView. Usa o anel de 5 segmentos
//             (SegmentedProgressRing) com o emoji da conquista do dia no centro.
//             A porcentagem e uma frase (próximo nível, dica ou nome do nível) ficam abaixo do anel.
//             Com progresso 0 o centro fica vazio; o emoji aparece no primeiro registro.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-19.
// ⌘

import SwiftUI
import GymNutshellCore

// MARK: - TodayProgressRingView

struct TodayProgressRingView: View {

    let progress: Double
    let achievement: DailyAchievement
    let theme: AppTheme
    /// Toque no anel: abre a sheet de informação do anel.
    var onTap: (() -> Void)? = nil
    /// Toque no emoji do centro: abre a sheet dos níveis de conquista.
    var onEmojiTap: (() -> Void)? = nil

    /// Frase abaixo da porcentagem. Vazia = mostra o nome do nível (ou nada, se não começou).
    var caption: String = ""

    var size: CGFloat = 150
    var lineWidth: CGFloat = 18

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Sexo do usuário, usado pro emoji e nome do nível no gênero correto.
    @AppStorage(UserProfile.sexKey) private var sex: String = "male"

    @GestureState private var isPressed: Bool = false

    // MARK: - Valores derivados

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    private var percentage: Int {
        // Truncação pra paridade com dailyPercentage (TodayView), widget do iPhone
        // e Watch, todos usam .rounded(.down). "9%" significa "pelo menos 9% feito".
        Int((clampedProgress * 100).rounded(.down))
    }

    /// Nada marcado ainda: centro vazio e sem nome de nível.
    private var hasStarted: Bool { clampedProgress > 0 }

    private var emoji: String { theme.emoji(for: achievement, sex: sex) }
    private var tierName: String { theme.name(for: achievement, sex: sex) }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 10) {
            SegmentedProgressRing(progress: clampedProgress, lineWidth: lineWidth) {
                if hasStarted {
                    Text(emoji)
                        .font(.system(size: size * 0.38))
                        // Troca de nível: o emoji novo entra com escala.
                        .id(emoji)
                        .transition(reduceMotion ? .opacity : .scale(scale: 0.4).combined(with: .opacity))
                        .contentShape(Circle())
                        .onTapGesture { onEmojiTap?() }
                        .accessibilityElement(children: .ignore)
                        .accessibilityAddTraits(.isButton)
                        .accessibilityLabel(String(format: String(localized: "today.tier.a11y.label",
                                                                 bundle: .gymNutshellCore),
                                                   emoji, tierName))
                        .accessibilityHint(A11y.moreInfoHint())
                }
            }
            .frame(width: size, height: size)
            .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.6), value: emoji)
            .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.6), value: hasStarted)
            // Expande ao pressionar, puramente visual.
            .scaleEffect(isPressed ? 1.08 : 1.0)
            .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.50), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in state = true }
            )
            // onTapGesture (não simultâneo): o toque no emoji do centro tem prioridade
            // e não abre as duas sheets ao mesmo tempo.
            .onTapGesture { onTap?() }
            .accessibilityElement(children: .contain)

            // Porcentagem fora do anel + nome do nível atual.
            VStack(spacing: 2) {
                Text("\(percentage)%")
                    .font(.title2.weight(.bold).monospacedDigit())
                    .contentTransition(.numericText())
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: percentage)

                Text(caption.isEmpty ? (hasStarted ? tierName : " ") : caption)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
            }
            .contentShape(Rectangle())
            .onTapGesture { onTap?() }
            // Anel + porcentagem num único elemento de VoiceOver (o emoji fica separado, acima).
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(String(localized: "today.ring.a11y.label", bundle: .gymNutshellCore))
            .accessibilityValue(String(format: String(localized: "today.ring.a11y.value",
                                                      bundle: .gymNutshellCore), percentage))
            .accessibilityHint(String(localized: "today.ring.a11y.hint", bundle: .gymNutshellCore))
        }
    }
}
