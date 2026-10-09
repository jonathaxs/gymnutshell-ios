// ⌘
//  GymNutshell/GymNutshellApp/Views/TodayView/Components/ProgressRingInfoView.swift
//
//  Propósito: View informativa sobre o anel de progresso.
//             Exibida como sheet quando o usuário toca no TodayProgressRingView e
//             também acessível em Configurações > Sobre > Anel de Progresso.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-04-15.
// ⌘

import SwiftUI
import GymNutshellCore

/// Exibe uma explicação sobre o anel de progresso diário:
/// o que ele representa, como a porcentagem é calculada e o que cada segmento significa.
struct ProgressRingInfoView: View {

    var isSheet: Bool = false
    /// Percentual atual do dia (0–100), passado pela TodayHeroView quando aberto como sheet.
    /// nil quando acessado via Settings > Sobre (sem contexto de progresso atual).
    var currentPercent: Int? = nil

    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppAccentColor.storageKey) private var storedColorRaw: String = AppAccentColor.blue.rawValue
    private var accentColor: Color { (AppAccentColor(rawValue: storedColorRaw) ?? .blue).color }

    // Próximo segmento do anel a alcançar, com nome, cor e distância em pontos percentuais.
    // nil quando o anel já está em 100% (completo).
    private var ringNextLevel: (percent: Int, name: String, color: Color, level: Int)? {
        guard let p = currentPercent, p < 100 else { return nil }
        if p < 20 { return (20 - p,  String(localized: "ring.info.color.orange", bundle: .gymNutshellCore), .yellow, 2) }
        if p < 40 { return (40 - p,  String(localized: "ring.info.color.green", bundle: .gymNutshellCore),  .green,  3) }
        if p < 60 { return (60 - p,  String(localized: "ring.info.color.cyan", bundle: .gymNutshellCore),   .blue,   4) }
        if p < 80 { return (80 - p,  String(localized: "ring.info.color.purple", bundle: .gymNutshellCore), .purple, 5) }
        return            (100 - p, String(localized: "ring.info.color.blue", bundle: .gymNutshellCore),   .purple, 6)
    }

    // Segmentos do anel na ordem do sentido horário, 20% cada (mesmas cores do SegmentedProgressRing).
    private var ringColors: [(label: String, color: Color, range: String)] {
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
        List {
            // Intro + frase de progresso na mesma seção pra reduzir o espaço entre eles.
            Section {
                // Prévia do anel com o progresso atual (ou cheio, quando aberto pelos Ajustes).
                SegmentedProgressRing(progress: 1, lineWidth: 10) {
                    EmptyView()
                }
                .frame(width: 96, height: 96)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .accessibilityHidden(true)

                Text(String(localized: "ring.info.intro", bundle: .gymNutshellCore))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)

                if let p = currentPercent, p >= 100 {
                    Text(String(localized: "today.max.level", bundle: .gymNutshellCore))
                        .font(.subheadline.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 4)
                } else if let next = ringNextLevel {
                    (Text(String(localized: "info.next.prefix", bundle: .gymNutshellCore))
                     + Text("\(next.percent)")
                     + Text("%")
                     + Text(String(localized: "info.next.middle", bundle: .gymNutshellCore))
                     + Text("\n")
                     + Text(next.name).foregroundStyle(.primary))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 4)
                }
            }
            .listRowBackground(Color.clear)

            // Seção das cores, sem indicador de nível.
            Section(String(localized: "ring.info.section.colors", bundle: .gymNutshellCore)) {
                ForEach(ringColors, id: \.label) { item in
                    HStack(spacing: 14) {
                        Circle()
                            .fill(item.color)
                            .frame(width: 24, height: 24)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.label)
                                .font(.subheadline.weight(.semibold))
                            Text(item.range)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(String(format: String(localized: "a11y.ringinfo.color.row.format",
                                                             bundle: .gymNutshellCore),
                                               item.label, item.range))
                }
            }
        }
        .navigationTitle(String(localized: "settings.about.progressRing", bundle: .gymNutshellCore))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isSheet {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text(String(localized: "common.close", bundle: .gymNutshellCore))
                            .foregroundStyle(accentColor)
                    }
                }
            }
        }
    }
}
