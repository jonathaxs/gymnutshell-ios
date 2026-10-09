// ⌘
//  GymNutshellWidget/LargeWidgetShared.swift
//
//  Propósito: Infra compartilhada pelos widgets systemLarge ("Calendário" e "Metas")
//            , Provider de timeline, helpers de fundo/cor de texto, ring e header.
//             Tudo aqui é interno ao target do widget.
// ⌘

import WidgetKit
import SwiftUI
import GymNutshellCore

// MARK: - Provider compartilhado

struct LargeWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> GymNutshellWidgetEntry {
        GymNutshellWidgetEntry(date: Date(), snapshot: .placeholder)
    }
    func getSnapshot(in context: Context, completion: @escaping (GymNutshellWidgetEntry) -> Void) {
        let snapshot = WidgetSnapshotStore.load() ?? .placeholder
        completion(GymNutshellWidgetEntry(date: Date(), snapshot: snapshot))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<GymNutshellWidgetEntry>) -> Void) {
        let snapshot = WidgetSnapshotStore.load() ?? .placeholder
        let now = Date()
        var entries: [GymNutshellWidgetEntry] = []
        for i in 0..<16 {
            let date = now.addingTimeInterval(TimeInterval(i * 15 * 60))
            entries.append(GymNutshellWidgetEntry(date: date, snapshot: snapshot))
        }
        let nextRefresh = now.addingTimeInterval(15 * 60)
        completion(Timeline(entries: entries, policy: .after(nextRefresh)))
    }
}

// MARK: - Helpers de visual

func largeWidgetTextColor(for snapshot: WidgetSnapshot) -> Color {
    switch WidgetBackgroundStore.loadMode() {
    case .accent:
        let accent = AppAccentColor(rawValue: snapshot.accentColorRaw)?.color ?? .blue
        return WidgetBackground.contrastingForegroundColor(for: accent)
    case .custom:
        if let bg = WidgetBackgroundStore.loadCustomColor() {
            return bg.contrastingForegroundColor
        }
        return .primary
    case .system:
        return .primary
    }
}

@ViewBuilder
func largeWidgetBackground(for snapshot: WidgetSnapshot) -> some View {
    switch WidgetBackgroundStore.loadMode() {
    case .accent:
        let accent = AppAccentColor(rawValue: snapshot.accentColorRaw)?.color ?? .blue
        WidgetBackground.gradient(from: accent)
    case .custom:
        if let bg = WidgetBackgroundStore.loadCustomColor() {
            bg.gradient
        } else {
            Rectangle().fill(.fill.tertiary)
        }
    case .system:
        Rectangle().fill(.fill.tertiary)
    }
}

/// True quando o widget está usando fundo customizado (accent ou custom).
var largeWidgetHasCustomBackground: Bool {
    WidgetBackgroundStore.loadMode() != .system
}

// MARK: - Ring grande reutilizável

struct LargeRing: View {
    let progress: Double
    let emoji: String
    let borderColor: Color?

    var body: some View {
        SegmentedProgressRing(progress: progress, lineWidth: 12,
                              animated: false, borderColor: borderColor) {
            Text(emoji).font(.system(size: 36))
        }
    }
}

// MARK: - Header compartilhado (tier + %)

struct LargeHeader: View {
    let snapshot: WidgetSnapshot
    let textColor: Color

    private var tierPoints: Int {
        switch snapshot.tier {
        case 2: return 40
        case 3: return 60
        case 4: return 90
        default: return 0
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            LargeRing(
                progress: snapshot.progressNormalized,
                emoji: snapshot.tierEmoji,
                borderColor: largeWidgetHasCustomBackground ? textColor : nil
            )
            .frame(width: 86, height: 86)

            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.updatedAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(textColor)
                Text(snapshot.tierName)
                    .font(.headline)
                    .foregroundStyle(textColor)
                    .lineLimit(1)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(snapshot.progressPercent)%")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(textColor)
                    Text(", \(tierPoints) pts")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(textColor)
                }
            }
            Spacer(minLength: 0)
        }
        // Header inteiro vira 1 elemento: "Today, Big Cat, 65 percent, 60 points".
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(format: String(localized: "a11y.widget.large.header.format",
                                                 bundle: .gymNutshellCore),
                                   snapshot.updatedAt.formatted(date: .abbreviated, time: .omitted),
                                   snapshot.tierName,
                                   snapshot.progressPercent,
                                   tierPoints))
    }
}
