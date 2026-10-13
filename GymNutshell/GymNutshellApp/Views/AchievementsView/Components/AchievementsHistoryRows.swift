// ⌘
//  GymNutshell/GymNutshellApp/Views/AchievementsView/Components/AchievementsHistoryRows.swift
//
//  Propósito: Linha da lista de histórico em Conquistas para registros
//             diários (com botão de editar quando dentro da janela).
// ⌘

import SwiftUI
import GymNutshellCore

/// Linha da lista que representa um `DailyRecord`. O HStack interno é o alvo
/// tappável e cabe num único elemento de VoiceOver; o botão de editar fica
/// fora pra ser focado separadamente.
struct HistoryDailyRow: View {
    @AppStorage(AppAccentColor.storageKey) private var storedColorRaw: String = AppAccentColor.blue.rawValue
    private var accentColor: Color { (AppAccentColor(rawValue: storedColorRaw) ?? .blue).color }

    let record: DailyRecord
    let tierName: String
    let tierEmoji: String
    let canEdit: Bool
    let onTap: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 16) {
                EmojiBadge(emoji: tierEmoji, color: accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(tierName)
                        .font(.headline)

                    Text(String(format: String(localized: "achievements.daily.row.description",
                                              bundle: .gymNutshellCore), record.percent))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(record.date, style: .date)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }

                Spacer()
            }
            .contentShape(Rectangle())
            .tapButton(perform: onTap)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(String(format: String(localized: "a11y.record.row.daily.format",
                                                     bundle: .gymNutshellCore),
                                       tierName,
                                       A11y.spokenDate(for: record.date),
                                       record.percent))
            .accessibilityHint(String(localized: "a11y.record.row.hint", bundle: .gymNutshellCore))

            // Botão de edição, visível só pra registros dentro da janela editável.
            if canEdit {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(width: 30, height: 30)
                }
                .appCircleButton()
                .controlSize(.small)
                .accessibilityLabel(String(localized: "a11y.record.edit.label", bundle: .gymNutshellCore))
                .accessibilityHint(String(localized: "a11y.record.edit.hint", bundle: .gymNutshellCore))
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Peças visuais

/// Emoji do nível dentro de um círculo suave na cor de destaque.
private struct EmojiBadge: View {
    let emoji: String
    let color: Color

    var body: some View {
        Text(emoji)
            .font(.title)
            .frame(width: 52, height: 52)
            .background(color.opacity(0.12), in: Circle())
            .accessibilityHidden(true)
    }
}
