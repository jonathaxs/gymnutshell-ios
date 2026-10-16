// ⌘
//  GymNutshell/GymNutshellApp/Views/Shared/AchievementStyles.swift
//
//  Propósito: Extensão da camada de apresentação pro DailyAchievement.
//             Mantém valores de cor do SwiftUI fora da camada de modelo.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-28.
// ⌘

import SwiftUI
import GymNutshellCore

// MARK: - DailyAchievement + Cor

extension DailyAchievement {

    // Cor representativa associada ao nível de conquista.
    // Usada principalmente pra fundos sutis e destaques.
    var color: Color {
        // Mesmas cores dos 5 segmentos do anel.
        SegmentedProgressRing<EmptyView>.segmentColors[number - 1].opacity(0.30)
    }
}
