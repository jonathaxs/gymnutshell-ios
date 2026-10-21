// ⌘
//  GymNutshell/GymNutshellCore/Sources/GymNutshellCore/UI/PercentProgressRing.swift
//
//  Propósito: Anel no mesmo desenho do anel da Hoje (espessura do ícone, trilho lavado)
//             com a porcentagem no centro. Usado nos widgets, na prévia deles em Ajustes e no Watch,
//             sempre sem animação. O emoji da conquista fica ao lado, por conta de quem usa.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-10-21.
// ⌘

import SwiftUI

public struct PercentProgressRing: View {

    let progress: Double
    /// Contorno de contraste atrás dos segmentos (widgets com fundo colorido).
    var borderColor: Color?
    var textColor: Color

    public init(progress: Double, borderColor: Color? = nil, textColor: Color = .primary) {
        self.progress = progress
        self.borderColor = borderColor
        self.textColor = textColor
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
                Text("\(percentage)%")
                    .font(.system(size: side * 0.22, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(percentage > 0 ? textColor : textColor.opacity(0.5))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .padding(lineWidth)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
