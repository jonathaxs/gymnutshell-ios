// ⌘
//  GymNutshell/GymNutshellApp/Views/AchievementsView/Components/AchievementsHistoryRows.swift
//
//  Propósito: Linhas da lista de histórico em Conquistas: registros diários (com os pontos do dia e
//             botão de editar quando dentro da janela) e bônus de sequência.
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

    /// Pontos do dia: o número do nível (1 a 5).
    private var points: Int { DailyAchievement.from(emoji: record.achievementEmoji).points }

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

                PointsCapsule(points: points, color: accentColor)
            }
            .contentShape(Rectangle())
            .tapButton(perform: onTap)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(String(format: String(localized: "a11y.record.row.daily.format",
                                                     bundle: .gymNutshellCore),
                                       tierName,
                                       A11y.spokenDate(for: record.date),
                                       record.percent)
                                + ", " + String(format: String(localized: "a11y.points.plus.format",
                                                               bundle: .gymNutshellCore), points))
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

/// Linha de um bônus de sequência: emoji, nome, descrição, data e os pontos ganhos.
struct HistoryBonusRow: View {
    @AppStorage(AppAccentColor.storageKey) private var storedColorRaw: String = AppAccentColor.blue.rawValue
    private var accentColor: Color { (AppAccentColor(rawValue: storedColorRaw) ?? .blue).color }

    let bonus: EarnedStreakBonus
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            EmojiBadge(emoji: bonus.kind.emoji, color: accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(bonus.kind.title)
                    .font(.headline)

                Text(bonus.kind.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(bonus.anchorDate, style: .date)
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }

            Spacer()

            PointsCapsule(points: bonus.points, color: accentColor)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .tapButton(perform: onTap)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: String(localized: "a11y.record.row.bonus.format",
                                                 bundle: .gymNutshellCore),
                                   bonus.kind.title, A11y.spokenDate(for: bonus.anchorDate), bonus.points))
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

/// Cápsula "+N pts" na cor de destaque, usada nos dias e nos bônus.
private struct PointsCapsule: View {
    let points: Int
    let color: Color

    var body: some View {
        Text(String(format: String(localized: "points.plus.format", bundle: .gymNutshellCore), points))
            .font(.caption.weight(.semibold).monospacedDigit())
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.12), in: Capsule())
            .fixedSize()
            .accessibilityHidden(true)
    }
}
