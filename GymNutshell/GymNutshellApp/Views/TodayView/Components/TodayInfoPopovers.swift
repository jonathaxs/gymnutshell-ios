// ⌘
//  GymNutshell/GymNutshellApp/Views/TodayView/Components/TodayInfoPopovers.swift
//
//  Propósito: Conteúdo dos balões informativos da tela Hoje: conquista (emoji), anel de progresso e data.
//             As páginas completas continuam em Ajustes > Sobre (TierInfoView e ProgressRingInfoView).
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-10-28.
// ⌘

import SwiftUI
import GymNutshellCore

// MARK: - Moldura comum

/// Título + conteúdo, na mesma largura e fundo do balão do modo grade.
private struct TodayInfoPopoverFrame<Content: View>: View {

    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            content
        }
        .padding(16)
        .frame(width: 320)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Conquista

/// Intro, os 5 níveis do tema e o botão de alterar o tema (que abre uma sheet).
struct TierInfoPopover: View {

    let theme: AppTheme
    let sex: String
    let accentColor: Color
    let onChangeTheme: () -> Void

    var body: some View {
        TodayInfoPopoverFrame(title: String(localized: "settings.about.achievement", bundle: .gymNutshellCore)) {
            Text(String(localized: "tier.info.intro", bundle: .gymNutshellCore))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                ForEach(DailyAchievement.allCases, id: \.self) { tier in
                    tierRow(tier)
                }
            }

            Button(action: onChangeTheme) {
                Label(String(localized: "tier.info.change.theme", bundle: .gymNutshellCore),
                      systemImage: "paintpalette")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .tint(accentColor)
        }
    }

    private func tierRow(_ tier: DailyAchievement) -> some View {
        let name = theme.name(for: tier, sex: sex)
        let range = tier.percentRange + String(localized: "tier.info.range.suffix", bundle: .gymNutshellCore)
        return HStack(spacing: 12) {
            Text(theme.emoji(for: tier, sex: sex))
                .font(.title2)
                .frame(width: 36)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                Text(range)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text(String(localized: "ring.info.level.label", bundle: .gymNutshellCore) + "\(tier.number)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(accentColor)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: String(localized: "a11y.tierinfo.row.format", bundle: .gymNutshellCore),
                                   name, range, tier.number))
    }
}

// MARK: - Anel de progresso

/// Intro e as 5 cores do anel, sem a prévia do anel (ele está logo acima do balão).
struct RingInfoPopover: View {

    private var rows: [(label: String, color: Color, range: String)] {
        let suffix = String(localized: "tier.info.range.suffix", bundle: .gymNutshellCore)
        let colors = SegmentedProgressRing<EmptyView>.segmentColors
        return [
            (String(localized: "ring.info.color.red", bundle: .gymNutshellCore),    colors[0], "0 – 20%" + suffix),
            (String(localized: "ring.info.color.orange", bundle: .gymNutshellCore), colors[1], "21 – 40%" + suffix),
            (String(localized: "ring.info.color.green", bundle: .gymNutshellCore),  colors[2], "41 – 60%" + suffix),
            (String(localized: "ring.info.color.cyan", bundle: .gymNutshellCore),   colors[3], "61 – 80%" + suffix),
            (String(localized: "ring.info.color.purple", bundle: .gymNutshellCore), colors[4], "81 – 100%" + suffix)
        ]
    }

    var body: some View {
        TodayInfoPopoverFrame(title: String(localized: "settings.about.progressRing", bundle: .gymNutshellCore)) {
            Text(String(localized: "ring.info.intro", bundle: .gymNutshellCore))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                ForEach(rows, id: \.label) { item in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(item.color)
                            .frame(width: 22, height: 22)
                            .frame(width: 36)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.label)
                                .font(.subheadline.weight(.semibold))
                            Text(item.range)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(String(format: String(localized: "a11y.ringinfo.color.row.format",
                                                             bundle: .gymNutshellCore),
                                               item.label, item.range))
                }
            }
        }
    }
}

// MARK: - Data

/// Data completa e quanto falta pro fim do dia. Atualiza a cada minuto enquanto aberto.
struct DayInfoPopover: View {

    var body: some View {
        TimelineView(.everyMinute) { context in
            let now = context.date
            TodayInfoPopoverFrame(title: Self.fullDate(now)) {
                Text(String(format: String(localized: "today.day.remaining", bundle: .gymNutshellCore),
                            Self.remaining(until: now, style: .abbreviated)))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    // VoiceOver lê a unidade por extenso ("10 horas" em vez de "10 h").
                    .accessibilityLabel(String(format: String(localized: "today.day.remaining",
                                                              bundle: .gymNutshellCore),
                                               Self.remaining(until: now, style: .full)))
            }
        }
    }

    /// "Terça-feira, 28 de outubro de 2026", com a primeira letra maiúscula.
    private static func fullDate(_ date: Date) -> String {
        let text = date.formatted(date: .complete, time: .omitted)
        return text.prefix(1).uppercased() + text.dropFirst()
    }

    /// Tempo até a meia-noite: horas inteiras (arredondadas pra baixo) ou, com menos de 1 hora, minutos.
    private static func remaining(until now: Date, style: DateComponentsFormatter.UnitsStyle) -> String {
        let calendar = Calendar.current
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
        let seconds = max(endOfDay.timeIntervalSince(now), 0)

        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = style
        if seconds >= 3600 {
            formatter.allowedUnits = [.hour]
            return formatter.string(from: floor(seconds / 3600) * 3600) ?? ""
        }
        formatter.allowedUnits = [.minute]
        return formatter.string(from: max(ceil(seconds / 60), 1) * 60) ?? ""
    }
}
