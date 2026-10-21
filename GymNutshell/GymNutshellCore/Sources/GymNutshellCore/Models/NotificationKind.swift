// ⌘
//  GymNutshellCore/Models/NotificationKind.swift
//
//  Propósito: Define os tipos de notificação suportados pelo app e um helper
//             estático pra ler/escrever as preferências (ativa/desativada e intervalo
//             em minutos) de cada tipo no UserDefaults.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-04-23.
// ⌘

import Foundation
import UserNotifications

// MARK: - NotificationSound

/// Som disponível para notificações locais.
/// `.default` toca o Text Tone configurado pelo usuário em Ajustes → Notificações → Gym Nutshell → Sons
/// (Tri-tone, Note, Chord, etc.). `.silent` desativa o som por completo neste app.
public enum NotificationSound: String, CaseIterable, Identifiable, Codable, Sendable {
    case `default`
    case silent

    public var id: String { rawValue }

    /// Som efetivo a aplicar em `UNMutableNotificationContent.sound`.
    /// `nil` significa silencioso (não atribuir som no content).
    public var systemSound: UNNotificationSound? {
        switch self {
        case .default: return .default
        case .silent:  return nil
        }
    }

    /// Chave de localização do nome exibido na UI.
    public var titleKey: String { "notifications.sound.\(rawValue)" }
}

// MARK: - NotificationKind

/// Catálogo de todas as notificações fixas (não-customizadas) do Gym Nutshell.
/// Notificações de metas personalizadas usam identifiers `custom.<uuid>` e não entram neste enum.
public enum NotificationKind: String, CaseIterable, Identifiable, Sendable {

    // MARK: Sistema
    case progress
    case achievement
    case appleHealth
    case backup

    // MARK: Metas
    case sleep
    case water
    case protein
    case carbs
    case goodFat
    case fiber
    case workout
    case cardio
    case creatine

    public var id: String { rawValue }

    /// True se a notificação permite o usuário editar o intervalo em minutos.
    /// Todas as Metas + Progresso são editáveis; Conquista, Apple Saúde e Backup são eventos.
    public var isEditable: Bool {
        switch self {
        case .progress, .sleep, .water, .protein, .carbs, .goodFat, .fiber,
             .workout, .cardio, .creatine:
            return true
        case .achievement, .appleHealth, .backup:
            return false
        }
    }

    /// True quando a notificação é baseada em intervalo (agendamento periódico no dia).
    public var isIntervalBased: Bool { isEditable }

    /// Intervalo padrão em minutos para notificações baseadas em intervalo.
    /// Progresso: 150 | Água: 120 | Sono: 180 | demais metas: 120.
    public var defaultIntervalMinutes: Int {
        switch self {
        case .progress: return 150
        case .water:    return 120
        case .sleep:    return 180
        case .protein, .carbs, .goodFat, .fiber, .workout, .cardio, .creatine:
            return 120
        default:
            return 0
        }
    }

    /// Hora limite (24h) a partir da qual não agendamos mais lembretes no dia.
    /// Sono tem cutoff mais cedo (19h) a pedido do usuário, não faz sentido sugerir cochilo à noite.
    public var dailyCutoffHour: Int {
        switch self {
        case .sleep: return 19
        default:     return 22
        }
    }

    /// Hora mínima (24h) a partir da qual os lembretes podem começar no dia.
    /// Sono só sugere a partir das 10h, antes disso o usuário provavelmente acabou de acordar.
    public var dailyStartHour: Int {
        switch self {
        case .sleep: return 10
        default:     return 6
        }
    }

    /// SF Symbol exibido na linha do row de Ajustes, apenas para kinds da seção Sistema.
    /// Metas usam emoji (via `emoji`), não ícone.
    /// Progresso usa `circle.dotted` pra bater com a página "Anel do Progresso" em Ajustes.
    public var systemIcon: String? {
        switch self {
        case .progress:    return "circle.dotted"
        case .achievement: return "trophy.fill"
        case .appleHealth: return "heart.fill"
        case .backup:      return "externaldrive"
        default:           return nil
        }
    }

    /// Emoji representativo para os kinds de Meta (espelha o usado em TrackingGoalsSettingsView).
    /// Retorna `nil` para kinds da seção Sistema.
    public var emoji: String? {
        switch self {
        case .workout:  return "🏋️"
        case .cardio:   return "🏃"
        case .sleep:    return "💤"
        case .water:    return "💧"
        case .protein:  return "🍗"
        case .carbs:    return "🍞"
        case .goodFat:  return "🧈"
        case .fiber:    return "🌾"
        case .creatine: return "🧪"
        default:        return nil
        }
    }

    /// Chave `tracking.*` correspondente no `GoalOrderStore`. Usada pra ordenar as metas
    /// conforme a ordem personalizada pelo usuário em Ajustes → Metas.
    public var trackingOrderKey: String? {
        switch self {
        case .workout:  return "tracking.workout"
        case .cardio:   return "tracking.cardio"
        case .sleep:    return "tracking.sleep"
        case .water:    return "tracking.water"
        case .protein:  return "tracking.protein"
        case .carbs:    return "tracking.carbs"
        case .goodFat:  return "tracking.goodFat"
        case .fiber:    return "tracking.fiber"
        case .creatine: return "tracking.creatine"
        default:        return nil
        }
    }

    /// Inverso de `trackingOrderKey`, resolve um NotificationKind a partir da chave do GoalOrderStore.
    public static func from(trackingOrderKey key: String) -> NotificationKind? {
        allCases.first { $0.trackingOrderKey == key }
    }

    /// Chave de localização do título exibido (ex: "Progresso", "Água").
    public var titleKey: String { "notifications.kind.\(rawValue).title" }

    /// Chave de localização da descrição curta abaixo do título na lista de Ajustes.
    public var descriptionKey: String { "notifications.kind.\(rawValue).description" }
}

// MARK: - NotificationPreferences

/// Helper estático pra ler e gravar as preferências de notificação no UserDefaults.
/// Chaves:
///   - `notifications.enabled.<kind>` : Bool
///   - `notifications.intervalMinutes.<kind>` : Int (0 = usa o default do kind)
///   - `notifications.enabled.custom.<uuid>` : Bool
///   - `notifications.intervalMinutes.custom.<uuid>` : Int
public enum NotificationPreferences {

    // MARK: Kind fixo

    public static func isEnabled(_ kind: NotificationKind) -> Bool {
        UserDefaults.standard.bool(forKey: "notifications.enabled.\(kind.rawValue)")
    }

    public static func setEnabled(_ enabled: Bool, for kind: NotificationKind) {
        UserDefaults.standard.set(enabled, forKey: "notifications.enabled.\(kind.rawValue)")
    }

    public static func intervalMinutes(_ kind: NotificationKind) -> Int {
        let stored = UserDefaults.standard.integer(forKey: "notifications.intervalMinutes.\(kind.rawValue)")
        return stored > 0 ? stored : kind.defaultIntervalMinutes
    }

    public static func setIntervalMinutes(_ minutes: Int, for kind: NotificationKind) {
        UserDefaults.standard.set(minutes, forKey: "notifications.intervalMinutes.\(kind.rawValue)")
    }

    // MARK: Som por kind

    public static func sound(for kind: NotificationKind) -> NotificationSound {
        let raw = UserDefaults.standard.string(forKey: "notifications.sound.\(kind.rawValue)") ?? ""
        return NotificationSound(rawValue: raw) ?? .default
    }

    public static func setSound(_ sound: NotificationSound, for kind: NotificationKind) {
        UserDefaults.standard.set(sound.rawValue, forKey: "notifications.sound.\(kind.rawValue)")
    }

    // MARK: Metas personalizadas

    public static func isCustomEnabled(id: UUID) -> Bool {
        UserDefaults.standard.bool(forKey: "notifications.enabled.custom.\(id.uuidString)")
    }

    public static func setCustomEnabled(_ enabled: Bool, id: UUID) {
        UserDefaults.standard.set(enabled, forKey: "notifications.enabled.custom.\(id.uuidString)")
    }

    public static func customIntervalMinutes(id: UUID, fallback: Int = 120) -> Int {
        let stored = UserDefaults.standard.integer(forKey: "notifications.intervalMinutes.custom.\(id.uuidString)")
        return stored > 0 ? stored : fallback
    }

    public static func setCustomIntervalMinutes(_ minutes: Int, id: UUID) {
        UserDefaults.standard.set(minutes, forKey: "notifications.intervalMinutes.custom.\(id.uuidString)")
    }

    public static func customSound(id: UUID) -> NotificationSound {
        let raw = UserDefaults.standard.string(forKey: "notifications.sound.custom.\(id.uuidString)") ?? ""
        return NotificationSound(rawValue: raw) ?? .default
    }

    public static func setCustomSound(_ sound: NotificationSound, id: UUID) {
        UserDefaults.standard.set(sound.rawValue, forKey: "notifications.sound.custom.\(id.uuidString)")
    }
}
