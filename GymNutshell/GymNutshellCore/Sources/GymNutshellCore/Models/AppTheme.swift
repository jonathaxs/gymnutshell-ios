// ⌘
//  GymNutshellCore/Models/AppTheme.swift
//
//  Propósito: Define o sistema de temas visuais do Gym Nutshell.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-28.
// ⌘

import Foundation

// MARK: - AppTheme

public enum AppTheme: String, CaseIterable, Sendable {
    // Sport
    case gym
    case running
    // Animals
    case cat
    case dog
    case horse
    case bear
    case dragon
    case dino
    case ocean
    case monkey
    case bird
    // Hero (warrior)
    case ninja
    case doctor
    // Elements
    case plant
    case fire
    // Space
    case astronaut
    case celestial
    // Competition
    case champion
    case number

    public static let storageKey = "app.theme"

    // MARK: - Categoria

    public enum ThemeCategory: CaseIterable, Sendable {
        case sport
        case animals
        case warrior
        case space
        case elements
        case competition

        public var localizedName: String {
            switch self {
            case .sport:       return String(localized: "app.theme.category.sport", bundle: .gymNutshellCore)
            case .animals:     return String(localized: "app.theme.category.animals", bundle: .gymNutshellCore)
            case .elements:    return String(localized: "app.theme.category.elements", bundle: .gymNutshellCore)
            case .competition: return String(localized: "app.theme.category.competition", bundle: .gymNutshellCore)
            case .warrior:     return String(localized: "app.theme.category.warrior", bundle: .gymNutshellCore)
            case .space:       return String(localized: "app.theme.category.space", bundle: .gymNutshellCore)
            }
        }

        public func localizedName(sex: String) -> String {
            guard self == .warrior, sex == "female" else { return localizedName }
            let femValue = NSLocalizedString("app.theme.category.warrior.fem", bundle: .gymNutshellCore, comment: "")
            return femValue != "app.theme.category.warrior.fem" ? femValue : localizedName
        }
    }

    public var category: ThemeCategory {
        switch self {
        case .gym, .running: return .sport
        case .cat, .dog, .bear, .dino, .dragon, .horse, .ocean, .monkey, .bird: return .animals
        case .doctor, .ninja: return .warrior
        case .fire, .plant: return .elements
        case .astronaut, .celestial: return .space
        case .champion, .number: return .competition
        }
    }

    public static func themes(in category: ThemeCategory) -> [AppTheme] {
        allCases.filter { $0.category == category }
    }

    // MARK: - Emoji por nível

    public func emoji(for tier: DailyAchievement) -> String {
        switch self {
        case .gym:
            switch tier {
            case .level1: return "🐓"
            case .level2: return "🏋️‍♂️"
            case .level3: return "🐀"
            case .level4: return "💪"
            }
        case .running:
            switch tier {
            case .level1: return "🚶‍♂️"
            case .level2: return "👟"
            case .level3: return "🏃‍♂️"
            case .level4: return "🏅"
            }
        case .cat:
            switch tier {
            case .level1: return "🐱"
            case .level2: return "🐈"
            case .level3: return "🐆"
            case .level4: return "🦁"
            }
        case .dog:
            switch tier {
            case .level1: return "🐶"
            case .level2: return "🐩"
            case .level3: return "🐕‍🦺"
            case .level4: return "🐕"
            }
        case .bear:
            switch tier {
            case .level1: return "🧸"
            case .level2: return "🐻"
            case .level3: return "🐻‍❄️"
            case .level4: return "🦬"
            }
        case .dino:
            switch tier {
            case .level1: return "🐢"
            case .level2: return "🐊"
            case .level3: return "🦖"
            case .level4: return "🦕"
            }
        case .dragon:
            switch tier {
            case .level1: return "🥚"
            case .level2: return "🦎"
            case .level3: return "🐉"
            case .level4: return "🐲"
            }
        case .horse:
            switch tier {
            case .level1: return "🐴"
            case .level2: return "🦄"
            case .level3: return "🏇"
            case .level4: return "🎠"
            }
        case .ocean:
            switch tier {
            case .level1: return "🐟"
            case .level2: return "🐬"
            case .level3: return "🪼"
            case .level4: return "🐋"
            }
        case .monkey:
            switch tier {
            case .level1: return "🐒"
            case .level2: return "🐵"
            case .level3: return "🦍"
            case .level4: return "🦧"
            }
        case .bird:
            switch tier {
            case .level1: return "🐣"
            case .level2: return "🐦"
            case .level3: return "🦅"
            case .level4: return "🦉"
            }
        case .doctor:
            switch tier {
            case .level1: return "🥼"
            case .level2: return "💉"
            case .level3: return "⚕️"
            case .level4: return "👨‍⚕️"
            }
        case .ninja:
            switch tier {
            case .level1: return "🥋"
            case .level2: return "⚔️"
            case .level3: return "🥷"
            case .level4: return "🦸"
            }
        case .fire:
            switch tier {
            case .level1: return "🕯️"
            case .level2: return "🔥"
            case .level3: return "🌋"
            case .level4: return "🌞"
            }
        case .plant:
            switch tier {
            case .level1: return "🌱"
            case .level2: return "🌿"
            case .level3: return "🌳"
            case .level4: return "🎄"
            }
        case .astronaut:
            switch tier {
            case .level1: return "🛰️"
            case .level2: return "🧑‍🚀"
            case .level3: return "🚀"
            case .level4: return "🛸"
            }
        case .celestial:
            switch tier {
            case .level1: return "☄️"
            case .level2: return "🌔"
            case .level3: return "🌎"
            case .level4: return "🪐"
            }
        case .champion:
            switch tier {
            case .level1: return "🥉"
            case .level2: return "🥈"
            case .level3: return "🥇"
            case .level4: return "💎"
            }
        case .number:
            switch tier {
            case .level1: return "1️⃣"
            case .level2: return "2️⃣"
            case .level3: return "3️⃣"
            case .level4: return "4️⃣"
            }
        }
    }

    // MARK: - Nome localizado por nível

    public func name(for tier: DailyAchievement) -> String {
        let key: String
        switch self {
        case .gym:
            switch tier {
            case .level1: key = "daily.achievement.gym.level1"
            case .level2: key = "daily.achievement.gym.level2"
            case .level3: key = "daily.achievement.gym.level3"
            case .level4: key = "daily.achievement.gym.level4"
            }
        case .running:
            switch tier {
            case .level1: key = "daily.achievement.running.level1"
            case .level2: key = "daily.achievement.running.level2"
            case .level3: key = "daily.achievement.running.level3"
            case .level4: key = "daily.achievement.running.level4"
            }
        case .cat:
            switch tier {
            case .level1: key = "daily.achievement.level1"
            case .level2: key = "daily.achievement.level2"
            case .level3: key = "daily.achievement.level3"
            case .level4: key = "daily.achievement.level4"
            }
        case .dog:
            switch tier {
            case .level1: key = "daily.achievement.dog.level1"
            case .level2: key = "daily.achievement.dog.level2"
            case .level3: key = "daily.achievement.dog.level3"
            case .level4: key = "daily.achievement.dog.level4"
            }
        case .bear:
            switch tier {
            case .level1: key = "daily.achievement.bear.level1"
            case .level2: key = "daily.achievement.bear.level2"
            case .level3: key = "daily.achievement.bear.level3"
            case .level4: key = "daily.achievement.bear.level4"
            }
        case .dino:
            switch tier {
            case .level1: key = "daily.achievement.dino.level1"
            case .level2: key = "daily.achievement.dino.level2"
            case .level3: key = "daily.achievement.dino.level3"
            case .level4: key = "daily.achievement.dino.level4"
            }
        case .dragon:
            switch tier {
            case .level1: key = "daily.achievement.dragon.level1"
            case .level2: key = "daily.achievement.dragon.level2"
            case .level3: key = "daily.achievement.dragon.level3"
            case .level4: key = "daily.achievement.dragon.level4"
            }
        case .horse:
            switch tier {
            case .level1: key = "daily.achievement.horse.level1"
            case .level2: key = "daily.achievement.horse.level2"
            case .level3: key = "daily.achievement.horse.level3"
            case .level4: key = "daily.achievement.horse.level4"
            }
        case .ocean:
            switch tier {
            case .level1: key = "daily.achievement.ocean.level1"
            case .level2: key = "daily.achievement.ocean.level2"
            case .level3: key = "daily.achievement.ocean.level3"
            case .level4: key = "daily.achievement.ocean.level4"
            }
        case .monkey:
            switch tier {
            case .level1: key = "daily.achievement.monkey.level1"
            case .level2: key = "daily.achievement.monkey.level2"
            case .level3: key = "daily.achievement.monkey.level3"
            case .level4: key = "daily.achievement.monkey.level4"
            }
        case .bird:
            switch tier {
            case .level1: key = "daily.achievement.bird.level1"
            case .level2: key = "daily.achievement.bird.level2"
            case .level3: key = "daily.achievement.bird.level3"
            case .level4: key = "daily.achievement.bird.level4"
            }
        case .doctor:
            switch tier {
            case .level1: key = "daily.achievement.doctor.level1"
            case .level2: key = "daily.achievement.doctor.level2"
            case .level3: key = "daily.achievement.doctor.level3"
            case .level4: key = "daily.achievement.doctor.level4"
            }
        case .ninja:
            switch tier {
            case .level1: key = "daily.achievement.ninja.level1"
            case .level2: key = "daily.achievement.ninja.level2"
            case .level3: key = "daily.achievement.ninja.level3"
            case .level4: key = "daily.achievement.ninja.level4"
            }
        case .fire:
            switch tier {
            case .level1: key = "daily.achievement.fire.level1"
            case .level2: key = "daily.achievement.fire.level2"
            case .level3: key = "daily.achievement.fire.level3"
            case .level4: key = "daily.achievement.fire.level4"
            }
        case .plant:
            switch tier {
            case .level1: key = "daily.achievement.plant.level1"
            case .level2: key = "daily.achievement.plant.level2"
            case .level3: key = "daily.achievement.plant.level3"
            case .level4: key = "daily.achievement.plant.level4"
            }
        case .astronaut:
            switch tier {
            case .level1: key = "daily.achievement.astronaut.level1"
            case .level2: key = "daily.achievement.astronaut.level2"
            case .level3: key = "daily.achievement.astronaut.level3"
            case .level4: key = "daily.achievement.astronaut.level4"
            }
        case .celestial:
            switch tier {
            case .level1: key = "daily.achievement.celestial.level1"
            case .level2: key = "daily.achievement.celestial.level2"
            case .level3: key = "daily.achievement.celestial.level3"
            case .level4: key = "daily.achievement.celestial.level4"
            }
        case .champion:
            switch tier {
            case .level1: key = "daily.achievement.champion.level1"
            case .level2: key = "daily.achievement.champion.level2"
            case .level3: key = "daily.achievement.champion.level3"
            case .level4: key = "daily.achievement.champion.level4"
            }
        case .number:
            switch tier {
            case .level1: key = "daily.achievement.number.level1"
            case .level2: key = "daily.achievement.number.level2"
            case .level3: key = "daily.achievement.number.level3"
            case .level4: key = "daily.achievement.number.level4"
            }
        }
        return String(localized: String.LocalizationValue(key), bundle: .gymNutshellCore)
    }

    // MARK: - Nome localizado por nível e sexo

    public func name(for tier: DailyAchievement, sex: String) -> String {
        guard sex == "female" else { return name(for: tier) }

        let masculineKey: String
        switch self {
        case .cat:
            switch tier {
            case .level1: masculineKey = "daily.achievement.level1"
            case .level2: masculineKey = "daily.achievement.level2"
            case .level3: masculineKey = "daily.achievement.level3"
            case .level4: masculineKey = "daily.achievement.level4"
            }
        default:
            let baseName = name(for: tier)
            let themePrefix: String
            switch self {
            case .gym:     themePrefix = "daily.achievement.gym"
            case .running: themePrefix = "daily.achievement.running"
            case .bear:    themePrefix = "daily.achievement.bear"
            case .horse:   themePrefix = "daily.achievement.horse"
            case .dog:     themePrefix = "daily.achievement.dog"
            case .dragon:  themePrefix = "daily.achievement.dragon"
            case .dino:    themePrefix = "daily.achievement.dino"
            case .doctor:  themePrefix = "daily.achievement.doctor"
            case .ninja:   themePrefix = "daily.achievement.ninja"
            case .fire:    themePrefix = "daily.achievement.fire"
            default:       return baseName
            }
            let tierSuffix: String
            switch tier {
            case .level1: tierSuffix = "level1"
            case .level2: tierSuffix = "level2"
            case .level3: tierSuffix = "level3"
            case .level4: tierSuffix = "level4"
            }
            let femKey = "\(themePrefix).\(tierSuffix).fem"
            let femValue = NSLocalizedString(femKey, bundle: .gymNutshellCore, comment: "")
            return femValue != femKey ? femValue : baseName
        }
        let femKey = masculineKey + ".fem"
        let femValue = NSLocalizedString(femKey, bundle: .gymNutshellCore, comment: "")
        return femValue != femKey ? femValue : String(localized: String.LocalizationValue(masculineKey), bundle: .gymNutshellCore)
    }

    // MARK: - Helpers de exibição

    public func displayName(sex: String) -> String {
        guard sex == "female" else { return displayName }
        let femKey: String
        switch self {
        case .gym:    femKey = "app.theme.gym.fem"
        case .cat:    femKey = "app.theme.cat.fem"
        case .bear:   femKey = "app.theme.bear.fem"
        case .horse:  femKey = "app.theme.horse.fem"
        case .dog:    femKey = "app.theme.dog.fem"
        case .dragon: femKey = "app.theme.dragon.fem"
        case .ninja:  femKey = "app.theme.ninja.fem"
        case .doctor: femKey = "app.theme.doctor.fem"
        default:      return displayName
        }
        let femValue = NSLocalizedString(femKey, bundle: .gymNutshellCore, comment: "")
        return femValue != femKey ? femValue : displayName
    }

    public var displayName: String {
        let key: String
        switch self {
        case .gym:       key = "app.theme.gym"
        case .running:   key = "app.theme.running"
        case .cat:       key = "app.theme.cat"
        case .dog:       key = "app.theme.dog"
        case .bear:      key = "app.theme.bear"
        case .dino:      key = "app.theme.dino"
        case .dragon:    key = "app.theme.dragon"
        case .horse:     key = "app.theme.horse"
        case .ocean:     key = "app.theme.ocean"
        case .monkey:    key = "app.theme.monkey"
        case .bird:      key = "app.theme.bird"
        case .doctor:    key = "app.theme.doctor"
        case .ninja:     key = "app.theme.ninja"
        case .fire:      key = "app.theme.fire"
        case .plant:     key = "app.theme.plant"
        case .astronaut: key = "app.theme.astronaut"
        case .celestial: key = "app.theme.celestial"
        case .champion:  key = "app.theme.champion"
        case .number:    key = "app.theme.number"
        }
        return String(localized: String.LocalizationValue(key), bundle: .gymNutshellCore)
    }

    public var themeEmojis: String {
        DailyAchievement.allCases.map { emoji(for: $0) }.joined()
    }

    public func emoji(for tier: DailyAchievement, sex: String) -> String {
        if sex == "female" {
            switch self {
            case .gym:
                switch tier {
                case .level1: return "🐔"
                case .level2: return "🏋️‍♀️"
                case .level3: return "🐁"
                case .level4: return "🍑"
                }
            case .running:
                switch tier {
                case .level1: return "🚶‍♀️"
                case .level3: return "🏃‍♀️"
                default: break
                }
            case .doctor:
                if tier == .level4 { return "👩‍⚕️" }
            default: break
            }
        }
        return emoji(for: tier)
    }

    public func themeEmojis(sex: String) -> String {
        DailyAchievement.allCases.map { emoji(for: $0, sex: sex) }.joined()
    }
}

// MARK: - Identifiable

extension AppTheme: Identifiable {
    public var id: String { rawValue }
}
