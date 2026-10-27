// ⌘
//  GymNutshell/GymNutshellApp/Views/TodayView/Components/TrackingGoalRowView.swift
//
//  Propósito: Linha em estilo de card pras metas de rastreio (acumulação numérica).
//             Mostra um slider (ou − / +) pra entrada; em categoria check-in, o seletor Pendente | Feito.
//             Os tons de cor refletem o nível de progresso.
//             Dentro de um card agrupado (Hoje, por categoria) perde o card próprio e vira só a linha.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-19.
// ⌘

import SwiftUI
import GymNutshellCore

// MARK: - Linha dentro de card agrupado

extension EnvironmentValues {
    /// true quando a linha está dentro de um card que já tem fundo e divisores (ex: categoria em Hoje).
    @Entry var goalRowGrouped: Bool = false
}

// MARK: - TrackingGoalRowView

// Uma meta de rastreio: card com tint colorido pelo progresso e um slider.
// Cor muda de vermelho→laranja→verde→azul conforme o usuário se aproxima da meta diária.
struct TrackingGoalRowView: View {

    let emoji: String
    let title: String
    let unit: String
    let increment: Int
    let goal: Int
    @Binding var value: Int

    // Quando não-nil, exibe botão OFF/ON à esquerda do valor (usado por Musculação/Cardio).
    // ON = dia de descanso: slider é substituído por texto "Dia de descanso" e conta como meta cumprida.
    var isRestDay: Binding<Bool>? = nil

    // Categoria check-in (ex: Suplemento): seletor Pendente | Feito no lugar do slider ou − / +.
    // Feito grava a meta inteira (a dose); Pendente grava 0.
    var isCheckIn: Bool = false

    // Estilo global dos controles (slider ou − / +), escolhido na Welcome e editável em Ajustes.
    @AppStorage(ControlStyle.storageKey) private var controlStyleRaw: String = ControlStyle.default.rawValue
    private var controlStyle: ControlStyle { ControlStyle(rawValue: controlStyleRaw) ?? .default }

    @AppStorage(AppAccentColor.storageKey) private var storedColorRaw: String = AppAccentColor.blue.rawValue
    private var accentColor: Color { (AppAccentColor(rawValue: storedColorRaw) ?? .blue).color }

    @Environment(\.goalRowGrouped) private var isGrouped

    @Namespace private var checkInNamespace

    // MARK: - Valores derivados

    private var safeGoal: Int { max(goal, 0) }
    private var safeStep: Int { max(increment, 1) }

    private var clampedProgress: Double {
        guard safeGoal > 0 else { return 0 }
        return min(Double(value) / Double(safeGoal), 1)
    }

    // MARK: - Cores baseadas no progresso

    private var progressTint: Color {
        ProgressColors.ring(for: clampedProgress)
    }

    // MARK: - Binding do slider

    // Faz a ponte entre o valor Int e o slider Double.
    // Encaixa nos passos de `increment`, limita em [0, goal], dispara haptic e anima.
    private var sliderBinding: Binding<Double> {
        Binding(
            get: { Double(value) },
            set: { newDouble in
                let clamped = snap(toNearest: newDouble)
                guard clamped != value else { return }
                UISelectionFeedbackGenerator().selectionChanged()
                withAnimation(.easeInOut(duration: 0.12)) {
                    value = clamped
                }
            }
        )
    }

    /// Snap pro alvo válido mais próximo.
    /// Inclui múltiplos do incremento até `safeGoal` E o próprio `safeGoal`, sem isso,
    /// metas que não são múltiplas do incremento (ex: 50 com passo 15) ficam inalcançáveis,
    /// porque o último múltiplo ≤ goal seria 45 e o slider clampa em goal.
    private func snap(toNearest raw: Double) -> Int {
        var targets = stride(from: 0, through: safeGoal, by: safeStep).map { $0 }
        if targets.last != safeGoal { targets.append(safeGoal) }
        let best = targets.min(by: { abs(Double($0) - raw) < abs(Double($1) - raw) }) ?? 0
        return min(max(best, 0), safeGoal)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // Cabeçalho. Estrutura intencional:
            //   1. HStack interno (emoji + título + valor textual) é combinado num
            //      único elemento de a11y, "Meta Água, 30 de 100 ml concluído".
            //   2. Botão rest day fica FORA desse subtree, como elemento focável
            //      independente, com seu próprio label (texto visível "ON"/"OFF")
            //      e hint. Sem isso, o botão era absorvido e virava "rotor action".
            HStack(alignment: .center, spacing: 6) {
                HStack(alignment: .center, spacing: 6) {
                    Text(emoji)
                        .font(.headline)
                        .accessibilityHidden(true)
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                        .layoutPriority(1)
                    Spacer(minLength: 6)
                    // Check-in mostra só a dose; o estado já aparece no seletor.
                    Text(isCheckIn ? "\(safeGoal) \(unit)" : "\(value) / \(safeGoal) \(unit)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(String(format: String(localized: "a11y.goalrow.a11y.label",
                                                         bundle: .gymNutshellCore), title))
                .accessibilityValue(
                    isRestDay?.wrappedValue == true
                    ? A11y.goalRowRestDayValue()
                    : isCheckIn
                    ? "\(checkInStateText), \(safeGoal) \(unit)"
                    : A11y.goalRowValue(current: value, goal: safeGoal, unit: unit)
                )

                // No modo − / + o ON/OFF vai pra linha dos botões (ver stepperRow).
                if let rest = isRestDay, !togglesInControlRow {
                    restDayToggle(isOn: rest)
                }
            }

            // Dia de descanso: o controle continua ocupando o espaço (invisível) e o texto entra
            // por cima, assim a linha não muda de altura ao ligar/desligar o descanso.
            if safeGoal > 0 {
                HStack(spacing: 8) {
                    ZStack {
                        control
                            .opacity(isResting ? 0 : 1)
                            .allowsHitTesting(!isResting)
                            .accessibilityHidden(isResting)
                        if isResting {
                            restDayLabel
                        }
                    }
                    if let rest = isRestDay, togglesInControlRow {
                        roundRestDayToggle(isOn: rest)
                    }
                }
            } else if isResting {
                restDayLabel
            }
        }
        .padding(14)
        .modifier(GoalRowCard(isGrouped: isGrouped))
        .accessibilityElement(children: .contain)
    }

    private var isResting: Bool { isRestDay?.wrappedValue == true }

    /// − / + com dia de descanso: o ON/OFF vira um botão redondo do tamanho do +, à direita dele,
    /// longe do + pra não ser tocado sem querer. No slider ele continua pequeno, no cabeçalho.
    private var togglesInControlRow: Bool {
        controlStyle == .stepper && safeGoal > 0 && isRestDay != nil
    }

    /// Slider ou − / +, conforme o estilo escolhido. O slider tem seu próprio label/value; sem hint
    /// custom porque o sistema já anuncia "ajustável, deslize para cima ou para baixo".
    @ViewBuilder
    private var control: some View {
        if isCheckIn {
            checkInControl
        } else if controlStyle == .stepper {
            stepperControl
        } else {
            Slider(
                value: sliderBinding,
                in: 0...Double(safeGoal)
            )
            .tint(progressTint)
            .accessibilityLabel(A11y.sliderLabel(for: title))
            .accessibilityValue(A11y.goalRowValue(current: value, goal: safeGoal, unit: unit))
        }
    }

    private var restDayLabel: some View {
        Text(String(localized: "today.restday.label", bundle: .gymNutshellCore))
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .transition(.opacity)
            // Já comunicado pelo value do header, esconde para não
            // duplicar "dia de descanso" no VoiceOver.
            .accessibilityHidden(true)
    }

    // MARK: - Check-in (Pendente | Feito)

    private var isDone: Bool { CategoryKind.isCheckInDone(current: value, goal: safeGoal) }

    private var checkInStateText: String {
        String(localized: isDone ? "today.checkin.done" : "today.checkin.pending", bundle: .gymNutshellCore)
    }

    /// Seletor de 2 opções com uma pílula que desliza até a escolhida: vidro no iOS 26+ (com a cor de
    /// destaque em Feito), sólida no iOS 18. Feito com botões, cada um com o traço "selecionado" no VoiceOver.
    private var checkInControl: some View {
        HStack(spacing: 0) {
            checkInSegment(done: false)
            checkInSegment(done: true)
        }
        .padding(4)
        .background(Capsule().fill(Color(.tertiarySystemFill)))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
    }

    private func checkInSegment(done: Bool) -> some View {
        let selected = isDone == done
        return Button {
            setCheckIn(done)
        } label: {
            Text(String(localized: done ? "today.checkin.done" : "today.checkin.pending", bundle: .gymNutshellCore))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selected ? (done ? Color.white : Color.primary) : Color.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background {
                    if selected {
                        checkInThumb(done: done)
                            .matchedGeometryEffect(id: "thumb", in: checkInNamespace)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    @ViewBuilder
    private func checkInThumb(done: Bool) -> some View {
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(done ? .regular.tint(accentColor) : .regular, in: Capsule())
        } else {
            Capsule()
                .fill(done ? accentColor : Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
        }
    }

    private func setCheckIn(_ done: Bool) {
        guard done != isDone else { return }
        if done {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            UISelectionFeedbackGenerator().selectionChanged()
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            value = CategoryKind.checkInValue(done: done, goal: safeGoal)
        }
    }

    // MARK: - Controle − / +

    /// Alternativa ao slider: barra de progresso à esquerda e os botões − / + juntos à direita.
    /// Cada toque anda um passo (`increment`), sempre dentro de [0, goal].
    private var stepperControl: some View {
        HStack(spacing: 14) {
            ProgressView(value: clampedProgress)
                .tint(progressTint)
                .accessibilityHidden(true)

            HStack(spacing: 8) {
                RoundStepButton(kind: .minus, size: 48, color: accentColor, isEnabled: value > 0) {
                    step(by: -safeStep)
                }
                .accessibilityLabel(String(format: String(localized: "a11y.welcome.goal.decrease.format", bundle: .gymNutshellCore), title))

                RoundStepButton(kind: .plus, size: 48, color: accentColor, isEnabled: value < safeGoal) {
                    step(by: safeStep)
                }
                .accessibilityLabel(String(format: String(localized: "a11y.welcome.goal.increase.format", bundle: .gymNutshellCore), title))
            }
        }
    }

    private func step(by delta: Int) {
        let next = min(max(value + delta, 0), safeGoal)
        guard next != value else { return }
        UISelectionFeedbackGenerator().selectionChanged()
        withAnimation(.easeInOut(duration: 0.12)) { value = next }
    }

    // Botão ON/OFF para alternar modo "dia de descanso".
    // ON (vidro neutro, texto na cor de destaque) → tap aciona descanso.
    // OFF (vidro com a cor de destaque) → tap volta o controle com valor zerado.
    // Largura fixa: ON e OFF ocupam o mesmo espaço e o título ao lado não se mexe.
    private func restDayToggle(isOn: Binding<Bool>) -> some View {
        Button {
            toggleRestDay(isOn)
        } label: {
            Text(isOn.wrappedValue
                 ? String(localized: "today.restday.off", bundle: .gymNutshellCore)
                 : String(localized: "today.restday.on", bundle: .gymNutshellCore))
                .font(.caption.weight(.bold))
                .frame(width: 40)
        }
        .restDayToggleStyle(isOn: isOn.wrappedValue, accentColor: accentColor)
        // Sem override de label: o texto visível ("ON"/"OFF") já vira o label
        // do Button automaticamente. Só adiciono o hint dinâmico.
        .accessibilityHint(A11y.restDayToggleHint(currentlyOn: isOn.wrappedValue))
    }

    /// ON/OFF redondo, mesmo tamanho e vidro dos botões − / +.
    private func roundRestDayToggle(isOn: Binding<Bool>) -> some View {
        let resting = isOn.wrappedValue
        let label = Text(resting
                         ? String(localized: "today.restday.off", bundle: .gymNutshellCore)
                         : String(localized: "today.restday.on", bundle: .gymNutshellCore))
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(resting ? Color.white : accentColor)
            .frame(width: 48, height: 48)
        return Group {
            if #available(iOS 26.0, *) {
                Button { toggleRestDay(isOn) } label: { label }
                    .buttonStyle(.plain)
                    .glassEffect(resting ? .regular.tint(accentColor).interactive() : .regular.interactive(),
                                 in: Circle())
            } else {
                Button { toggleRestDay(isOn) } label: { label }
                    .buttonStyle(.plain)
                    .background(Circle().fill(resting ? accentColor : Color(.tertiarySystemFill)))
            }
        }
        .accessibilityHint(A11y.restDayToggleHint(currentlyOn: resting))
    }

    /// ON → liga o descanso (conta como meta cumprida). OFF → volta o controle com valor zerado.
    private func toggleRestDay(_ isOn: Binding<Bool>) {
        UISelectionFeedbackGenerator().selectionChanged()
        withAnimation(.easeInOut(duration: 0.15)) {
            if isOn.wrappedValue {
                isOn.wrappedValue = false
                value = 0
            } else {
                isOn.wrappedValue = true
            }
        }
    }
}

// MARK: - Estilo do ON/OFF

private extension View {

    /// iOS 26+: cápsula de vidro (com a cor de destaque quando o descanso está ligado).
    /// Antes: cápsula sólida como na 1.0.
    @ViewBuilder
    func restDayToggleStyle(isOn: Bool, accentColor: Color) -> some View {
        if #available(iOS 26.0, *) {
            if isOn {
                self.buttonStyle(.glassProminent)
                    .buttonBorderShape(.capsule)
                    .controlSize(.small)
                    .tint(accentColor)
            } else {
                self.buttonStyle(.glass)
                    .buttonBorderShape(.capsule)
                    .controlSize(.small)
                    .tint(accentColor)
            }
        } else {
            self.buttonStyle(.plain)
                .foregroundStyle(isOn ? Color.secondary : accentColor)
                .padding(.vertical, 4)
                .padding(.horizontal, 6)
                .background(
                    Capsule().fill(isOn ? accentColor.opacity(0.25) : Color.secondary.opacity(0.20))
                )
                // No macOS (iPad App on Mac) o Button estica o conteúdo; fixedSize mantém a cápsula justa.
                .fixedSize()
        }
    }
}

// MARK: - Card próprio

/// Card individual da linha; some quando a linha já está num card agrupado.
private struct GoalRowCard: ViewModifier {
    let isGrouped: Bool

    func body(content: Content) -> some View {
        if isGrouped {
            content
        } else {
            let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
            content
                .background { shape.fill(Color(.secondarySystemGroupedBackground)) }
                .clipShape(shape)
                .overlay { shape.stroke(Color.secondary.opacity(0.15), lineWidth: 1) }
        }
    }
}
