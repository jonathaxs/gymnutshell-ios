// ⌘
//  GymNutshell/GymNutshellApp/Views/AchievementsView/RecordDetailView.swift
//
//  Propósito: Tela de detalhe somente leitura pra um DailyRecord histórico.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-01-29.
// ⌘

import SwiftUI
import GymNutshellCore

struct RecordDetailView: View {

    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppTheme.storageKey) private var selectedTheme: AppTheme = .gym
    @AppStorage(UserProfile.sexKey) private var sex: String = "male"

    // MARK: - Ações de navegação
    let canEdit: Bool
    let onEdit: () -> Void

    // MARK: - Entradas
    let record: DailyRecord

    // MARK: - Metas
    // Por enquanto usamos as metas padrão do app (provider fixo).
    // No futuro isso pode vir de Settings.
    private let waterGoal: Int = GoalsProvider.water
    private let proteinGoal: Int = GoalsProvider.protein
    private let carbGoal: Int = GoalsProvider.carbs
    private let goodFatGoal: Int = GoalsProvider.goodFat
    private let fiberGoal: Int = GoalsProvider.fiber
    private let sleepGoal: Int = GoalsProvider.sleep

    // MARK: - View
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // Card de resumo pra este dia específico
                let achievement = DailyAchievement.from(emoji: record.achievementEmoji)
                let tierName = selectedTheme.name(for: achievement, sex: sex)
                HStack(spacing: 12) {
                    Text(selectedTheme.emoji(for: achievement))
                        .font(.system(size: 40))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(record.date.formatted(date: .long, time: .omitted))
                            .font(.headline)
                        Text("\(tierName) · \(record.percent)%")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(String(localized: "ring.info.level.label", bundle: .gymNutshellCore) + "\(tierLevel(for: achievement))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(achievement.color, in: RoundedRectangle(cornerRadius: 16))
                .accessibilityElement(children: .combine)
                .accessibilityLabel(String(format: String(localized: "a11y.record.header.format",
                                                         bundle: .gymNutshellCore),
                                           record.date.formatted(date: .long, time: .omitted),
                                           tierName,
                                           record.percent,
                                           tierLevel(for: achievement)))

                Divider()
                    .opacity(0.6)

                // Linhas de métricas somente leitura
                TrackingGoalRow(
                    icon: "💤",
                    title: String(localized: "today.metric.sleep", bundle: .gymNutshellCore),
                    unit: "h",
                    goal: sleepGoal,
                    value: record.sleep
                )

                TrackingGoalRow(
                    icon: "💧",
                    title: String(localized: "today.metric.water", bundle: .gymNutshellCore),
                    unit: "ml",
                    goal: waterGoal,
                    value: record.water
                )

                TrackingGoalRow(
                    icon: "🍗",
                    title: String(localized: "today.metric.protein", bundle: .gymNutshellCore),
                    unit: "g",
                    goal: proteinGoal,
                    value: record.protein
                )

                TrackingGoalRow(
                    icon: "🍞",
                    title: String(localized: "today.metric.carbs", bundle: .gymNutshellCore),
                    unit: "g",
                    goal: carbGoal,
                    value: record.carbs
                )

                TrackingGoalRow(
                    icon: "🧈",
                    title: String(localized: "today.metric.fats", bundle: .gymNutshellCore),
                    unit: "g",
                    goal: goodFatGoal,
                    value: record.goodFat
                )

                TrackingGoalRow(
                    icon: "🌾",
                    title: String(localized: "today.metric.fiber", bundle: .gymNutshellCore),
                    unit: "g",
                    goal: fiberGoal,
                    value: record.fiber
                )

                Spacer(minLength: 0)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(String(localized: "record.detail.title", bundle: .gymNutshellCore))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                SheetCloseButton(title: String(localized: "record.detail.back", bundle: .gymNutshellCore)) {
                    dismiss()
                }
            }

            if canEdit {
                ToolbarItem(placement: .confirmationAction) {
                    SheetToolbarButton(title: String(localized: "record.detail.edit", bundle: .gymNutshellCore),
                                       systemImage: "pencil") {
                        onEdit()
                    }
                }
            }
        }
    }

    private func tierLevel(for achievement: DailyAchievement) -> Int {
        achievement.number
    }

    // MARK: - Notas
    // Essa tela é intencionalmente somente leitura.
    // Quando um registro ainda está dentro da janela de edição, uma ação Editar é exposta
    // via barra de navegação, delegando a edição pra `EditTodayView`.
}

#Preview {
    // NOTA: Previews com modelo do SwiftData podem ser adicionados depois.
    Text("RecordDetailView Preview")
}
