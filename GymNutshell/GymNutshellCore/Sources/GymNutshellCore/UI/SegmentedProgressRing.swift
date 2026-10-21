// ⌘
//  GymNutshell/GymNutshellCore/Sources/GymNutshellCore/UI/SegmentedProgressRing.swift
//
//  Propósito: Anel de progresso em 5 segmentos arredondados, desenhado igual ao ícone do app.
//             Sentido horário a partir do topo: vermelho → amarelo → verde → azul → roxo (20% cada).
//             Cores, contorno, gradiente (claro em cima à esquerda) e espaço entre segmentos foram
//             medidos no AppIcon.png; a espessura do ícone fica em `iconLineWidthRatio`.
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

    /// Espessura do traço em relação ao lado do anel, a mesma do ícone (132 de 732 px).
    public static var iconLineWidthRatio: CGFloat { 0.18 }

    /// Cores fixas dos segmentos (o tom do meio de cada um no ícone), na ordem do sentido horário.
    public static var segmentColors: [Color] { RingSegmentPalette.all.map(\.base) }

    let progress: Double
    var lineWidth: CGFloat = 14
    var fillMode: RingFillMode = Self.defaultFillMode
    /// false em widgets e no Watch: sem animação de preenchimento, sem "pop" e sem haptics.
    var animated: Bool = true
    /// Quando não-nil (widgets com fundo colorido): contorno de 2pt nessa cor em volta da parte
    /// preenchida e o trilho translúcido nessa mesma cor, pra separar o anel do fundo.
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
    @Environment(\.colorScheme) private var colorScheme

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
            // Espaço entre segmentos: compensa as pontas arredondadas + um respiro de 22% da
            // espessura, a mesma proporção do ícone.
            let gapDegrees = Double(lineWidth * 1.22 / max(radius, 1)) * 180 / .pi
            let span = 360.0 / Double(segmentCount)
            // Contorno de cada segmento: ~6% da espessura, como no ícone.
            let rimWidth = max(lineWidth * 0.06, 1)
            let isDark = colorScheme == .dark

            ZStack {
                ForEach(0..<segmentCount, id: \.self) { index in
                    let palette = RingSegmentPalette.all[index]
                    let start = Double(index) * span + gapDegrees / 2
                    let end = Double(index + 1) * span - gapDegrees / 2
                    // No escuro o contorno é a cor clareada; no claro, escurecida.
                    let rim = isDark ? palette.rimOnDark : palette.rimOnLight
                    let corners = Self.gradientCorners(startDegrees: start, endDegrees: end,
                                                       halfWidth: Double(lineWidth / 2 / max(radius * 2, 1)))
                    let filled = RingSegmentShape(startDegrees: start, endDegrees: end, fraction: fraction(for: index))

                    ZStack {
                        if let borderColor {
                            // Fundo colorido: o trilho vira um vidro na cor do texto (a cor lavada some
                            // no fundo) e só a parte preenchida ganha o contorno de contraste em volta.
                            RingSegmentShape(startDegrees: start, endDegrees: end, fraction: 1)
                                .stroke(borderColor.opacity(0.22),
                                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                            filled
                                .stroke(borderColor,
                                        style: StrokeStyle(lineWidth: lineWidth + 4, lineCap: .round))
                        } else {
                            // Trilho do segmento: cinza ou a própria cor, lavada (com o contorno bem fraco).
                            RingSegmentShape(startDegrees: start, endDegrees: end, fraction: 1)
                                .stroke(tintedTrack ? palette.base.opacity(0.2) : Color.secondary.opacity(0.18),
                                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                        }
                        if tintedTrack && borderColor == nil {
                            RingSegmentShape(startDegrees: start, endDegrees: end, fraction: 1)
                                .stroke(style: StrokeStyle(lineWidth: lineWidth - rimWidth, lineCap: .round))
                                .stroke(rim.opacity(0.25), lineWidth: rimWidth)
                        }
                        // Parte preenchida: contorno embaixo (com sombra suave no claro) e o gradiente
                        // por cima, mais fino, deixando só a borda do contorno aparecendo.
                        filled
                            .stroke(rim, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                            .shadow(color: .black.opacity(isDark ? 0 : 0.14),
                                    radius: lineWidth * 0.12, y: lineWidth * 0.1)
                        filled
                            .stroke(LinearGradient(colors: [palette.light, palette.dark],
                                                   startPoint: corners.topLeading,
                                                   endPoint: corners.bottomTrailing),
                                    style: StrokeStyle(lineWidth: lineWidth - rimWidth * 2, lineCap: .round))
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

    // MARK: - Gradiente

    /// Cantos da caixa do segmento inteiro (traço incluído), relativos ao quadro do arco (0...1).
    /// O gradiente vai do canto de cima à esquerda (claro) ao de baixo à direita (escuro), como no
    /// ícone. Usa sempre o segmento cheio pra cor não mudar enquanto ele preenche.
    private static func gradientCorners(startDegrees: Double, endDegrees: Double,
                                        halfWidth: Double) -> (topLeading: UnitPoint, bottomTrailing: UnitPoint) {
        // Pontas do arco + topo/direita/base/esquerda do círculo que caírem dentro dele.
        var angles = [startDegrees, endDegrees]
        for extreme in stride(from: 0.0, through: 360.0, by: 90.0)
        where extreme > startDegrees && extreme < endDegrees {
            angles.append(extreme)
        }
        let xs = angles.map { 0.5 + 0.5 * sin($0 * .pi / 180) }
        let ys = angles.map { 0.5 - 0.5 * cos($0 * .pi / 180) }
        return (UnitPoint(x: xs.min()! - halfWidth, y: ys.min()! - halfWidth),
                UnitPoint(x: xs.max()! + halfWidth, y: ys.max()! + halfWidth))
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

// MARK: - Cores de cada segmento

/// Tons de um segmento, medidos no ícone do app (AppIcon.png e AppIcon-Dark.png).
struct RingSegmentPalette {
    /// Canto de cima à esquerda, onde bate a luz.
    let light: Color
    /// Tom do meio, usado como a cor do segmento no resto do app.
    let base: Color
    /// Canto de baixo à direita.
    let dark: Color
    /// Contorno no modo claro: a cor bem escurecida.
    let rimOnLight: Color
    /// Contorno no modo escuro: a cor bem clareada.
    let rimOnDark: Color

    init(light: UInt32, base: UInt32, dark: UInt32, rimOnLight: UInt32, rimOnDark: UInt32) {
        self.light = Color(rgb: light)
        self.base = Color(rgb: base)
        self.dark = Color(rgb: dark)
        self.rimOnLight = Color(rgb: rimOnLight)
        self.rimOnDark = Color(rgb: rimOnDark)
    }

    /// Na ordem do sentido horário: vermelho, amarelo, verde, azul, roxo.
    static let all: [RingSegmentPalette] = [
        .init(light: 0xFD866C, base: 0xFE6E55, dark: 0xF25C48, rimOnLight: 0x7F382B, rimOnDark: 0xFFB9AD),
        .init(light: 0xFEDB56, base: 0xFEC239, dark: 0xF6AD2A, rimOnLight: 0x83631B, rimOnDark: 0xFBE29C),
        .init(light: 0x6CF4A0, base: 0x46DA7F, dark: 0x38C86E, rimOnLight: 0x267143, rimOnDark: 0xA4EFC0),
        .init(light: 0x67CEFD, base: 0x3CA6FC, dark: 0x2D92EA, rimOnLight: 0x1E547F, rimOnDark: 0x9FD4FF),
        .init(light: 0x5C57A8, base: 0x47468F, dark: 0x3B3A7E, rimOnLight: 0x272650, rimOnDark: 0xA5A3C8)
    ]
}

private extension Color {
    /// Cor sRGB a partir de um hexadecimal 0xRRGGBB.
    init(rgb: UInt32) {
        self.init(.sRGB,
                  red: Double((rgb >> 16) & 0xFF) / 255,
                  green: Double((rgb >> 8) & 0xFF) / 255,
                  blue: Double(rgb & 0xFF) / 255)
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
