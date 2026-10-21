// ⌘
//  GymNutshellWidget/GymNutshellWidget.swift
//
//  Propósito: Widget para iPhone (Small e Medium), mostra o anel de progresso do dia
//             e o tier atual. Lê o WidgetSnapshot escrito pelo app principal via App Group.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-04-29.
// ⌘

import WidgetKit
import SwiftUI
import GymNutshellCore

// MARK: - Entry + Provider

struct GymNutshellWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct GymNutshellWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> GymNutshellWidgetEntry {
        GymNutshellWidgetEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (GymNutshellWidgetEntry) -> Void) {
        let snapshot = WidgetSnapshotStore.load() ?? .placeholder
        completion(GymNutshellWidgetEntry(date: Date(), snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GymNutshellWidgetEntry>) -> Void) {
        let snapshot = WidgetSnapshotStore.load() ?? .placeholder
        // Cria entradas a cada 15min nas próximas 4h. O iOS prioriza reloads de
        // widgets vistos com frequência, e múltiplas entradas dão dicas de cadência.
        // Reloads imediatos ao mudar intake continuam vindo de WidgetCenter.reloadAllTimelines().
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

// MARK: - Widget definition

struct GymNutshellWidget: Widget {
    let kind: String = "GymNutshellWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GymNutshellWidgetProvider()) { entry in
            GymNutshellWidgetEntryView(entry: entry)
                .widgetURL(URL(string: "gymnutshell://today"))
                .containerBackground(for: .widget) {
                    widgetBackground(for: entry)
                }
        }
        .configurationDisplayName("Progresso")
        .description("Acompanhe seu progresso diário.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }

    /// Escolhe o fundo do widget conforme o modo selecionado pelo usuário em Ajustes.
    @ViewBuilder
    private func widgetBackground(for entry: GymNutshellWidgetEntry) -> some View {
        switch WidgetBackgroundStore.loadMode() {
        case .accent:
            let accent = AppAccentColor(rawValue: entry.snapshot.accentColorRaw)?.color ?? .blue
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
}

/// Resolve a cor de progresso usada nos anéis dos widgets, delega pra regra única em Core.
internal func widgetRingColor(progress: Double) -> Color {
    ProgressColors.ring(for: progress)
}

// MARK: - Views

struct GymNutshellWidgetEntryView: View {
    let entry: GymNutshellWidgetEntry
    @Environment(\.widgetFamily) private var family

    private var accent: Color {
        AppAccentColor(rawValue: entry.snapshot.accentColorRaw)?.color ?? .blue
    }

    /// True quando o widget está usando fundo customizado (accent ou custom).
    /// Usado pra decidir se o ring precisa de borda de contraste.
    private var hasCustomBackground: Bool {
        WidgetBackgroundStore.loadMode() != .system
    }

    /// Cor de texto que contrasta com o fundo atual do widget. Branco em fundos escuros,
    /// preto em fundos claros. No modo .system segue `.primary` do iOS.
    private var textColor: Color {
        switch WidgetBackgroundStore.loadMode() {
        case .accent:
            let accentColor = AppAccentColor(rawValue: entry.snapshot.accentColorRaw)?.color ?? .blue
            return WidgetBackground.contrastingForegroundColor(for: accentColor)
        case .custom:
            if let bg = WidgetBackgroundStore.loadCustomColor() {
                return bg.contrastingForegroundColor
            }
            return .primary
        case .system:
            return .primary
        }
    }

    var body: some View {
        Group {
            switch family {
            case .systemMedium: mediumView
            case .accessoryRectangular: lockScreenView
            default: smallView
            }
        }
        // Widget inteiro vira UM único elemento de VoiceOver, sem isso o usuário
        // ouve emoji, tier name e "%" como elementos separados. O label
        // composto reusa a frase de progresso do iPhone.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(format: String(localized: "a11y.widget.summary.points.format",
                                                 bundle: .gymNutshellCore),
                                   entry.snapshot.tierName,
                                   entry.snapshot.progressPercent))
    }

    // MARK: Lock screen (accessoryRectangular)

    /// Layout para a tela de bloqueio: tier emoji + nome em destaque, % abaixo.
    /// Não usa background customizado, a tela de bloqueio aplica vibrant rendering.
    private var lockScreenView: some View {
        HStack(spacing: 8) {
            Text(entry.snapshot.tierEmoji)
                .font(.system(size: 28))
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.snapshot.tierName)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("\(entry.snapshot.progressPercent)%")
                    .font(.caption2)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .widgetAccentable()
    }

    // MARK: Small

    /// Anel com o emoji dentro, no alto e centralizado; a % centralizada embaixo.
    private var smallView: some View {
        VStack(spacing: 6) {
            ring
                .frame(width: 90, height: 90)
            percentText(size: 26)
        }
        .padding(8)
    }

    // MARK: Medium

    /// Anel com o emoji dentro à esquerda; ao lado a % e, embaixo dela, quanto falta pro próximo nível.
    private var mediumView: some View {
        HStack(spacing: 14) {
            ring
                .frame(width: 104, height: 104)
            VStack(alignment: .leading, spacing: 2) {
                percentText(size: 44)
                Text(nextLevelText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(textColor.opacity(0.8))
                    // Sempre numa linha só: encolhe a fonte em vez de quebrar.
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            Spacer(minLength: 0)
        }
        .padding()
    }

    /// Mesma frase do hero da Hoje: quanto falta pro próximo nível, ou o aviso de nível máximo.
    private var nextLevelText: String {
        let percent = entry.snapshot.progressPercent
        guard let next = DailyAchievement.from(percent: percent).next else {
            return String(localized: "today.hero.caption.max", bundle: .gymNutshellCore)
        }
        return String(format: String(localized: "today.hero.caption.nextLevel", bundle: .gymNutshellCore),
                      next.minPercent - percent)
    }

    private func percentText(size: CGFloat) -> some View {
        Text("\(entry.snapshot.progressPercent)%")
            .font(.system(size: size, weight: .bold, design: .rounded).monospacedDigit())
            .foregroundStyle(textColor)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }

    /// Mesmo anel da Hoje, com o emoji da conquista dentro. Em fundo colorido ganha o contorno de contraste.
    private var ring: some View {
        PercentProgressRing(progress: entry.snapshot.progressNormalized,
                            borderColor: hasCustomBackground ? textColor : nil,
                            textColor: textColor,
                            emoji: entry.snapshot.tierEmoji)
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    GymNutshellWidget()
} timeline: {
    GymNutshellWidgetEntry(date: .now, snapshot: .placeholder)
}

#Preview(as: .systemMedium) {
    GymNutshellWidget()
} timeline: {
    GymNutshellWidgetEntry(date: .now, snapshot: .placeholder)
}
