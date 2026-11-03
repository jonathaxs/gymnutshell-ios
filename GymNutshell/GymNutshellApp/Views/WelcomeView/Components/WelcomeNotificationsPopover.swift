// ⌘
//  GymNutshell/GymNutshellApp/Views/WelcomeView/Components/WelcomeNotificationsPopover.swift
//
//  Propósito: Balão que abre na etapa Tudo pronto depois de permitir as notificações.
//             Atalho pra ligar ou desligar o lembrete de água e, se a Creatina foi incluída,
//             o dela com o horário. Quase ninguém vai até Ajustes, então já fica pronto aqui.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-11-02.
// ⌘

import SwiftUI
import GymNutshellCore

struct WelcomeNotificationsPopover: View {

    let includeCreatine: Bool
    let accentColor: Color

    @State private var waterOn = NotificationPreferences.isEnabled(.water)
    @State private var creatineOn = NotificationPreferences.isEnabled(.creatine)
    @State private var creatineTime = NotificationPreferences
        .reminderTimes(id: NotificationPreferences.creatineReminderId).first ?? Self.defaultCreatineTime

    /// Horário sugerido pra Creatina: o atalho Manhã.
    private static let defaultCreatineTime = ReminderTime(hour: 8, minute: 0)

    var body: some View {
        VStack(spacing: 12) {
            Text(String(localized: "welcome.ready.notifications.setup.title", bundle: .gymNutshellCore))
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $waterOn) {
                    Text("💧 " + String(localized: "today.metric.water", bundle: .gymNutshellCore))
                }

                if includeCreatine {
                    Divider()
                    Toggle(isOn: $creatineOn) {
                        Text("🧪 " + String(localized: "today.goals.creatine", bundle: .gymNutshellCore))
                    }
                    if creatineOn {
                        DatePicker(String(localized: "settings.notifications.times.row", bundle: .gymNutshellCore),
                                   selection: creatineDate,
                                   displayedComponents: .hourAndMinute)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .tint(accentColor)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground)))

            Text(String(localized: "welcome.ready.notifications.setup.footer", bundle: .gymNutshellCore))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(width: 320)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color(.systemGroupedBackground))
        .animation(.easeInOut(duration: 0.2), value: creatineOn)
        .onChange(of: waterOn) { _, on in
            NotificationPreferences.setEnabled(on, for: .water)
        }
        .onChange(of: creatineOn) { _, on in
            // Ligar sem horário salvo grava o sugerido; desligar mantém o horário pra depois.
            if on && NotificationPreferences.reminderTimes(id: NotificationPreferences.creatineReminderId).isEmpty {
                NotificationPreferences.setReminderTimes([creatineTime], id: NotificationPreferences.creatineReminderId)
            }
            NotificationPreferences.setEnabled(on, for: .creatine)
        }
        .onChange(of: creatineTime) { _, time in
            NotificationPreferences.setReminderTimes([time], id: NotificationPreferences.creatineReminderId)
        }
    }

    private var creatineDate: Binding<Date> {
        Binding(
            get: { creatineTime.date(on: Date()) ?? Date() },
            set: { newDate in
                let c = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                creatineTime = ReminderTime(hour: c.hour ?? 8, minute: c.minute ?? 0)
            }
        )
    }
}
