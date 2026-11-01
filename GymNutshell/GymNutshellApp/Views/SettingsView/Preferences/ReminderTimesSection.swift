// ⌘
//  GymNutshell/GymNutshellApp/Views/SettingsView/Preferences/ReminderTimesSection.swift
//
//  Propósito: Seção de horários dos lembretes de uma meta check-in (suplemento).
//             Lista os horários, adiciona por atalho (Manhã, Almoço...) ou livre, e remove.
//             Usada na edição da meta e em Ajustes → Notificações.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-11-01.
// ⌘

import SwiftUI
import GymNutshellCore

struct ReminderTimesSection: View {

    @Binding var times: [ReminderTime]

    var body: some View {
        Section {
            ForEach(times.indices, id: \.self) { index in
                DatePicker(
                    String(localized: "settings.notifications.times.row", bundle: .gymNutshellCore),
                    selection: dateBinding(at: index),
                    displayedComponents: .hourAndMinute
                )
            }
            .onDelete { times.remove(atOffsets: $0) }

            // Atalhos: um toque adiciona o horário; o que já está na lista fica marcado.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ReminderTime.presets) { preset in
                        let added = times.contains(preset.time)
                        Button {
                            toggle(preset.time)
                        } label: {
                            Label("\(preset.title) \(preset.time.formatted)",
                                  systemImage: added ? "checkmark" : "plus")
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                        .tint(added ? .accentColor : .secondary)
                        .accessibilityAddTraits(added ? .isSelected : [])
                    }
                }
                .padding(.vertical, 2)
            }

            Button {
                addNextFreeTime()
            } label: {
                Label(String(localized: "settings.notifications.times.add", bundle: .gymNutshellCore),
                      systemImage: "plus.circle.fill")
            }
        } header: {
            Text(String(localized: "settings.notifications.times.header", bundle: .gymNutshellCore))
        } footer: {
            Text(String(localized: "settings.notifications.times.footer", bundle: .gymNutshellCore))
        }
    }

    // MARK: - Ações

    // Atalho já na lista sai; senão entra.
    private func toggle(_ time: ReminderTime) {
        if let index = times.firstIndex(of: time) {
            times.remove(at: index)
        } else {
            times.append(time)
            times.sort()
        }
    }

    // Uma hora depois do último horário (ou 08:00), pulando os que já existem.
    private func addNextFreeTime() {
        var candidate = times.max().map { ReminderTime(hour: min($0.hour + 1, 23), minute: $0.minute) }
            ?? ReminderTime(hour: 8, minute: 0)
        while times.contains(candidate) && candidate.hour < 23 {
            candidate = ReminderTime(hour: candidate.hour + 1, minute: candidate.minute)
        }
        guard !times.contains(candidate) else { return }
        times.append(candidate)
    }

    // Binding protegido: depois de apagar uma linha o índice antigo pode não existir mais.
    private func dateBinding(at index: Int) -> Binding<Date> {
        Binding(
            get: {
                guard times.indices.contains(index) else { return Date() }
                return times[index].date(on: Date()) ?? Date()
            },
            set: { newDate in
                guard times.indices.contains(index) else { return }
                let c = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                times[index] = ReminderTime(hour: c.hour ?? 0, minute: c.minute ?? 0)
            }
        )
    }
}

// MARK: - Resumo dos horários

extension ReminderTime {
    /// "08:00 · 22:30", ou o aviso de que não há horário.
    static func summary(_ times: [ReminderTime]) -> String {
        guard !times.isEmpty else {
            return String(localized: "settings.notifications.times.empty", bundle: .gymNutshellCore)
        }
        return times.sorted().map(\.formatted).joined(separator: " · ")
    }
}
