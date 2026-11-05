// ⌘
//  GymNutshell/GymNutshellApp/Views/ProfileView/Components/ProgressOverviewRows.swift
//
//  Propósito: Peças reutilizáveis da ProgressOverView no visual novo: seção com rótulo, linha de nível
//             com barra proporcional, blocos de atividade e linha navegável com ícone.
//             Cada peça encapsula o visual e a acessibilidade.
// ⌘

import SwiftUI
import GymNutshellCore

// MARK: - Seção

/// Rótulo pequeno acima do conteúdo da seção (cards sólidos, sem divisória colorida).
struct ProgressSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AppSectionLabel(text: title)
            content
        }
    }
}

// MARK: - Nível

/// Linha de nível: emoji do mascote, nome, total de dias e barra proporcional ao nível mais frequente.
struct TierRow: View {
    let emoji: String
    let label: String
    let days: Int
    /// Maior contagem entre os níveis, a barra cheia equivale a ela.
    let maxDays: Int
    let accentColor: Color

    var body: some View {
        HStack(spacing: 14) {
            Text(emoji)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(accentColor.opacity(0.12), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(label).font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(String(format: String(localized: "statistics.tier.days", bundle: .gymNutshellCore), days))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: Double(days), total: Double(max(maxDays, 1)))
                    .tint(accentColor)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: String(localized: "a11y.stats.tier.row.format",
                                                 bundle: .gymNutshellCore), label, days))
    }
}

// MARK: - Atividade

/// Bloco de atividade (treino/cardio): emoji, total de dias e nome.
struct ActivityTile: View {
    let emoji: String
    let label: String
    let days: Int

    var body: some View {
        VStack(spacing: 6) {
            Text(emoji)
                .font(.title)
                .accessibilityHidden(true)
            Text("\(days)")
                .font(.system(size: 30, weight: .bold, design: .rounded).monospacedDigit())
            Text(label)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .appCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: String(localized: "a11y.stats.activity.row.format",
                                                 bundle: .gymNutshellCore), label, days))
    }
}

// MARK: - Linha navegável

/// Linha com ícone colorido, título, valor à direita e seta. O toque fica por conta de quem usa.
struct ProgressNavRow: View {
    let icon: String
    let color: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            IconBadge(systemName: icon, color: color, size: 34)
            Text(title)
            Spacer(minLength: 8)
            Text(value)
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 56)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(value)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Pontos e bônus

/// Linha do total de pontos (dias + bônus de sequência).
struct PointsTotalRow: View {
    let total: Int
    let accentColor: Color

    var body: some View {
        let label = String(localized: "statistics.points.total", bundle: .gymNutshellCore)
        HStack(spacing: 14) {
            Image(systemName: "star.fill")
                .font(.title3)
                .foregroundStyle(accentColor)
                .frame(width: 44, height: 44)
                .background(accentColor.opacity(0.12), in: Circle())
                .accessibilityHidden(true)
            Text(label).font(.subheadline.weight(.semibold))
            Spacer()
            Text("\(total)")
                .font(.title3.weight(.bold).monospacedDigit())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue("\(total)")
    }
}

/// Linha de um tipo de bônus: emoji, nome, pontos e quantas vezes saiu.
struct BonusCountRow: View {
    let kind: StreakBonusKind
    let count: Int
    let accentColor: Color

    var body: some View {
        let points = String(format: String(localized: "points.plus.format", bundle: .gymNutshellCore), kind.points)
        HStack(spacing: 14) {
            Text(kind.emoji)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(accentColor.opacity(0.12), in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(kind.title).font(.subheadline.weight(.semibold))
                Text(points)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(String(format: String(localized: "statistics.bonus.times", bundle: .gymNutshellCore), count))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .opacity(count == 0 ? 0.55 : 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: String(localized: "a11y.stats.bonus.row.format",
                                                 bundle: .gymNutshellCore), kind.title, count))
    }
}
