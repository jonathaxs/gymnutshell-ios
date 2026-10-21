// ⌘
//  GymNutshell/GymNutshellCore/Sources/GymNutshellCore/UI/SegmentedProgressRing.swift
//
//  Propósito: Anel de progresso em 5 segmentos arredondados, no estilo do ícone do app.
//             Sentido horário a partir do topo: vermelho → amarelo → verde → azul → roxo (20% cada).
//             Ao entrar numa cor nova o anel inteiro pulsa (escala sobe e volta).
//             Conteúdo opcional no centro (ex: emoji da conquista).
//             Com `tintedTrack` o trilho já mostra a cor de cada segmento, lavada, e acende ao preencher.
//             Vive no Core pra ser usado no app, no Watch e nos widgets (sem animação nem haptics lá).
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-10-08.
// ⌘

import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Como cada segmento é preenchido.
public enum RingFillMode {
    /// A cor avança aos poucos dentro do segmento, sobre o trilho cinza.
    case gradual
    /// O segmento só acende (inteiro) quando os 20% dele são completados.
    case whole
}

public struct SegmentedProgressRing<Center: View>: View {

    /// Troque aqui pra testar o outro modo de preenchimento em todo o app.
    public static var defaultFillMode: RingFillMode { .gradual }

    /// Cores fixas dos segmentos, na ordem do sentido horário.
    public static var segmentColors: [Color] { [.red, .yellow, .green, .blue, .purple] }

    let progress: Double
    var lineWidth: CGFloat = 14
    var fillMode: RingFillMode = Self.defaultFillMode
    /// false em widgets e no Watch: sem animação de preenchimento, sem "pop" e sem haptics.
    var animated: Bool = true
    /// Quando não-nil, desenha um contorno de 2pt nessa cor atrás dos segmentos, pra separar
    /// o anel de fundos coloridos (widgets com fundo customizado).
    var borderColor: Color? = nil
    /// true = trilho na cor do segmento, bem clara (hero da Today); false = trilho cinza.
    var tintedTrack: Bool = false
    @ViewBuilder var center: Center

    public init(progress: Double,
                lineWidth: CGFloat = 14,
                fillMode: RingFillMode = SegmentedProgressRing.defaultFillMode,
                animated: Bool = true,
                borderColor: Color? = nil,
                tintedTrack: Bool = false,
                @ViewBuilder center: () -> Center) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.fillMode = fillMode
        self.animated = animated
        self.borderColor = borderColor
        self.tintedTrack = tintedTrack
        self.center = center()
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Escala do anel inteiro, usada no pulso ao entrar numa cor nova.
    @State private var pulseScale: CGFloat = 1

    private var segmentCount: Int { Self.segmentColors.count }

    private var clampedProgress: Double { min(max(progress, 0), 1) }

    /// Quantos segmentos estão completos (0...5).
    private var completedCount: Int {
        // Pequena folga pra 0.6 * 5 não virar 2.9999 por arredondamento.
        Int((clampedProgress * Double(segmentCount)) + 0.0001)
    }

    /// Preenchimento de um segmento (0...1).
    private func fraction(for index: Int) -> Double {
        let raw = min(max(clampedProgress * Double(segmentCount) - Double(index), 0), 1)
        switch fillMode {
        case .gradual: return raw
        case .whole:   return index < completedCount ? 1 : 0
        }
    }

    public var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let radius = (side - lineWidth) / 2
            // Espaço entre segmentos: compensa as pontas arredondadas + um respiro visível.
            let gapDegrees = Double((lineWidth + 4) / max(radius, 1)) * 180 / .pi
            let span = 360.0 / Double(segmentCount)

            ZStack {
                ForEach(0..<segmentCount, id: \.self) { index in
                    let start = Double(index) * span + gapDegrees / 2
                    let end = Double(index + 1) * span - gapDegrees / 2

                    ZStack {
                        if let borderColor {
                            RingSegmentShape(startDegrees: start, endDegrees: end, fraction: 1)
                                .stroke(borderColor,
                                        style: StrokeStyle(lineWidth: lineWidth + 4, lineCap: .round))
                        }
                        // Trilho do segmento: cinza ou a própria cor, lavada.
                        RingSegmentShape(startDegrees: start, endDegrees: end, fraction: 1)
                            .stroke(tintedTrack ? Self.segmentColors[index].opacity(0.2)
                                                : Color.secondary.opacity(0.18),
                                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                        // Parte preenchida, na cor do segmento.
                        RingSegmentShape(startDegrees: start, endDegrees: end, fraction: fraction(for: index))
                            .stroke(Self.segmentColors[index],
                                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    }
                    .padding(lineWidth / 2)
                }

                center
            }
            .scaleEffect(pulseScale)
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .animation(reduceMotion || !animated ? nil : .easeInOut(duration: 0.45), value: clampedProgress)
        .onChange(of: completedCount) { old, new in
            // Entrou numa cor nova (ex: vermelho → amarelo): o anel inteiro pulsa uma vez.
            guard new > old, !reduceMotion, animated else { return }
            pulse(delay: 0.35)
        }
    }

    // MARK: - Pulso

    private func pulse(delay: Double) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            #endif
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                pulseScale = 1.08
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    pulseScale = 1
                }
            }
        }
    }
}

// MARK: - Forma de um segmento

/// Arco de um segmento. Ângulos em graus a partir do topo, sentido horário.
/// `fraction` é animável pra cor avançar suavemente dentro do segmento.
public struct RingSegmentShape: Shape {

    public var startDegrees: Double
    public var endDegrees: Double
    public var fraction: Double

    public init(startDegrees: Double, endDegrees: Double, fraction: Double) {
        self.startDegrees = startDegrees
        self.endDegrees = endDegrees
        self.fraction = fraction
    }

    public var animatableData: Double {
        get { fraction }
        set { fraction = newValue }
    }

    public func path(in rect: CGRect) -> Path {
        guard fraction > 0.001 else { return Path() }
        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let end = startDegrees + (endDegrees - startDegrees) * min(fraction, 1)
        var path = Path()
        // -90 leva o zero pro topo; clockwise false = horário na tela (eixo y invertido).
        path.addArc(center: center, radius: radius,
                    startAngle: .degrees(startDegrees - 90),
                    endAngle: .degrees(end - 90),
                    clockwise: false)
        return path
    }
}
