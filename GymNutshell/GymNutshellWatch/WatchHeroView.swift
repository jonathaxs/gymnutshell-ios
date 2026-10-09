// ⌘
//  GymNutshellWatch/WatchHeroView.swift
//
//  Propósito: Hero superior do Watch app, anel de progresso médio do dia
//             + emoji do tier + nome do tier + percentual.
//             Anel de 5 segmentos coloridos, igual ao iPhone.
// ⌘

import SwiftUI
import GymNutshellCore

struct WatchHeroView: View {
    let averageProgress: Double
    let theme: AppTheme
    let tier: DailyAchievement
    let sex: String

    // Percentual no tom do segmento atual (mesmas 5 cores do anel).
    private var ringColor: Color {
        let colors = SegmentedProgressRing<EmptyView>.segmentColors
        let index = min(max(Int(averageProgress * Double(colors.count)), 0), colors.count - 1)
        return colors[index]
    }

    var body: some View {
        VStack(spacing: 6) {
            SegmentedProgressRing(progress: averageProgress, lineWidth: 9, animated: false) {
                Text(theme.emoji(for: tier, sex: sex))
                    .font(.system(size: 36))
            }
            .frame(width: 100, height: 100)

            Text(theme.name(for: tier, sex: sex))
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)

            Text("\(Int(averageProgress * 100))%")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(ringColor)
        }
        // Combina anel + tier + percentual em uma única locução, mesma estrutura
        // do iPhone TodayProgressRingView: "Daily progress, Big Cat, 65 percent completed".
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            String(localized: "a11y.watch.hero.label", bundle: .gymNutshellCore)
            + ", " + theme.name(for: tier, sex: sex)
        )
        .accessibilityValue(A11y.progressValue(percent: Int(averageProgress * 100)))
    }
}
