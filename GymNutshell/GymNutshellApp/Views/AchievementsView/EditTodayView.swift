// ⌘
//  GymNutshell/GymNutshellApp/Views/AchievementsView/EditTodayView.swift
//
//  Propósito: Tela de edição pra atualizar um DailyRecord recente e recalcular o nível e pontos.
//
//  Created by Jonathas Motta (@jonathaxs) on 2025-12-10.
// ⌘

import SwiftUI
import GymNutshellCore
import SwiftData

// MARK: - EditTodayView
// Tela pra editar um DailyRecord existente.
// Reutiliza as mesmas metas e componentes visuais da TodayView.
// Respeita metas removidas pra que a view de edição bata com o que o usuário rastreou naquele dia.
struct EditTodayView: View {

    let record: DailyRecord

    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppTheme.storageKey) private var selectedTheme: AppTheme = .gym
    @AppStorage(UserProfile.sexKey) private var sex: String = "male"

    // MARK: - Valores editáveis, metas explícitas do DailyRecord
    @State private var water: Int
    @State private var protein: Int
    @State private var carbs: Int
    @State private var goodFat: Int
    @State private var fiber: Int
    @State private var sleep: Int

    // Metas de treino e suplementos, lidas do customValues do record (ou didWorkout/didCardio para compat).
    @State private var workoutIntake: Int
    @State private var cardioIntake: Int
    @State private var creatineIntake: Int

    // Metas personalizadas e suas ingestões pra esse registro.
    @State private var customTrackingGoals: [CustomTrackingGoal] = []
    @State private var customTrackingIntakes: [String: Int] = [:]

    // Estado local de "dia de descanso", não persistido no DailyRecord,
    // só afeta o recálculo da porcentagem durante a edição.
    @State private var workoutRestDay: Bool = false
    @State private var cardioRestDay: Bool = false
    @State private var customTrackingRestDays: [String: Bool] = [:]

    // Categorias criadas pelo usuário (pra saber quais suportam ON/OFF).
    @State private var userCategories: [CustomGoalCategory] = []

    // Ordem de exibição das metas e itens removidos.
    @State private var orderedGoalKeys: [String] = []
    @State private var removedItems: Set<String> = []
    @State private var orderedCategories: [GoalCategory] = []

    // MARK: - Metas
    private let waterGoal: Int    = GoalsProvider.water
    private let proteinGoal: Int  = GoalsProvider.protein
    private let carbGoal: Int     = GoalsProvider.carbs
    private let goodFatGoal: Int  = GoalsProvider.goodFat
    private let fiberGoal: Int    = GoalsProvider.fiber
    private let sleepGoal: Int    = GoalsProvider.sleep
    private let workoutGoal: Int  = GoalsProvider.workout
    private let cardioGoal: Int   = GoalsProvider.cardio
    private let creatineGoal: Int = GoalsProvider.creatine

    // MARK: - Initializer
    init(record: DailyRecord) {
        self.record = record
        _water   = State(initialValue: record.water)
        _protein = State(initialValue: record.protein)
        _carbs   = State(initialValue: record.carbs)
        _goodFat = State(initialValue: record.goodFat)
        _fiber   = State(initialValue: record.fiber)
        _sleep   = State(initialValue: record.sleep)

        // Lê workout/cardio/creatina do customValues; usa didWorkout/didCardio como fallback
        // pra registros antigos que ainda não tinham esses valores no dicionário.
        let storedIntakes = (try? JSONDecoder().decode([String: Int].self, from: record.customValues)) ?? [:]
        _workoutIntake  = State(initialValue: storedIntakes["tracking.workout"]  ?? (record.didWorkout ? 1 : 0))
        _cardioIntake   = State(initialValue: storedIntakes["tracking.cardio"]   ?? (record.didCardio  ? 15 : 0))
        _creatineIntake = State(initialValue: storedIntakes["tracking.creatine"] ?? 0)
        // Restaura os flags de "dia de descanso" salvos no record, sem isso o tier
        // recalculado em edição cairia pra level1 mesmo quando o usuário tinha marcado descanso.
        _workoutRestDay = State(initialValue: record.workoutRestDay)
        _cardioRestDay  = State(initialValue: record.cardioRestDay)
        let storedCustomRest = (try? JSONDecoder().decode([String: Bool].self, from: record.customRestDays)) ?? [:]
        _customTrackingRestDays = State(initialValue: storedCustomRest)
    }

    // MARK: - Chaves ativas

    private var activeGoalKeys: [String] {
        orderedGoalKeys.filter { !removedItems.contains($0) }
    }

    // MARK: - Helpers de progresso

    private func progress(for key: String) -> Double {
        switch key {
        case "tracking.workout":  return workoutRestDay ? 1.0 : ProgressHelpers.normalizedProgress(current: workoutIntake,  goal: workoutGoal)
        case "tracking.cardio":   return cardioRestDay  ? 1.0 : ProgressHelpers.normalizedProgress(current: cardioIntake,   goal: cardioGoal)
        case "tracking.sleep":    return ProgressHelpers.normalizedProgress(current: sleep,    goal: sleepGoal)
        case "tracking.water":    return ProgressHelpers.normalizedProgress(current: water,    goal: waterGoal)
        case "tracking.protein":  return ProgressHelpers.normalizedProgress(current: protein,  goal: proteinGoal)
        case "tracking.carbs":    return ProgressHelpers.normalizedProgress(current: carbs,    goal: carbGoal)
        case "tracking.goodFat":  return ProgressHelpers.normalizedProgress(current: goodFat,  goal: goodFatGoal)
        case "tracking.fiber":    return ProgressHelpers.normalizedProgress(current: fiber,    goal: fiberGoal)
        case "tracking.creatine": return ProgressHelpers.normalizedProgress(current: creatineIntake, goal: creatineGoal)
        default: return 0
        }
    }

    private var progressValues: [Double] {
        var values: [Double] = activeGoalKeys.map { progress(for: $0) }
        for trackingGoal in customTrackingGoals {
            if supportsRestDay(for: trackingGoal),
               customTrackingRestDays[trackingGoal.id.uuidString] == true {
                values.append(1.0)
                continue
            }
            let intake = customTrackingIntakes[trackingGoal.id.uuidString] ?? 0
            values.append(ProgressHelpers.normalizedProgress(current: intake, goal: trackingGoal.goal))
        }
        return values
    }

    private func supportsRestDay(for goal: CustomTrackingGoal) -> Bool {
        goal.kind(in: userCategories) == .restDay
    }

    private func restDayBinding(for trackingGoal: CustomTrackingGoal) -> Binding<Bool>? {
        guard supportsRestDay(for: trackingGoal) else { return nil }
        return Binding(
            get: { customTrackingRestDays[trackingGoal.id.uuidString] ?? false },
            set: { customTrackingRestDays[trackingGoal.id.uuidString] = $0 }
        )
    }

    private var dailyProgress: Double {
        guard !progressValues.isEmpty else { return 0 }
        return progressValues.reduce(0, +) / Double(progressValues.count)
    }

    private var dailyPercentage: Int {
        Int((dailyProgress * 100).rounded(.down))
    }

    private var dailyAchievement: DailyAchievement {
        DailyAchievement.from(progress: dailyProgress)
    }

    // MARK: - Construtor de linha de meta

    @ViewBuilder
    private func goalRow(for key: String) -> some View {
        switch key {
        case "tracking.workout":
            TrackingGoalRowView(emoji: "🏋️", title: String(localized: "today.goals.workout", bundle: .gymNutshellCore),
                                unit: "x", increment: DefaultGoals.workoutIncrement,
                                goal: workoutGoal, value: $workoutIntake,
                                isRestDay: $workoutRestDay)
        case "tracking.cardio":
            TrackingGoalRowView(emoji: "🏃", title: String(localized: "today.goals.cardio", bundle: .gymNutshellCore),
                                unit: "min", increment: DefaultGoals.cardioIncrement,
                                goal: cardioGoal, value: $cardioIntake,
                                isRestDay: $cardioRestDay)
        case "tracking.sleep":
            TrackingGoalRowView(emoji: "💤", title: String(localized: "today.metric.sleep", bundle: .gymNutshellCore),
                                unit: "h", increment: 1, goal: sleepGoal, value: $sleep)
        case "tracking.water":
            TrackingGoalRowView(emoji: "💧", title: String(localized: "today.metric.water", bundle: .gymNutshellCore),
                                unit: "ml", increment: 250, goal: waterGoal, value: $water)
        case "tracking.protein":
            TrackingGoalRowView(emoji: "🍗", title: String(localized: "today.metric.protein", bundle: .gymNutshellCore),
                                unit: "g", increment: 20, goal: proteinGoal, value: $protein)
        case "tracking.carbs":
            TrackingGoalRowView(emoji: "🍞", title: String(localized: "today.metric.carbs", bundle: .gymNutshellCore),
                                unit: "g", increment: 20, goal: carbGoal, value: $carbs)
        case "tracking.goodFat":
            TrackingGoalRowView(emoji: "🧈", title: String(localized: "today.metric.fats", bundle: .gymNutshellCore),
                                unit: "g", increment: 5, goal: goodFatGoal, value: $goodFat)
        case "tracking.fiber":
            TrackingGoalRowView(emoji: "🌾", title: String(localized: "today.metric.fiber", bundle: .gymNutshellCore),
                                unit: "g", increment: 5, goal: fiberGoal, value: $fiber)
        case "tracking.creatine":
            TrackingGoalRowView(emoji: "🧪", title: String(localized: "today.goals.creatine", bundle: .gymNutshellCore),
                                unit: "g", increment: DefaultGoals.creatineIncrement,
                                goal: creatineGoal, value: $creatineIntake,
                                isCheckIn: GoalCategory.suplemento.kind == .checkIn)
        default:
            EmptyView()
        }
    }

    // MARK: - Helpers de binding

    private func intakeBinding(for trackingGoal: CustomTrackingGoal) -> Binding<Int> {
        Binding(
            get: { customTrackingIntakes[trackingGoal.id.uuidString] ?? 0 },
            set: { customTrackingIntakes[trackingGoal.id.uuidString] = $0 }
        )
    }

    // MARK: - Seção de categoria

    // Renderiza o cabeçalho e as linhas de meta de uma categoria, ou EmptyView se nenhuma meta ativa estiver nela.
    @ViewBuilder
    private func goalCategorySection(for category: GoalCategory) -> some View {
        let keysInCategory = activeGoalKeys.filter { GoalCategory.defaultCategory(for: $0) == category }
        if !keysInCategory.isEmpty {
            Text(category.displayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 4)
                .accessibilityAddTraits(.isHeader)

            ForEach(keysInCategory, id: \.self) { key in
                goalRow(for: key)
            }
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {

                    // Card de resumo compacto mostrando a data do registro e o nível recalculado.
                    let tierName = selectedTheme.name(for: dailyAchievement, sex: sex)
                    let levelNumber = dailyAchievement.number
                    HStack(spacing: 12) {
                        Text(selectedTheme.emoji(for: dailyAchievement))
                            .font(.system(size: 40))
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.date.formatted(date: .long, time: .omitted))
                                .font(.headline)
                            Text("\(tierName) · \(dailyPercentage)%")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(dailyAchievement.color, in: RoundedRectangle(cornerRadius: 16))
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(String(format: String(localized: "a11y.record.header.format",
                                                             bundle: .gymNutshellCore),
                                               record.date.formatted(date: .long, time: .omitted),
                                               tierName,
                                               dailyPercentage,
                                               levelNumber))

                    // Metas ativas agrupadas por categoria na ordem do usuário.
                    ForEach(orderedCategories, id: \.self) { category in
                        goalCategorySection(for: category)
                    }

                    // Metas personalizadas.
                    ForEach(customTrackingGoals) { trackingGoal in
                        TrackingGoalRowView(
                            emoji: trackingGoal.emoji,
                            title: trackingGoal.name,
                            unit: trackingGoal.unit,
                            increment: trackingGoal.increment,
                            goal: trackingGoal.goal,
                            value: intakeBinding(for: trackingGoal),
                            isRestDay: restDayBinding(for: trackingGoal),
                            isCheckIn: trackingGoal.kind(in: userCategories) == .checkIn
                        )
                    }

                    Spacer()
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "edit.record.cancel", bundle: .gymNutshellCore)) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "edit.record.save", bundle: .gymNutshellCore)) {
                        saveChanges()
                    }
                }
            }
            .onAppear {
                orderedGoalKeys = GoalOrderStore.load()
                removedItems = RemovedItemsStore.load()
                customTrackingGoals = CustomTrackingGoalsStore.load()
                orderedCategories = GoalCategoryOrderStore.load()
                userCategories = CustomGoalCategoriesStore.load()
                // Carrega intakes customizados, excluindo as chaves built-in (tratadas como @State acima).
                // Mantém "tracking.calories" na lista pra que esse valor antigo salvo em customValues
                // seja ignorado e não apareça como meta personalizada.
                if let dict = try? JSONDecoder().decode([String: Int].self, from: record.customValues) {
                    let builtinKeys: Set<String> = ["tracking.calories", "tracking.workout", "tracking.cardio", "tracking.creatine"]
                    customTrackingIntakes = dict.filter { !builtinKeys.contains($0.key) }
                }
            }
        }
    }

    // MARK: - Ações

    private func saveChanges() {
        record.water   = water
        record.protein = protein
        record.carbs   = carbs
        record.goodFat = goodFat
        record.fiber   = fiber
        record.sleep   = sleep

        // Reconstrói o customValues com todos os intakes, built-in novos + customizados.
        var allIntakes = customTrackingIntakes
        allIntakes["tracking.workout"]  = workoutIntake
        allIntakes["tracking.cardio"]   = cardioIntake
        allIntakes["tracking.creatine"] = creatineIntake
        record.customValues = (try? JSONEncoder().encode(allIntakes)) ?? Data()

        // Atualiza os campos booleanos pra manter compatibilidade com as estatísticas.
        record.didWorkout = workoutIntake > 0
        record.didCardio  = cardioIntake  > 0

        // Persistir os flags de descanso pra que reabrir a edição mostre o estado correto.
        record.workoutRestDay = workoutRestDay
        record.cardioRestDay  = cardioRestDay
        record.customRestDays = (try? JSONEncoder().encode(customTrackingRestDays)) ?? Data()

        HealthKitManager.shared.writeSleepIfNeeded(for: record.date, hours: sleep)

        record.percent   = dailyPercentage
        record.achievementTitle = selectedTheme.name(for: dailyAchievement, sex: sex)
        record.achievementEmoji = selectedTheme.emoji(for: dailyAchievement)
        record.points    = dailyAchievement.points

        dismiss()
    }
}

#Preview {
    let sample = DailyRecord(
        water: 1500,
        protein: 80,
        carbs: 200,
        goodFat: 50,
        fiber: 15,
        sleep: 6,
        percent: 70,
        achievementTitle: DailyAchievement.level3.name,
        achievementEmoji: DailyAchievement.level3.emoji,
        points: DailyAchievement.level3.points
    )
    EditTodayView(record: sample)
        .modelContainer(for: DailyRecord.self, inMemory: true)
}
