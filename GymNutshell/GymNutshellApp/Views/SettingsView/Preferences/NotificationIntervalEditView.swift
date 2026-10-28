// ⌘
//  GymNutshell/GymNutshellApp/Views/SettingsView/Preferences/NotificationIntervalEditView.swift
//
//  Propósito: Sheet que permite editar o intervalo (em minutos) entre notificações
//             recorrentes de um kind editável (Progresso, Metas fixas e personalizadas).
//             Padrão visual inspirado em TrackingGoalDetailView, Form + Stepper + toolbar.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-04-23.
// ⌘

import SwiftUI
import GymNutshellCore

/// Sheet de edição do intervalo em minutos.
/// Use a sobrecarga `init(kind:)` pra kinds fixos e `init(customGoal:)` pra metas personalizadas.
struct NotificationIntervalEditView: View {

    private enum Target {
        case fixed(NotificationKind)
        case custom(CustomTrackingGoal)
    }

    private let target: Target

    @Environment(\.dismiss) private var dismiss

    @State private var minutes: Int = 120
    @State private var sound: NotificationSound = .default

    @Environment(\.openURL) private var openURL

    init(kind: NotificationKind) {
        self.target = .fixed(kind)
    }

    init(customGoal: CustomTrackingGoal) {
        self.target = .custom(customGoal)
    }

    private func soundLabel(_ s: NotificationSound) -> String {
        NSLocalizedString(s.titleKey, bundle: .gymNutshellCore, comment: "")
    }

    /// Intervalo só aparece para kinds editáveis (Metas + Progresso) e metas personalizadas.
    private var showsInterval: Bool {
        switch target {
        case .fixed(let k): return k.isEditable
        case .custom:       return true
        }
    }

    private var titleEmojiPrefix: String {
        switch target {
        case .fixed: return ""
        case .custom(let g): return "\(g.emoji) "
        }
    }

    private var titleText: String {
        switch target {
        case .fixed(let k): return NSLocalizedString(k.titleKey, bundle: .gymNutshellCore, comment: "")
        case .custom(let g): return g.name
        }
    }

    private var footerText: String {
        switch target {
        case .fixed(let k):
            return NSLocalizedString("notifications.kind.\(k.rawValue).footer", bundle: .gymNutshellCore, comment: "")
        case .custom:
            return String(localized: "notifications.custom.footer", bundle: .gymNutshellCore)
        }
    }

    var body: some View {
        Form {
            if showsInterval {
                Section {
                    Stepper(value: $minutes, in: 15...600, step: 15) {
                        HStack {
                            Text(String(localized: "settings.notifications.interval.stepper", bundle: .gymNutshellCore))
                            Spacer()
                            Text(String(format: String(localized: "settings.notifications.interval.value", bundle: .gymNutshellCore), minutes))
                                .font(.body.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text(String(localized: "settings.notifications.interval.header", bundle: .gymNutshellCore))
                } footer: {
                    Text(footerText)
                }
            }

            Section {
                Picker(selection: $sound) {
                    ForEach(NotificationSound.allCases) { option in
                        Text(soundLabel(option)).tag(option)
                    }
                } label: {
                    Text(String(localized: "settings.notifications.sound.label", bundle: .gymNutshellCore))
                }

                if sound == .default, let url = NotificationManager.systemSettingsURL {
                    Button {
                        openURL(url)
                    } label: {
                        Label(
                            String(localized: "settings.notifications.sound.openSystem", bundle: .gymNutshellCore),
                            systemImage: "speaker.wave.2"
                        )
                    }
                }
            } header: {
                Text(String(localized: "settings.notifications.sound.header", bundle: .gymNutshellCore))
            } footer: {
                Text(String(localized: "settings.notifications.sound.footer", bundle: .gymNutshellCore))
            }
        }
        .frame(maxWidth: 600)
        .frame(maxWidth: .infinity)
        .navigationTitle("\(titleEmojiPrefix)\(titleText)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                SheetCloseButton(title: String(localized: "common.cancel", bundle: .gymNutshellCore)) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                SheetConfirmButton(title: String(localized: "settings.goaldetail.save", bundle: .gymNutshellCore)) {
                    save()
                    dismiss()
                }
                .disabled(showsInterval && minutes < 15)
            }
        }
        .onAppear { load() }
    }

    private func load() {
        switch target {
        case .fixed(let k):
            minutes = NotificationPreferences.intervalMinutes(k)
            sound = NotificationPreferences.sound(for: k)
        case .custom(let g):
            minutes = NotificationPreferences.customIntervalMinutes(id: g.id)
            sound = NotificationPreferences.customSound(id: g.id)
        }
    }

    private func save() {
        switch target {
        case .fixed(let k):
            if k.isEditable {
                NotificationPreferences.setIntervalMinutes(minutes, for: k)
            }
            NotificationPreferences.setSound(sound, for: k)
            if k.isIntervalBased {
                NotificationManager.shared.reschedule(kind: k)
            }
        case .custom(let g):
            NotificationPreferences.setCustomIntervalMinutes(minutes, id: g.id)
            NotificationPreferences.setCustomSound(sound, id: g.id)
            NotificationManager.shared.rescheduleCustom(goal: g, currentIntake: nil)
        }
    }
}
