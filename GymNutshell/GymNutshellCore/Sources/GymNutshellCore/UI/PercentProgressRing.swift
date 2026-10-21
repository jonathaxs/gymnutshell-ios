// ⌘
//  GymNutshell/GymNutshellCore/Sources/GymNutshellCore/UI/PercentProgressRing.swift
//
//  Propósito: Anel no mesmo desenho do anel da Hoje (espessura do ícone, trilho lavado)
//             com a porcentagem ou o emoji da conquista no centro. Usado nos widgets, na prévia deles em
//             Ajustes e no Watch, sempre sem animação.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-10-21.
// ⌘

import SwiftUI

public struct PercentProgressRing: View {

    let progress: Double
    /// Contorno de contraste atrás dos segmentos (widgets com fundo colorido).
    var borderColor: Color?
    var textColor: Color
    /// Quando não-nil, o emoji vai no centro no lugar da % (widgets do iPhone, a % fica fora).
    var emoji: String?

    public init(progress: Double, borderColor: Color? = nil, textColor: Color = .primary,
                emoji: String? = nil) {
        self.progress = progress
        self.borderColor = borderColor
        self.textColor = textColor
        self.emoji = emoji
    }

    /// Truncada, igual à Hoje: "9%" significa "pelo menos 9% feito".
    private var percentage: Int {
        Int((min(max(progress, 0), 1) * 100).rounded(.down))
    }

    public var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let lineWidth = side * SegmentedProgressRing<EmptyView>.iconLineWidthRatio
            SegmentedProgressRing(progress: progress, lineWidth: lineWidth, animated: false,
                                  borderColor: borderColor, tintedTrack: true) {
                if let emoji {
                    Text(emoji)
                        .font(.system(size: side * 0.36))
                        .minimumScaleFactor(0.5)
                        .padding(lineWidth)
                } else {
                    Text("\(percentage)%")
                        .font(.system(size: side * 0.22, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(percentage > 0 ? textColor : textColor.opacity(0.5))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                        .padding(lineWidth)
                }
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
