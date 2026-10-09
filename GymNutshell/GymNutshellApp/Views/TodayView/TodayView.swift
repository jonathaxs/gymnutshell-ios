// ⌘
//  GymNutshell/GymNutshellApp/Views/TodayView/TodayView.swift
//
//  Propósito: Tela principal "Hoje", onde o usuário acompanha todas as metas diárias com sliders.
//             O bloco hero mostra a data de hoje, o nível de conquista, o anel de progresso e a frase do próximo nível.
//             No iPhone as metas ficam em blocos por categoria; tocar abre um balão com os controles.
//             No layout largo (iPad) continua a lista/grade completa.
//
//  Created by Jonathas Motta (@jonathaxs) on 2025-08-16.
// ⌘

import SwiftUI
import GymNutshellCore
import SwiftData
internal import Combine

struct TodayView: View {

    // MARK: - Valores diários persistidos

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    // Metas de treino
    @AppStorage("workoutIntake")  private var workoutIntake:  Int = 0
    @AppStorage("cardioIntake")   private var cardioIntake:   Int = 0

    // Dia de descanso, quando true, a meta conta como cumprida sem slider.
    @AppStorage("workoutRestDay") private var workoutRestDay: Bool = false
    @AppStorage("cardioRestDay")  private var cardioRestDay:  Bool = false

    // Recuperação
    @AppStorage("sleepHours")     private var sleepHours:     Int = 0

    // Hidratação
    @AppStorage("waterIntake")    private var waterIntake:    Int = 0

    // Energia
    @AppStorage("caloriesIntake") private var caloriesIntake: Int = 0

    // Macros
    @AppStorage("proteinIntake")  private var proteinIntake:  Int = 0
    @AppStorage("carbIntake")     private var carbIntake:     Int = 0
    @AppStorage("goodFatIntake")  private var goodFatIntake:  Int = 0
    @AppStorage("fiberIntake")    private var fiberIntake:    Int = 0

    // Suplementos
    @AppStorage("creatineIntake") private var creatineIntake: Int = 0

    @AppStorage("lastFinishedDate") private var lastFinishedDate: String = ""

    // Metas personalizadas e seus valores diários.
    @State private var customTrackingGoals: [CustomTrackingGoal] = []
    @State private var customTrackingIntakes: [String: Int] = [:]
    // Estado "dia de descanso" das metas personalizadas da categoria Treino
    // e das categorias criadas pelo usuário que ativam o botão ON/OFF.
    @State private var customTrackingRestDays: [String: Bool] = [:]
    // Categorias criadas pelo usuário.
    @State private var userCategories: [CustomGoalCategory] = []
    // Ordem unificada (fixas + personalizadas) pra renderização em Hoje.
    @State private var unifiedCategoryItems: [CategoryItem] = []

    // Ordem de exibição das metas e itens built-in removidos.
    @State private var orderedGoalKeys: [String] = []
    @State private var removedItems: Set<String> = []

    // Sistema de medida, controla a unidade de exibição da água (ml vs fl oz).
    @AppStorage(UserProfile.measurementSystemKey) private var measurementSystem: MeasurementSystem = .metric

    // Tema de mascote selecionado, controla quais emojis e nomes de tier são exibidos.
    @AppStorage(AppTheme.storageKey) private var selectedTheme: AppTheme = .gym

    // Auto detecção de treinos do Apple Health.
    @AppStorage("healthkit.autoWorkoutCheckin") private var autoWorkoutCheckin: Bool = false

    // Estado de colapso das categorias de metas na TodayView.
    @AppStorage("today.goal.collapsed") private var todayCollapsedRaw: String = ""

    // Ordem das categorias, sincronizada com TrackingGoalsSettingsView.
    @State private var orderedCategories: [GoalCategory] = GoalCategoryOrderStore.defaultOrder


    // MARK: - Constantes de layout

    private enum UI {
        static let wideThreshold: CGFloat    = 700
        static let heroColumnWidth: CGFloat  = 360
        static let contentMaxWidth: CGFloat  = 330
        static let heroAreaMinHeight: CGFloat = 250
        static let heroAreaMaxHeight: CGFloat = 310
        static let heroAreaRatio: CGFloat    = 0.32
        static let sectionSpacing: CGFloat   = 15
        static let rowSpacing: CGFloat       = 10
        static let heroInnerSpacing: CGFloat = 12
        static let wideHStackSpacing: CGFloat = 24
    }

    // MARK: - Valores fixos das metas

    private let workoutGoal:  Int = GoalsProvider.workout
    private let cardioGoal:   Int = GoalsProvider.cardio
    private let sleepGoal:    Int = GoalsProvider.sleep
    private let caloriesGoal: Int = GoalsProvider.calories
    private let proteinGoal:  Int = GoalsProvider.protein
    private let carbGoal:     Int = GoalsProvider.carbs
    private let goodFatGoal:  Int = GoalsProvider.goodFat
    private let fiberGoal:    Int = GoalsProvider.fiber
    private let creatineGoal: Int = GoalsProvider.creatine

    // MARK: - Helpers de exibição de água (imperial converte ml ↔ fl oz na camada de UI)

    private var waterGoal: Int { GoalsProvider.water }

    private var waterIntakeBinding: Binding<Int> {
        if measurementSystem == .us {
            return Binding(
                get: { Int(UnitConverter.mlToFlOz(Double(waterIntake)).rounded()) },
                set: { waterIntake = Int(UnitConverter.flOzToMl(Double($0)).rounded()) }
            )
        }
        return $waterIntake
    }

    private var waterGoalDisplay: Int {
        measurementSystem == .us
            ? Int(UnitConverter.mlToFlOz(Double(waterGoal)).rounded())
            : waterGoal
    }

    private var waterUnit: String   { measurementSystem == .us ? "fl oz" : "ml" }
    private var waterIncrement: Int { measurementSystem == .us ? 8 : 250 }

    // MARK: - Categorias de metas

    private var todayCollapsedCategories: Set<String> {
        Set(todayCollapsedRaw.split(separator: ",").map(String.init).filter { !$0.isEmpty })
    }

    private func isTodayCategoryCollapsed(_ key: String) -> Bool {
        todayCollapsedCategories.contains(key)
    }

    private func toggleTodayCategory(_ key: String) {
        var current = todayCollapsedCategories
        if current.contains(key) {
            current.remove(key)
        } else {
            current.insert(key)
        }
        todayCollapsedRaw = current.joined(separator: ",")
    }

    private var uncategorizedCustomGoals: [CustomTrackingGoal] {
        customTrackingGoals.filter { $0.category == nil && $0.customCategoryId == nil }
    }

    private func customGoalsFor(customCategoryId: String) -> [CustomTrackingGoal] {
        customTrackingGoals.filter { $0.customCategoryId == customCategoryId }
    }

    // Retorna se a categoria (fixa ou customizada) aceita dia de descanso.
    private func supportsRestDay(for goal: CustomTrackingGoal) -> Bool {
        if goal.category == .treino { return true }
        if let customId = goal.customCategoryId,
           let found = userCategories.first(where: { $0.id == customId }) {
            return found.supportsRestDay
        }
        return false
    }

    // MARK: - Chaves ativas

    private var activeGoalKeys: [String] {
        orderedGoalKeys.filter { !removedItems.contains($0) }
    }

    // MARK: - Cálculos de progresso

    private func progress(for key: String) -> Double {
        switch key {
        case "tracking.workout":  return workoutRestDay ? 1.0 : ProgressHelpers.normalizedProgress(current: workoutIntake,  goal: workoutGoal)
        case "tracking.cardio":   return cardioRestDay  ? 1.0 : ProgressHelpers.normalizedProgress(current: cardioIntake,   goal: cardioGoal)
        case "tracking.sleep":    return ProgressHelpers.normalizedProgress(current: sleepHours,     goal: sleepGoal)
        case "tracking.water":    return ProgressHelpers.normalizedProgress(current: waterIntake,    goal: waterGoal)
        case "tracking.calories": return ProgressHelpers.normalizedProgress(current: caloriesIntake, goal: caloriesGoal)
        case "tracking.protein":  return ProgressHelpers.normalizedProgress(current: proteinIntake,  goal: proteinGoal)
        case "tracking.carbs":    return ProgressHelpers.normalizedProgress(current: carbIntake,     goal: carbGoal)
        case "tracking.goodFat":  return ProgressHelpers.normalizedProgress(current: goodFatIntake,  goal: goodFatGoal)
        case "tracking.fiber":    return ProgressHelpers.normalizedProgress(current: fiberIntake,    goal: fiberGoal)
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

    // MARK: - Formatação de data

    private var formattedDate: String {
        AppDateFormatters.longDate(for: Date())
    }

    private func dateString(from date: Date) -> String {
        AppDateFormatters.dayKey.string(from: date)
    }

    // MARK: - Helpers de binding

    private func intakeBinding(for trackingGoal: CustomTrackingGoal) -> Binding<Int> {
        Binding(
            get: { customTrackingIntakes[trackingGoal.id.uuidString] ?? 0 },
            set: { newValue in
                customTrackingIntakes[trackingGoal.id.uuidString] = newValue
                CustomTrackingIntakesStore.save(customTrackingIntakes)
            }
        )
    }

    // Binding de "dia de descanso" só para metas cuja categoria aceita ON/OFF.
    // Retorna nil pras outras, TrackingGoalRowView então esconde o botão.
    private func restDayBinding(for trackingGoal: CustomTrackingGoal) -> Binding<Bool>? {
        guard supportsRestDay(for: trackingGoal) else { return nil }
        return Binding(
            get: { customTrackingRestDays[trackingGoal.id.uuidString] ?? false },
            set: { newValue in
                customTrackingRestDays[trackingGoal.id.uuidString] = newValue
                CustomTrackingRestDaysStore.save(customTrackingRestDays)
            }
        )
    }

    // MARK: - Linhas de metas built-in

    @ViewBuilder
    private func goalRow(for key: String) -> some View {
        switch key {
        case "tracking.workout":
            TrackingGoalRowView(emoji: "🏋️", title: String(localized: "today.goals.workout", bundle: .gymNutshellCore),
                                unit: "min", increment: DefaultGoals.workoutIncrement,
                                goal: workoutGoal, value: $workoutIntake,
                                isRestDay: $workoutRestDay)
        case "tracking.cardio":
            TrackingGoalRowView(emoji: "🏃", title: String(localized: "today.goals.cardio", bundle: .gymNutshellCore),
                                unit: "min", increment: DefaultGoals.cardioIncrement,
                                goal: cardioGoal, value: $cardioIntake,
                                isRestDay: $cardioRestDay)
        case "tracking.sleep":
            TrackingGoalRowView(emoji: "💤", title: String(localized: "today.metric.sleep", bundle: .gymNutshellCore),
                                unit: "h", increment: 1, goal: sleepGoal, value: $sleepHours)
        case "tracking.water":
            TrackingGoalRowView(emoji: "💧", title: String(localized: "today.metric.water", bundle: .gymNutshellCore),
                                unit: waterUnit, increment: waterIncrement,
                                goal: waterGoalDisplay, value: waterIntakeBinding)
        case "tracking.calories":
            TrackingGoalRowView(emoji: "🔥", title: String(localized: "today.metric.calories", bundle: .gymNutshellCore),
                                unit: "kcal", increment: DefaultGoals.caloriesIncrement,
                                goal: caloriesGoal, value: $caloriesIntake)
        case "tracking.protein":
            TrackingGoalRowView(emoji: "🍗", title: String(localized: "today.metric.protein", bundle: .gymNutshellCore),
                                unit: "g", increment: 20, goal: proteinGoal, value: $proteinIntake)
        case "tracking.carbs":
            TrackingGoalRowView(emoji: "🍞", title: String(localized: "today.metric.carbs", bundle: .gymNutshellCore),
                                unit: "g", increment: 20, goal: carbGoal, value: $carbIntake)
        case "tracking.goodFat":
            TrackingGoalRowView(emoji: "🧈", title: String(localized: "today.metric.fats", bundle: .gymNutshellCore),
                                unit: "g", increment: 5, goal: goodFatGoal, value: $goodFatIntake)
        case "tracking.fiber":
            TrackingGoalRowView(emoji: "🌾", title: String(localized: "today.metric.fiber", bundle: .gymNutshellCore),
                                unit: "g", increment: 5, goal: fiberGoal, value: $fiberIntake)
        case "tracking.creatine":
            TrackingGoalRowView(emoji: "🧪", title: String(localized: "today.goals.creatine", bundle: .gymNutshellCore),
                                unit: "g", increment: DefaultGoals.creatineIncrement,
                                goal: creatineGoal, value: $creatineIntake)
        default:
            EmptyView()
        }
    }

    // MARK: - Auto detecção de treinos do Apple Health

    // Quando o HealthKit detecta um treino, seta os valores das metas de treino/cardio.
    // Só seta quando o valor ainda está zerado, nunca sobrescreve o que o usuário já registrou.
    private func checkWorkoutsFromHealth() {
        guard autoWorkoutCheckin else { return }
        HealthKitManager.shared.checkTodayWorkouts { workoutMinutes, cardioMinutes, workoutName, cardioName in
            if workoutMinutes > 0 && workoutIntake == 0 {
                workoutIntake = min(workoutMinutes, workoutGoal)
                NotificationManager.shared.fireHealthLogged(
                    .workout, value: workoutIntake, activityName: workoutName
                )
            }
            if cardioMinutes > 0 && cardioIntake == 0 {
                cardioIntake = min(cardioMinutes, cardioGoal)
                NotificationManager.shared.fireHealthLogged(
                    .cardio, value: cardioIntake, activityName: cardioName
                )
            }
        }
    }

    // MARK: - Gerenciamento do dia

    private func finishSpecificDay(_ date: Date) {
        // Inclui os intakes das novas metas built-in no dicionário de valores customizados.
        var allIntakes = customTrackingIntakes
        allIntakes["tracking.calories"] = caloriesIntake
        allIntakes["tracking.workout"]  = workoutIntake
        allIntakes["tracking.cardio"]   = cardioIntake
        allIntakes["tracking.creatine"] = creatineIntake

        let record = DailyRecord(
            date: date,
            water: waterIntake,
            protein: proteinIntake,
            carbs: carbIntake,
            goodFat: goodFatIntake,
            fiber: fiberIntake,
            sleep: sleepHours,
            percent: dailyPercentage,
            achievementTitle: selectedTheme.name(for: dailyAchievement),
            achievementEmoji: selectedTheme.emoji(for: dailyAchievement),
            points: dailyAchievement.points
        )
        record.customValues = (try? JSONEncoder().encode(allIntakes)) ?? Data()
        // Só conta como dia de musculação/cardio se o usuário realmente registrou atividade.
        // Dia de descanso já foi contabilizado no `dailyPercentage`, mas não entra no contador de Atividade.
        record.didWorkout = workoutIntake > 0
        record.didCardio  = cardioIntake  > 0
        // Persistir rest-day flags pra que EditTodayView recalcule o tier corretamente
        // sem assumir que workout/cardio ficaram em 0.
        record.workoutRestDay = workoutRestDay
        record.cardioRestDay  = cardioRestDay
        record.customRestDays = (try? JSONEncoder().encode(customTrackingRestDays)) ?? Data()
        modelContext.insert(record)
        HealthKitManager.shared.writeSleepIfNeeded(for: date, hours: sleepHours)
    }

    private func finishDay() {
        workoutIntake  = 0
        cardioIntake   = 0
        workoutRestDay = false
        cardioRestDay  = false
        sleepHours     = 0
        waterIntake    = 0
        caloriesIntake = 0
        proteinIntake  = 0
        carbIntake     = 0
        goodFatIntake  = 0
        fiberIntake    = 0
        creatineIntake = 0
        customTrackingIntakes = [:]
        CustomTrackingIntakesStore.reset()
        customTrackingRestDays = [:]
        CustomTrackingRestDaysStore.reset()
    }

    private func checkIfNewDay() {
        let todayString = dateString(from: Date())

        if lastFinishedDate.isEmpty {
            lastFinishedDate = todayString
            return
        }

        if todayString == lastFinishedDate { return }

        let calendar = Calendar.current

        guard let lastDate = AppDateFormatters.dayKey.date(from: lastFinishedDate) else {
            lastFinishedDate = todayString
            finishDay()
            return
        }

        // 1) Salva o último dia real com os dados reais do usuário.
        finishSpecificDay(lastDate)

        // 1b) Notifica o usuário sobre a conquista que ele desbloqueou no dia anterior.
        //     O tier é computado com base nos intakes salvos (ainda não foram zerados).
        NotificationManager.shared.fireAchievementUnlocked(
            tierName: selectedTheme.name(for: dailyAchievement),
            emoji: selectedTheme.emoji(for: dailyAchievement),
            date: lastDate
        )

        // 2) Reseta as métricas antes de preencher os dias perdidos.
        finishDay()

        // 3) Gera registros Beginner pra qualquer dia perdido.
        var cursor = calendar.date(byAdding: .day, value: 1, to: lastDate)!
        let todayStart = calendar.startOfDay(for: Date())

        while cursor < todayStart {
            let missed = DailyAchievement.level1
            let sadRecord = DailyRecord(
                date: cursor,
                water: 0, protein: 0, carbs: 0, goodFat: 0, fiber: 0, sleep: 0,
                percent: 0,
                achievementTitle: selectedTheme.name(for: missed),
                achievementEmoji: selectedTheme.emoji(for: missed),
                points: missed.points
            )
            modelContext.insert(sadRecord)
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor)!
        }

        // 4) Marca hoje como o novo dia corrente.
        lastFinishedDate = todayString

        // 5) Verifica se os dias concluídos desbloquearam algum bônus semanal ou mensal.
        StreakBonusChecker.evaluateAndAward(into: modelContext)
    }

    // MARK: - Bloco hero

    private func heroBlock(vertical: Bool, card: Bool = false) -> some View {
        // O modo vertical (progresso em cima, conquista embaixo) só faz sentido quando
        // sobra altura, controlado pelo chamador via tamanho real da janela, não pelo
        // idiom do dispositivo. Assim, iPad em modo "janela pequena" (iOS 26 multi-window)
        // cai pro layout horizontal igual iPhone sem precisar de detecção especial.
        TodayHeroView(
            formattedDate: formattedDate,
            dailyAchievement: dailyAchievement,
            dailyProgress: dailyProgress,
            selectedTheme: selectedTheme,
            verticalLayout: vertical,
            cardStyle: card
        )
    }

    // MARK: - Conteúdo das metas (agrupado por categoria)

    @ViewBuilder
    private var goalsContent: some View {
        // Renderiza fixas e personalizadas na ordem unificada escolhida pelo usuário.
        ForEach(unifiedCategoryItems) { item in
            switch item {
            case .builtin(let category):  todayCategorySection(category)
            case .custom(let category):   todayCustomCategorySection(category)
            }
        }
        // Metas personalizadas sem categoria ficam no final.
        ForEach(uncategorizedCustomGoals) { goal in
            TrackingGoalRowView(
                emoji: goal.emoji,
                title: goal.name,
                unit: goal.unit,
                increment: goal.increment,
                goal: goal.goal,
                value: intakeBinding(for: goal),
                isRestDay: restDayBinding(for: goal)
            )
        }
    }

    // Header + conteúdo colapsável para uma categoria criada pelo usuário.
    @ViewBuilder
    private func todayCustomCategorySection(_ customCategory: CustomGoalCategory) -> some View {
        let goals = customGoalsFor(customCategoryId: customCategory.id)
        if !goals.isEmpty {
            todayCustomCategoryHeader(customCategory)
            if !isTodayCategoryCollapsed(customCategory.id) {
                VStack(spacing: 10) {
                    ForEach(goals) { goal in
                        TrackingGoalRowView(
                            emoji: goal.emoji,
                            title: goal.name,
                            unit: goal.unit,
                            increment: goal.increment,
                            goal: goal.goal,
                            value: intakeBinding(for: goal),
                            isRestDay: restDayBinding(for: goal)
                        )
                    }
                }
                .transition(.scale(scale: 0.92, anchor: .top).combined(with: .opacity))
            }
        }
    }

    // Header de categoria customizada, mesmo visual das fixas, mas com chave própria.
    @ViewBuilder
    private func todayCustomCategoryHeader(_ customCategory: CustomGoalCategory) -> some View {
        TodayCategoryHeader(
            title: customCategory.name,
            collapsed: isTodayCategoryCollapsed(customCategory.id),
            accentColor: todayAccentColor,
            a11yLabel: A11y.categoryLabel(customCategory.name),
            a11yHint: A11y.categoryHint(),
            onToggle: { toggleTodayCategory(customCategory.id) }
        )
    }

    // Seção colapsável de uma categoria, mostra o header e, quando expandido, as metas.
    @ViewBuilder
    private func todayCategorySection(_ category: GoalCategory) -> some View {
        let fixedKeys = activeGoalKeys.filter {
            GoalCategory.defaultCategory(for: $0) == category
        }
        let customGoalsInCategory = customTrackingGoals.filter { $0.category == category }

        if !fixedKeys.isEmpty || !customGoalsInCategory.isEmpty {
            todayCategoryHeader(category)

            if !isTodayCategoryCollapsed(category.rawValue) {
                VStack(spacing: 10) {
                    ForEach(fixedKeys, id: \.self) { key in
                        goalRow(for: key)
                    }
                    ForEach(customGoalsInCategory) { goal in
                        TrackingGoalRowView(
                            emoji: goal.emoji,
                            title: goal.name,
                            unit: goal.unit,
                            increment: goal.increment,
                            goal: goal.goal,
                            value: intakeBinding(for: goal),
                            isRestDay: restDayBinding(for: goal)
                        )
                    }
                }
                .transition(.scale(scale: 0.92, anchor: .top).combined(with: .opacity))
            }
        }
    }

    // Cor de destaque lida do AppStorage, segue a escolha do usuário em Settings > Cores.
    @AppStorage(AppAccentColor.storageKey) private var storedColorRaw: String = AppAccentColor.blue.rawValue
    private var todayAccentColor: Color {
        (AppAccentColor(rawValue: storedColorRaw) ?? .blue).color
    }

    // Header de categoria com botão de colapso, texto centralizado, preto/branco.
    // Recolhida: cantos superiores arredondados, inferiores zerados (indicativo visual de abertura pra baixo).
    // Expandida: cantos inferiores arredondados, superiores zerados (indica que há conteúdo acima/aberto).
    @ViewBuilder
    private func todayCategoryHeader(_ category: GoalCategory) -> some View {
        TodayCategoryHeader(
            title: category.displayName,
            collapsed: isTodayCategoryCollapsed(category.rawValue),
            accentColor: todayAccentColor,
            a11yLabel: A11y.categoryLabel(category.displayName),
            a11yHint: A11y.categoryHint(),
            onToggle: { toggleTodayCategory(category.rawValue) }
        )
    }

    // MARK: - Grade de categorias (iPhone)

    /// Progresso de uma meta personalizada (dia de descanso conta como cumprida).
    private func customProgress(_ goal: CustomTrackingGoal) -> Double {
        if supportsRestDay(for: goal), customTrackingRestDays[goal.id.uuidString] == true { return 1 }
        let intake = customTrackingIntakes[goal.id.uuidString] ?? 0
        return ProgressHelpers.normalizedProgress(current: intake, goal: goal.goal)
    }

    private func customRow(_ goal: CustomTrackingGoal) -> some View {
        TrackingGoalRowView(
            emoji: goal.emoji,
            title: goal.name,
            unit: goal.unit,
            increment: goal.increment,
            goal: goal.goal,
            value: intakeBinding(for: goal),
            isRestDay: restDayBinding(for: goal)
        )
    }

    /// Monta um bloco a partir dos progressos das metas e das linhas de controle.
    private func makeTile(id: String, title: String, symbol: String,
                          progresses: [Double], content: AnyView) -> TodayCategoryTile {
        let average = progresses.isEmpty ? 0 : progresses.reduce(0, +) / Double(progresses.count)
        return TodayCategoryTile(
            id: id,
            title: title,
            symbolName: symbol,
            progress: average,
            completedCount: progresses.filter { $0 >= 1 }.count,
            totalCount: progresses.count,
            content: content
        )
    }

    /// Blocos da grade: as 4 categorias fixas primeiro, depois as do usuário, e "Outras" no fim.
    private var categoryTiles: [TodayCategoryTile] {
        let builtins = unifiedCategoryItems.filter { if case .builtin = $0 { return true }; return false }
        let customs  = unifiedCategoryItems.filter { if case .custom = $0 { return true }; return false }
        var tiles: [TodayCategoryTile] = []

        for item in (builtins + customs) where categoryHasContent(item) {
            switch item {
            case .builtin(let category):
                let keys = activeGoalKeys.filter { GoalCategory.defaultCategory(for: $0) == category }
                let goals = customTrackingGoals.filter { $0.category == category }
                tiles.append(makeTile(
                    id: gridCellId(for: item),
                    title: category.displayName,
                    symbol: category.symbolName,
                    progresses: keys.map { progress(for: $0) } + goals.map { customProgress($0) },
                    content: AnyView(Group {
                        ForEach(keys, id: \.self) { goalRow(for: $0) }
                        ForEach(goals) { customRow($0) }
                    })
                ))
            case .custom(let category):
                let goals = customGoalsFor(customCategoryId: category.id)
                tiles.append(makeTile(
                    id: gridCellId(for: item),
                    title: category.name,
                    symbol: category.symbolName,
                    progresses: goals.map { customProgress($0) },
                    content: AnyView(ForEach(goals) { customRow($0) })
                ))
            }
        }

        if !uncategorizedCustomGoals.isEmpty {
            let goals = uncategorizedCustomGoals
            tiles.append(makeTile(
                id: "__uncategorized__",
                title: String(localized: "today.category.other", bundle: .gymNutshellCore),
                symbol: "ellipsis",
                progresses: goals.map { customProgress($0) },
                content: AnyView(ForEach(goals) { customRow($0) })
            ))
        }
        return tiles
    }

    // MARK: - Corpo da lista de metas

    private var goalsListBody: some View {
        TodayGoalsListView {
            goalsContent
        }
        .animation(.easeInOut(duration: 0.28), value: todayCollapsedRaw)
    }

    /// Lista achatada de células renderizáveis pro grid coluna-major.
    /// Categorias vazias são filtradas; metas personalizadas sem categoria viram a célula final.
    private var gridCells: [TodayGridCell] {
        var cells: [TodayGridCell] = unifiedCategoryItems
            .filter { categoryHasContent($0) }
            .map { item in
                TodayGridCell(id: gridCellId(for: item)) {
                    AnyView(
                        VStack(spacing: 10) {
                            switch item {
                            case .builtin(let category): todayCategorySection(category)
                            case .custom(let category):  todayCustomCategorySection(category)
                            }
                        }
                    )
                }
            }
        if !uncategorizedCustomGoals.isEmpty {
            cells.append(TodayGridCell(id: "__uncategorized__") {
                AnyView(
                    VStack(spacing: 10) {
                        ForEach(uncategorizedCustomGoals) { goal in
                            TrackingGoalRowView(
                                emoji: goal.emoji,
                                title: goal.name,
                                unit: goal.unit,
                                increment: goal.increment,
                                goal: goal.goal,
                                value: intakeBinding(for: goal),
                                isRestDay: restDayBinding(for: goal)
                            )
                        }
                    }
                )
            })
        }
        return cells
    }

    private func gridCellId(for item: CategoryItem) -> String {
        switch item {
        case .builtin(let category): return "builtin:\(category.rawValue)"
        case .custom(let category):  return "custom:\(category.id)"
        }
    }

    // Verifica se uma categoria tem ao menos uma meta visível.
    // Espelha as condições internas de todayCategorySection / todayCustomCategorySection.
    private func categoryHasContent(_ item: CategoryItem) -> Bool {
        switch item {
        case .builtin(let category):
            let fixedKeys = activeGoalKeys.filter {
                GoalCategory.defaultCategory(for: $0) == category
            }
            let customs = customTrackingGoals.filter { $0.category == category }
            return !fixedKeys.isEmpty || !customs.isEmpty
        case .custom(let category):
            return !customGoalsFor(customCategoryId: category.id).isEmpty
        }
    }

    // MARK: - Layout retrato

    private var portraitLayout: some View {
        GeometryReader { proxy in
            // Hero ocupa só o necessário (ancorado no topo, sem padding superior).
            // Espaço entre hero e metas é menor que o spacing padrão de seção.
            let topInset: CGFloat = 16
            let heroToGoalsSpacing: CGFloat = 20
            VStack(spacing: 0) {
                Spacer().frame(height: topInset)

                VStack(spacing: UI.heroInnerSpacing) {
                    heroBlock(vertical: false, card: true)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                Spacer().frame(height: heroToGoalsSpacing)

                // Blocos de categoria; os controles abrem num balão ao tocar.
                // Rola só se houver muitas categorias personalizadas.
                ScrollView {
                    TodayCategoryGrid(tiles: categoryTiles, accentColor: todayAccentColor)
                        .frame(maxWidth: UI.contentMaxWidth)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .scrollBounceBehavior(.basedOnSize)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal)
        }
    }

    // MARK: - Layout largo (paisagem / iPad)

    private func wideLayout(vertical: Bool) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            HStack(alignment: .top, spacing: UI.wideHStackSpacing) {
                VStack(alignment: .center, spacing: UI.heroInnerSpacing) {
                    Spacer(minLength: 0)
                    heroBlock(vertical: vertical)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer(minLength: 0)
                }
                .frame(width: UI.heroColumnWidth)

                if vertical {
                    // iPad com altura sobrando: metas em grid coluna-major, ocupa
                    // toda a largura disponível à direita do hero. O grid já tem
                    // GeometryReader+ScrollView internos, sem wrap extra aqui.
                    TodayGoalsGrid(cells: gridCells, animationKey: todayCollapsedRaw)
                        .frame(maxWidth: .infinity)
                } else {
                    // iPhone landscape / janela estreita: coluna única centralizada.
                    GeometryReader { goalsProxy in
                        ScrollView {
                            VStack(spacing: 0) {
                                Spacer(minLength: 0)
                                goalsListBody
                                Spacer(minLength: 0)
                            }
                            .frame(minHeight: goalsProxy.size.height)
                        }
                    }
                    .frame(width: UI.contentMaxWidth)
                }
            }
            // Em modo grid (iPad/macOS/Vision Pro com altura sobrando) cap o conjunto
            // hero + grid e centraliza no eixo horizontal, evita o conteúdo ficar
            // ancorado num canto quando a janela é estendida pra 4K.
            // No iPhone landscape (vertical=false) mantém leading pra hero colar
            // na borda esquerda como o usuário pediu.
            .frame(maxWidth: vertical ? 1400 : .infinity, alignment: vertical ? .center : .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, vertical ? 24 : 0)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical)
        .padding(.trailing)
    }

    // MARK: - Corpo

    var body: some View {
        GeometryReader { proxy in
            let isWide = proxy.size.width >= UI.wideThreshold
            // Hero vertical (progresso/conquista empilhados) exige largura E altura
            // generosas, caso contrário (iPhone landscape, iPad em janela pequena do iOS 26)
            // usamos o hero horizontal pra não tampar as metas.
            // Threshold de altura menor que o de largura, iPad em landscape ainda
            // tem altura de sobra pro empilhamento.
            let isTall = proxy.size.height >= 500
            Group {
                if isWide {
                    wideLayout(vertical: isTall)
                } else {
                    portraitLayout
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            // Carrega stores ANTES de checkIfNewDay, caso contrário o dailyAchievement
            // do dia anterior é recalculado com state vazio (progressValues = []) e o
            // DailyRecord salvo fica com tier "level1" mesmo quando o usuário tinha conquistas.
            orderedGoalKeys = GoalOrderStore.load()
            orderedCategories = GoalCategoryOrderStore.load()
            removedItems = RemovedItemsStore.load()
            customTrackingGoals = CustomTrackingGoalsStore.load()
            customTrackingIntakes = CustomTrackingIntakesStore.load()
            customTrackingRestDays = CustomTrackingRestDaysStore.load()
            userCategories = CustomGoalCategoriesStore.load()
            unifiedCategoryItems = UnifiedCategoryOrderStore.load()
            checkIfNewDay()
            StreakBonusChecker.evaluateAndAward(into: modelContext)
            checkWorkoutsFromHealth()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                orderedGoalKeys = GoalOrderStore.load()
                orderedCategories = GoalCategoryOrderStore.load()
                removedItems = RemovedItemsStore.load()
                customTrackingGoals = CustomTrackingGoalsStore.load()
                customTrackingIntakes = CustomTrackingIntakesStore.load()
                customTrackingRestDays = CustomTrackingRestDaysStore.load()
                userCategories = CustomGoalCategoriesStore.load()
                unifiedCategoryItems = UnifiedCategoryOrderStore.load()
                checkIfNewDay()
                checkWorkoutsFromHealth()
            } else if newPhase == .background {
                // Reagenda a notificação de conquista de meia-noite com o estado atual ,
                // como o intake é manual via app, a última ida pra background reflete
                // o que o usuário terá no fim do dia.
                let tier = dailyAchievement
                NotificationManager.shared.scheduleDailyAchievementAtMidnight(
                    tierName: selectedTheme.name(for: tier),
                    emoji: selectedTheme.emoji(for: tier),
                    earnedOn: Date()
                )
            }
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            checkIfNewDay()
        }
    }
}


#Preview {
    TodayView()
}
