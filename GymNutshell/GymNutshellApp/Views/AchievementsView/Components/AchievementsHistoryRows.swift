// ⌘
//  GymNutshell/GymNutshellApp/Views/AchievementsView/Components/AchievementsHistoryRows.swift
//
//  Propósito: Linhas da lista de histórico em Conquistas, uma para registros
//             diários (com botão de editar quando dentro da janela) e outra para
//             bônus de sequência.
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

                PointsCapsule(text: "\(record.points) \(String(localized: "achievements.points.total", bundle: .gymNutshellCore))",
                              color: accentColor)
            }
            .contentShape(Rectangle())
            .tapButton(perform: onTap)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(String(format: String(localized: "a11y.record.row.daily.format",
                                                     bundle: .gymNutshellCore),
                                       tierName,
                                       A11y.spokenDate(for: record.date),
                                       record.percent, record.points))
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

/// Linha da lista que representa um `StreakBonus`. O "+" no total diferencia
/// pontos de bônus dos pontos diários.
struct HistoryBonusRow: View {
    @AppStorage(AppAccentColor.storageKey) private var storedColorRaw: String = AppAccentColor.blue.rawValue
    private var accentColor: Color { (AppAccentColor(rawValue: storedColorRaw) ?? .blue).color }

    let bonus: StreakBonus
    let onTap: () -> Void

    var body: some View {
        let bTitle = bonus.displayTitle
        let bDesc  = bonus.displayDescription
        HStack(spacing: 16) {
            EmojiBadge(emoji: bonus.displayEmoji, color: accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(bTitle)
                    .font(.headline)

                Text(bDesc)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(bonus.anchorDate, style: .date)
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }

            Spacer()

            PointsCapsule(text: "+\(bonus.bonusPoints) \(String(localized: "achievements.points.total", bundle: .gymNutshellCore))",
                          color: accentColor)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .tapButton(perform: onTap)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: String(localized: "a11y.record.row.bonus.format",
                                                 bundle: .gymNutshellCore),
                                   bTitle, bDesc, bonus.bonusPoints))
        .accessibilityHint(String(localized: "a11y.record.bonus.hint", bundle: .gymNutshellCore))
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

/// Pontos do dia ou do bônus numa cápsula.
private struct PointsCapsule: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.bold).monospacedDigit())
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.12), in: Capsule())
    }
}
