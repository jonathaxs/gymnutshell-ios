// ⌘
//  GymNutshellCore/Models/DailyAchievement.swift
//
//  Propósito: Define a lógica dos níveis de conquista diária (emoji, nome, cor, pontos) com base no progresso.
//
//  Created by Jonathas Motta (@jonathaxs) on 2025-11-22.
// ⌘

import Foundation

// MARK: - DailyAchievement (Enum dos níveis de conquista diária)
public enum DailyAchievement: CaseIterable, Sendable {
    case level1
    case level2
    case level3
    case level4
    case level5
}

extension DailyAchievement {
    /// Converte um valor de progresso normalizado (0...1) no tier `DailyAchievement` correspondente.
    /// Usa a % inteira (arredondada pra baixo), igual à mostrada no anel.
    public static func from(progress: Double) -> DailyAchievement {
        from(percent: Int((progress * 100).rounded(.down)))
    }

    /// Faixas de 20%, as mesmas cores do anel: 0–20, 21–40, 41–60, 61–80 e 81–100.
    public static func from(percent: Int) -> DailyAchievement {
        switch percent {
        case ...20: return .level1
        case ...40: return .level2
        case ...60: return .level3
        case ...80: return .level4
        default:    return .level5
        }
    }

    /// Número do nível (1...5).
    public var number: Int {
        switch self {
        case .level1: return 1
        case .level2: return 2
        case .level3: return 3
        case .level4: return 4
        case .level5: return 5
        }
    }

    /// % mínima pra chegar neste nível.
    public var minPercent: Int {
        switch self {
        case .level1: return 0
        case .level2: return 21
        case .level3: return 41
        case .level4: return 61
        case .level5: return 81
        }
    }

    /// % máxima deste nível.
    public var maxPercent: Int {
        switch self {
        case .level5: return 100
        default:      return DailyAchievement.allCases[number].minPercent - 1
        }
    }

    /// Faixa pra exibição, ex.: "21 – 40%".
    public var percentRange: String { "\(minPercent) – \(maxPercent)%" }

    /// Próximo nível (nil no 5).
    public var next: DailyAchievement? {
        number < DailyAchievement.allCases.count ? DailyAchievement.allCases[number] : nil
    }

    /// Converte um emoji armazenado (vindo de `DailyRecord`) de volta pro tier `DailyAchievement`.
    public static func from(emoji: String) -> DailyAchievement {
        for theme in AppTheme.allCases {
            for tier in DailyAchievement.allCases {
                if theme.emoji(for: tier) == emoji {
                    return tier
                }
            }
        }
        return .level1
    }

    // MARK: - Propriedades de exibição

    public var emoji: String {
        switch self {
        case .level1:
            return "🐱"
        case .level2:
            return "🐈"
        case .level3:
            return "🐆"
        case .level4:
            return "🦁"
        case .level5:
            return "🐅"
        }
    }

    public var name: String {
        switch self {
        case .level1:
            return String(localized: "daily.achievement.level1", bundle: .gymNutshellCore)
        case .level2:
            return String(localized: "daily.achievement.level2", bundle: .gymNutshellCore)
        case .level3:
            return String(localized: "daily.achievement.level3", bundle: .gymNutshellCore)
        case .level4:
            return String(localized: "daily.achievement.level4", bundle: .gymNutshellCore)
        case .level5:
            return String(localized: "daily.achievement.level5", bundle: .gymNutshellCore)
        }
    }

    public var points: Int {
        switch self {
        case .level1:
            return 0
        case .level2:
            return 25
        case .level3:
            return 50
        case .level4:
            return 75
        case .level5:
            return 100
        }
    }
}
