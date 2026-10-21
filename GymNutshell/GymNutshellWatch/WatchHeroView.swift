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

    var body: some View {
        VStack(spacing: 6) {
            // Igual ao hero da Hoje: anel com a % no centro e o emoji ao lado.
            HStack(spacing: 8) {
                PercentProgressRing(progress: averageProgress)
                    .frame(width: 92, height: 92)
                Text(theme.emoji(for: tier, sex: sex))
                    .font(.system(size: 40))
            }

            Text(theme.name(for: tier, sex: sex))
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
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
