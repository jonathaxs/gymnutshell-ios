// ⌘
//  GymNutshellWatch/WatchGoalCard.swift
//
//  Propósito: Card de meta do Watch, pílula com preenchimento proporcional ao
//             progresso. Tap expande os controles −/+ e (quando aplicável) o
//             toggle ON/OFF de dia de descanso. Em meta check-in o tap alterna
//             Pendente ↔ Feito direto, sem expandir.
// ⌘

import SwiftUI
import WatchKit
import GymNutshellCore

struct WatchGoalCard: View {
    let entry: GoalEntry
    let isExpanded: Bool
    let accentColor: Color
    /// nil = meta não suporta dia de descanso; true/false = estado atual.
    let restActive: Bool?
    let onToggleExpand: () -> Void
    let onToggleRestDay: () -> Void
    let storageKeyForId: (String) -> String

    var body: some View {
        VStack(spacing: 6) {
            header

            if isExpanded {
                controls
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Header (pílula com fill)

    private var header: some View {
        let progress = ProgressHelpers.normalizedProgress(current: entry.current, goal: entry.goal)
        let tier = DailyAchievement.from(progress: progress)
        let fillColor = tier.color.opacity(0.55)

        return ZStack(alignment: .leading) {
            // Fundo cinza ocupando a largura total.
            Color.secondary.opacity(0.18)

            // Preenchimento proporcional, Rectangle clipado pelo Capsule externo
            // garante que mesmo com largura pequena o fill respeite a curva da pílula.
            GeometryReader { geo in
                Rectangle()
                    .fill(fillColor)
                    .frame(width: geo.size.width * progress)
                    .animation(.easeInOut(duration: 0.25), value: progress)
                    .animation(.easeInOut(duration: 0.25), value: fillColor)
            }

            HStack(spacing: 8) {
                Text(entry.emoji)
                    .font(.title3)
                    .accessibilityHidden(true)
                if restActive == true {
                    Text(String(localized: "today.restday.label", bundle: .gymNutshellCore))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                } else if entry.isCheckIn {
                    Text(checkInStateText)
                        .font(.caption.weight(.semibold))
                    Text("\(entry.goal) \(entry.unit)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(entry.current) / \(entry.goal) \(entry.unit)")
                        .font(.caption.monospacedDigit().weight(.semibold))
                }
                Spacer()
                if entry.isCheckIn {
                    Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(isDone ? accentColor : .secondary)
                        .accessibilityHidden(true)
                } else {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .clipShape(Capsule())
        .contentShape(Capsule())
        .tapButton {
            if entry.isCheckIn {
                toggleCheckIn()
            } else {
                withAnimation(.easeInOut(duration: 0.22)) {
                    onToggleExpand()
                }
            }
        }
        // Header inteiro = 1 botão: "Treino, 0 de 50 minutos, recolhido".
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(entry.displayName)
        .accessibilityValue({
            if entry.isCheckIn {
                return "\(checkInStateText), \(entry.goal) \(entry.unit)"
            }
            let state = isExpanded
                ? String(localized: "a11y.watch.card.expanded", bundle: .gymNutshellCore)
                : String(localized: "a11y.watch.card.collapsed", bundle: .gymNutshellCore)
            if restActive == true {
                return A11y.goalRowRestDayValue() + ", " + state
            }
            return A11y.goalRowValue(current: entry.current, goal: entry.goal, unit: entry.unit)
                + ", " + state
        }())
        .accessibilityHint(String(localized: entry.isCheckIn
            ? (isDone ? "a11y.checkin.hint.markPending" : "a11y.checkin.hint.markDone")
            : (isExpanded ? "a11y.watch.card.hint.collapse" : "a11y.watch.card.hint.expand"),
            bundle: .gymNutshellCore))
    }

    // MARK: - Check-in

    private var isDone: Bool { CategoryKind.isCheckInDone(current: entry.current, goal: entry.goal) }

    private var checkInStateText: String {
        String(localized: isDone ? "today.checkin.done" : "today.checkin.pending", bundle: .gymNutshellCore)
    }

    /// Feito grava a dose inteira; Pendente volta pra 0. Sincroniza com o iPhone igual ao − / +.
    private func toggleCheckIn() {
        let next = CategoryKind.checkInValue(done: !isDone, goal: entry.goal)
        entry.update(next)
        WKInterfaceDevice.current().play(next > 0 ? .success : .click)
        WatchConnectivityManager.shared.sendIntakeUpdate(key: storageKeyForId(entry.id), value: next)
    }

    // MARK: - Controls (−/+ e ON/OFF)

    @ViewBuilder
    private var controls: some View {
        HStack(spacing: 8) {
            // Botão ON/OFF, só pra metas que suportam dia de descanso.
            if restActive != nil {
                onOffButton(isOn: restActive == true)
            }

            if restActive == true {
                // Dia de descanso ativo: − e + somem, mostra "Day off" no espaço deles.
                Text(String(localized: "today.restday.label", bundle: .gymNutshellCore))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 36)
            } else {
                decrementButton
                incrementButton
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }

    private var decrementButton: some View {
        Button {
            let next = max(entry.current - entry.increment, 0)
            entry.update(next)
            WKInterfaceDevice.current().play(.click)
            WatchConnectivityManager.shared.sendIntakeUpdate(key: storageKeyForId(entry.id), value: next)
        } label: {
            Image(systemName: "minus")
                .font(.body.weight(.bold))
                .frame(maxWidth: .infinity, minHeight: 36)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .tint(accentColor)
        .disabled(entry.current <= 0)
        .accessibilityLabel(String(format: String(localized: "a11y.watch.decrease.label.format",
                                                 bundle: .gymNutshellCore), entry.displayName))
        .accessibilityHint(A11y.decrementHint())
    }

    private var incrementButton: some View {
        Button {
            let next = min(entry.current + entry.increment, entry.goal)
            entry.update(next)
            WKInterfaceDevice.current().play(next >= entry.goal ? .success : .click)
            WatchConnectivityManager.shared.sendIntakeUpdate(key: storageKeyForId(entry.id), value: next)
        } label: {
            Image(systemName: "plus")
                .font(.body.weight(.bold))
                .frame(maxWidth: .infinity, minHeight: 36)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .tint(accentColor)
        .disabled(entry.current >= entry.goal)
        .accessibilityLabel(String(format: String(localized: "a11y.watch.increase.label.format",
                                                 bundle: .gymNutshellCore), entry.displayName))
        .accessibilityHint(A11y.incrementHint())
    }

    private func onOffButton(isOn: Bool) -> some View {
        Button {
            onToggleRestDay()
            WKInterfaceDevice.current().play(.click)
        } label: {
            Text(isOn ? "OFF" : "ON")
                .font(.caption.weight(.bold))
                .frame(maxWidth: .infinity, minHeight: 36)
                .foregroundStyle(isOn ? Color.secondary : accentColor)
                .background(
                    Capsule().fill(isOn ? accentColor.opacity(0.25) : Color.secondary.opacity(0.20))
                )
        }
        .buttonStyle(.plain)
        // Sem override de label, texto "ON"/"OFF" do botão já vira label
        // automático. Hint explica o efeito.
        .accessibilityHint(A11y.restDayToggleHint(currentlyOn: isOn))
    }
}
