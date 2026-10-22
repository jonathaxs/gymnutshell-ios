// ⌘
//  GymNutshell/GymNutshellApp/Views/TodayView/TodayView.swift
//
//  Propósito: Tela principal "Hoje", onde o usuário acompanha todas as metas diárias com sliders.
//             O bloco hero mostra a data de hoje, o nível de conquista, o anel de progresso e a frase do próximo nível.
//             As metas ficam agrupadas por categoria (cabeçalho colapsável + card com as linhas);
//             no iPhone em lista, no layout largo (iPad) em grade de colunas.
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
    @Environment(AppRouter.self) private var router
    // Duo dobrado: os botões das páginas vão pra coluna lateral (ver AppTabHeader).
    @Environment(\.usesVerticalBar) private var usesVerticalBar
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// Sheet de Editar metas / Editar controles aberta agora (nil = nenhuma).
    @State private var editSheet: EditSheet?

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

    // Modo de visualização das metas (lista ou grade com balão), no retrato e no layout largo.
    @AppStorage(TodayGoalsViewMode.storageKey) private var goalsViewModeRaw: String = TodayGoalsViewMode.list.rawValue
    private var goalsViewMode: TodayGoalsViewMode { TodayGoalsViewMode(rawValue: goalsViewModeRaw) ?? .list }

    /// Liga cada categoria da lista ao seu botão da grade, pra transformação na troca de modo.
    @Namespace private var goalsMorphNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Ordem das categorias, sincronizada com TrackingGoalsSettingsView.
    @State private var orderedCategories: [GoalCategory] = GoalCategoryOrderStore.defaultOrder

    /// Logo depois do "Vamos lá" da Welcome: as categorias da lista começam escondidas e entram vindo
    /// de baixo, uma a uma, junto com a comemoração do anel. Só uma vez.
    @State private var goalsEntranceHidden = UserDefaults.standard.bool(forKey: UserProfile.pendingGoalsEntranceKey)


    // MARK: - Constantes de layout

    private enum UI {
        static let wideThreshold: CGFloat    = 700
        static let regularWideMinWidth: CGFloat = 560
        static let compactWideLimit: CGFloat = 744
        static let compactHeroColumnWidth: CGFloat = 320
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
    private var waterIncrement: Int { measurementSystem == .us ? UnitConverter.flOzWaterStep : 250 }

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
        AppDateFormatters.weekdayAndDay(for: Date())
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
    }

    // MARK: - Bloco hero

    private func heroBlock(vertical: Bool, showsHeader: Bool = true) -> some View {
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
            showsHeader: showsHeader
        )
        // Os botões das páginas ficam na TodayView: no retrato acima ou abaixo da grade conforme o modo,
        // no layout largo abaixo do hero junto dos atalhos de edição (ou na coluna lateral do Duo).
    }

    // MARK: - Conteúdo das metas (agrupado por categoria)

    // Cor de destaque lida do AppStorage, segue a escolha do usuário em Settings > Cores.
    @AppStorage(AppAccentColor.storageKey) private var storedColorRaw: String = AppAccentColor.blue.rawValue
    private var todayAccentColor: Color {
        (AppAccentColor(rawValue: storedColorRaw) ?? .blue).color
    }

    /// Chave de colapso de "Outras" (metas personalizadas sem categoria).
    private static let uncategorizedId = "__uncategorized__"

    @ViewBuilder
    private var goalsContent: some View {
        // Renderiza fixas e personalizadas na ordem unificada escolhida pelo usuário.
        let items = unifiedCategoryItems.filter { categoryHasContent($0) }
        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
            categorySection(for: item)
                .goalsEntrance(index: index, hidden: goalsEntranceHidden)
        }
        // Metas personalizadas sem categoria ficam no final, em "Outras".
        uncategorizedSection
            .goalsEntrance(index: items.count, hidden: goalsEntranceHidden)
    }

    /// Solta a entrada das metas depois do "Vamos lá" (a marca é apagada pra não repetir).
    private func playGoalsEntranceIfNeeded() {
        guard goalsEntranceHidden else { return }
        UserDefaults.standard.removeObject(forKey: UserProfile.pendingGoalsEntranceKey)
        guard !reduceMotion else {
            goalsEntranceHidden = false
            return
        }
        // Espera a Welcome terminar de sumir (0,6s na troca do GymNutshellApp) pra a subida ser vista.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { goalsEntranceHidden = false }
    }

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

    /// Uma categoria fixa ou criada pelo usuário: cabeçalho + card com as metas.
    @ViewBuilder
    private func categorySection(for item: CategoryItem) -> some View {
        switch item {
        case .builtin(let category):
            let keys = activeGoalKeys.filter { GoalCategory.defaultCategory(for: $0) == category }
            let goals = customTrackingGoals.filter { $0.category == category }
            categoryBlock(id: category.rawValue,
                          morphId: gridCellId(for: item),
                          title: category.displayName,
                          symbol: category.symbolName,
                          progresses: keys.map { progress(for: $0) } + goals.map { customProgress($0) }) {
                ForEach(keys, id: \.self) { goalRow(for: $0) }
                ForEach(goals) { customRow($0) }
            }
        case .custom(let category):
            let goals = customGoalsFor(customCategoryId: category.id)
            categoryBlock(id: category.id,
                          morphId: gridCellId(for: item),
                          title: category.name,
                          symbol: category.symbolName,
                          progresses: goals.map { customProgress($0) }) {
                ForEach(goals) { customRow($0) }
            }
        }
    }

    @ViewBuilder
    private var uncategorizedSection: some View {
        let goals = uncategorizedCustomGoals
        if !goals.isEmpty {
            categoryBlock(id: Self.uncategorizedId,
                          morphId: Self.uncategorizedId,
                          title: String(localized: "today.category.other", bundle: .gymNutshellCore),
                          symbol: "ellipsis.circle",
                          progresses: goals.map { customProgress($0) }) {
                ForEach(goals) { customRow($0) }
            }
        }
    }

    /// Cabeçalho colapsável + as metas num card só, com divisores (lista agrupada do iOS).
    private func categoryBlock<Rows: View>(id: String, morphId: String, title: String, symbol: String,
                                           progresses: [Double],
                                           @ViewBuilder rows: () -> Rows) -> some View {
        let collapsed = isTodayCategoryCollapsed(id)
        let content = rows()
        return VStack(spacing: 8) {
            TodayCategoryHeader(
                title: title,
                symbolName: symbol,
                completedCount: progresses.filter { $0 >= 1 }.count,
                totalCount: progresses.count,
                collapsed: collapsed,
                accentColor: todayAccentColor,
                a11yLabel: A11y.categoryLabel(title),
                a11yHint: A11y.categoryHint(),
                onToggle: { toggleTodayCategory(id) },
                morphId: morphId
            )

            if !collapsed {
                AppGroupedCard(dividerInset: 14) {
                    content
                }
                .environment(\.goalRowGrouped, true)
                .transition(.scale(scale: 0.96, anchor: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Blocos da grade

    /// Monta um bloco a partir dos progressos das metas e das linhas de controle.
    private func makeTile(id: String, title: String, symbol: String, tint: Color? = nil,
                          progresses: [Double], content: AnyView) -> TodayCategoryTile {
        let average = progresses.isEmpty ? 0 : progresses.reduce(0, +) / Double(progresses.count)
        return TodayCategoryTile(
            id: id,
            title: title,
            symbolName: symbol,
            progress: average,
            completedCount: progresses.filter { $0 >= 1 }.count,
            totalCount: progresses.count,
            tint: tint,
            content: content
        )
    }

    /// Blocos da grade: as categorias fixas primeiro, depois as do usuário, e "Outras" no fim.
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
                    tint: category.tintColor,
                    progresses: keys.map { progress(for: $0) } + goals.map { customProgress($0) },
                    content: AnyView(
                        AppGroupedCard(dividerInset: 14) {
                            ForEach(keys, id: \.self) { goalRow(for: $0) }
                            ForEach(goals) { customRow($0) }
                        }
                        .environment(\.goalRowGrouped, true)
                    )
                ))
            case .custom(let category):
                let goals = customGoalsFor(customCategoryId: category.id)
                tiles.append(makeTile(
                    id: gridCellId(for: item),
                    title: category.name,
                    symbol: category.symbolName,
                    progresses: goals.map { customProgress($0) },
                    content: AnyView(
                        AppGroupedCard(dividerInset: 14) {
                            ForEach(goals) { customRow($0) }
                        }
                        .environment(\.goalRowGrouped, true)
                    )
                ))
            }
        }

        let others = uncategorizedCustomGoals
        if !others.isEmpty {
            tiles.append(makeTile(
                id: Self.uncategorizedId,
                title: String(localized: "today.category.other", bundle: .gymNutshellCore),
                symbol: "ellipsis.circle",
                progresses: others.map { customProgress($0) },
                content: AnyView(
                    AppGroupedCard(dividerInset: 14) {
                        ForEach(others) { customRow($0) }
                    }
                    .environment(\.goalRowGrouped, true)
                )
            ))
        }
        return tiles
    }

    // MARK: - Corpo da lista de metas

    private func goalsListBody(maxWidth: CGFloat = UI.contentMaxWidth) -> some View {
        TodayGoalsListView(maxWidth: maxWidth) {
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
                    AnyView(categorySection(for: item))
                }
            }
        if !uncategorizedCustomGoals.isEmpty {
            cells.append(TodayGridCell(id: Self.uncategorizedId) {
                AnyView(uncategorizedSection)
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
        // Data + sino + engrenagem ficam fixos no topo; anel, metas e atalhos rolam juntos.
        ScrollView {
            VStack(spacing: 20) {
                heroBlock(vertical: false, showsHeader: false)
                    .frame(maxWidth: .infinity, alignment: .center)

                // Grade: anel → grade → botões → atalhos. Lista: anel → botões → lista → atalhos.
                // Os botões são sempre a mesma view, então na troca eles deslizam e a grade sobe/desce.
                if goalsViewMode == .grid {
                    // Blocos de categoria; os controles abrem num balão ao tocar.
                    TodayCategoryGrid(tiles: categoryTiles, accentColor: todayAccentColor)
                        .frame(maxWidth: 560)
                        .transition(.opacity)
                }

                // Com a barra vertical (Duo dobrado) esses botões vão pra coluna lateral.
                if !usesVerticalBar {
                    TodayPageButtons()
                        // Mesmo respiro entre a frase do hero e os botões de antes (o hero usa 16 por dentro).
                        .padding(.top, goalsViewMode == .list ? -4 : 0)
                }

                if goalsViewMode == .list {
                    goalsListBody(maxWidth: 560)
                        .transition(.opacity)
                }

                editShortcuts
                    // Na lista a última meta termina num card sem respiro embaixo; a grade já tem folga.
                    .padding(.top, goalsViewMode == .list ? 12 : 0)
            }
            // Lista e grade trocam com transformação (ícone ↔ círculo, nome ↔ nome).
            .environment(\.todayMorphNamespace, goalsMorphNamespace)
            // O modo muda pelo @AppStorage (fora da transação do botão), então a animação fica aqui.
            .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.5, dampingFraction: 0.82),
                       value: goalsViewModeRaw)
            // Margem maior que a padrão: metas e botões do hero mais estreitos, na mesma largura.
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .top, spacing: 0) {
            // Só a data: os Ajustes ficam na linha de botões abaixo do anel.
            AppTabHeader(title: formattedDate)
                .padding(.horizontal)
                .padding(.horizontal, 4)
                .padding(.top, 16)
                .padding(.bottom, 8)
                .background(Color(.systemGroupedBackground))
        }
    }

    // MARK: - Atalhos pra Ajustes

    /// Sheets de edição rápida, com as mesmas telas de Ajustes > Tema, Cores de destaque, Controles e Metas.
    private enum EditSheet: String, Identifiable {
        case theme, colors, controls, goals
        var id: String { rawValue }
    }

    /// Botões pequenos abaixo das metas, centralizados: Tema (máscaras, como no Welcome), Cores de destaque (paleta) e
    /// Controles (os tracinhos dos Ajustes) só com o ícone e, por último, "Editar metas" com texto. Cada um abre a tela
    /// dos Ajustes numa sheet, sem sair da Hoje. Os ícones daqui são só desses atalhos; os Ajustes têm os seus.
    private var editShortcuts: some View {
        HStack(spacing: 8) {
            shortcutIconButton(systemImage: "theatermasks", a11yKey: "today.edit.theme", sheet: .theme)
            shortcutIconButton(systemImage: "paintpalette", a11yKey: "today.edit.colors", sheet: .colors)
            shortcutIconButton(systemImage: "slider.horizontal.3", a11yKey: "today.edit.controls", sheet: .controls)
            shortcutButton(titleKey: "today.edit.goals", sheet: .goals)
        }
    }

    private func shortcutButton(titleKey: String, sheet: EditSheet) -> some View {
        Button {
            editSheet = sheet
        } label: {
            Text(String(localized: String.LocalizationValue(titleKey), bundle: .gymNutshellCore))
                .font(.footnote.weight(.semibold))
                // Numa linha só; nos iPhones mais estreitos encolhe um pouco em vez de quebrar.
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .appSecondaryButton(todayAccentColor)
        .controlSize(.small)
    }

    /// Só o ícone, maior que o texto (como os botões de ícone do hero), mas com o frame travado no tamanho
    /// antigo: o ícone ocupa parte da margem interna do vidro, sem aumentar o botão. Com um frame mais largo,
    /// o "Editar metas" quebrava em duas linhas no iPhone de 6,3".
    private func shortcutIconButton(systemImage: String, a11yKey: String, sheet: EditSheet) -> some View {
        Button {
            editSheet = sheet
        } label: {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .frame(width: 22, height: 16)
        }
        .appSecondaryButton(todayAccentColor, circle: true)
        .controlSize(.small)
        .accessibilityLabel(String(localized: String.LocalizationValue(a11yKey), bundle: .gymNutshellCore))
    }

    // MARK: - Layout largo (paisagem / iPad)


    /// Mesmos atalhos, com a mesma identidade nas duas posições: na troca lista ↔ grade eles deslizam entre o
    /// hero e o pé da grade.
    private var wideEditShortcuts: some View {
        editShortcuts
            .matchedGeometryEffect(id: "editShortcuts", in: goalsMorphNamespace)
    }

    private func wideLayout(vertical: Bool, buttonsInRail: Bool, compact: Bool) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            HStack(alignment: .top, spacing: compact ? 16 : UI.wideHStackSpacing) {
                VStack(alignment: .center, spacing: UI.heroInnerSpacing) {
                    Spacer(minLength: 0)
                    // Sem coluna lateral (iPad e Duo aberto em pé): a linha de botões fica acima da data, com os
                    // Ajustes primeiro. Com a coluna (barra vertical do Duo ou a do iPad deitado) ela vai pra lá.
                    if !buttonsInRail {
                        TodayPageButtons(items: TodayPageButtons.wideOrder)
                            .padding(.bottom, 8)
                    }
                    // Compacto: anel menor (o de 170 + conquista não cabe na coluna estreita).
                    heroBlock(vertical: vertical && !compact)
                        .frame(maxWidth: .infinity, alignment: .center)
                    // Na lista os atalhos de edição ficam abaixo do hero; na grade vão pra baixo das categorias.
                    if goalsViewMode == .list {
                        wideEditShortcuts
                    }
                    Spacer(minLength: 0)
                }
                .frame(width: compact ? UI.compactHeroColumnWidth : UI.heroColumnWidth)

                if goalsViewMode == .grid {
                    // Mesma grade de botões com balão do iPhone, centralizada na coluna das metas.
                    GeometryReader { goalsProxy in
                        ScrollView {
                            VStack(spacing: 0) {
                                Spacer(minLength: 0)
                                // Categorias em cima e atalhos embaixo: o balão aberto pra baixo ganha espaço.
                                VStack(spacing: 24) {
                                    TodayCategoryGrid(tiles: categoryTiles, accentColor: todayAccentColor)
                                        .frame(maxWidth: 560)
                                    wideEditShortcuts
                                }
                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity, minHeight: goalsProxy.size.height)
                        }
                    }
                    .frame(maxWidth: vertical ? .infinity : UI.contentMaxWidth)
                    .transition(.opacity)
                } else if vertical {
                    // iPad com altura sobrando: metas em grid coluna-major, ocupa
                    // toda a largura disponível à direita do hero. O grid já tem
                    // GeometryReader+ScrollView internos, sem wrap extra aqui.
                    TodayGoalsGrid(cells: gridCells, animationKey: todayCollapsedRaw)
                        .frame(maxWidth: .infinity)
                        .transition(.opacity)
                } else {
                    // iPhone landscape / janela estreita: coluna única centralizada.
                    GeometryReader { goalsProxy in
                        ScrollView {
                            VStack(spacing: 0) {
                                Spacer(minLength: 0)
                                goalsListBody()
                                Spacer(minLength: 0)
                            }
                            .frame(minHeight: goalsProxy.size.height)
                        }
                    }
                    .frame(width: UI.contentMaxWidth)
                    .transition(.opacity)
                }
            }
            .environment(\.todayMorphNamespace, goalsMorphNamespace)
            .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.5, dampingFraction: 0.82),
                       value: goalsViewModeRaw)
            // Em modo grid (iPad/macOS/Vision Pro com altura sobrando) cap o conjunto
            // hero + grid e centraliza no eixo horizontal, evita o conteúdo ficar
            // ancorado num canto quando a janela é estendida pra 4K.
            // No iPhone landscape (vertical=false) mantém leading pra hero colar
            // na borda esquerda como o usuário pediu.
            .frame(maxWidth: vertical ? 1400 : .infinity, alignment: vertical ? .center : .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, vertical && !compact ? 24 : 0)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical)
        .padding(.trailing)
    }

    // MARK: - Corpo

    var body: some View {
        GeometryReader { proxy in
            // Largo a partir de 700 pt, ou já a partir de 560 pt quando o sistema diz que a largura é regular
            // (iPhone Duo aberto em pé, ~669 pt, fica igual ao iPad mini em vez do layout de iPhone esticado).
            let isWide = proxy.size.width >= UI.wideThreshold
                || (horizontalSizeClass == .regular && proxy.size.width >= UI.regularWideMinWidth)
            // Abaixo da largura do iPad mini em pé o hero encolhe e as margens somem, pra sobrar espaço pras metas.
            let compactWide = proxy.size.width < UI.compactWideLimit
            // Hero vertical (progresso/conquista empilhados) exige largura E altura
            // generosas, caso contrário (iPhone landscape, iPad em janela pequena do iOS 26)
            // usamos o hero horizontal pra não tampar as metas.
            // Threshold de altura menor que o de largura, iPad em landscape ainda
            // tem altura de sobra pro empilhamento.
            let isTall = proxy.size.height >= 500
            // iPad deitado (largo e mais largo que alto, sem a barra vertical do sistema): os botões de navegação
            // vão pra coluna de vidro à direita, no estilo da barra vertical do iPhone Duo.
            let sideRail = isWide && !usesVerticalBar && proxy.size.width > proxy.size.height
            Group {
                if isWide {
                    HStack(alignment: .center, spacing: 0) {
                        wideLayout(vertical: isTall, buttonsInRail: usesVerticalBar || sideRail,
                                   compact: compactWide)
                        if sideRail {
                            // Centralizada na altura, junto com o anel e as metas.
                            TodaySideRail()
                                .padding(.trailing)
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
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
            reloadGoalStores()
            checkIfNewDay()
            checkWorkoutsFromHealth()
            playGoalsEntranceIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                reloadGoalStores()
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
        // Registros (sheet do MainView) também edita metas e objetivo; ao fechar, recarrega.
        .onChange(of: router.sheet) { _, newSheet in
            if newSheet == nil { reloadGoalStores() }
        }
        // Edição rápida (tema, cores, controles, metas) abre por cima da Hoje; ao fechar, recarrega o que mudou.
        .sheet(item: $editSheet, onDismiss: reloadGoalStores) { sheet in
            NavigationStack {
                Group {
                    switch sheet {
                    case .theme:    ThemeSettingsView()
                    case .colors:   ColorSettingsView()
                    case .controls: ControlStyleSettingsView()
                    case .goals:    TrackingGoalsSettingsView()
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(String(localized: "common.close", bundle: .gymNutshellCore)) { editSheet = nil }
                    }
                }
            }
        }
    }

    /// Lê de novo as metas, categorias e ordens salvas (ao abrir, voltar pro app e fechar as sheets de edição).
    private func reloadGoalStores() {
        orderedGoalKeys = GoalOrderStore.load()
        orderedCategories = GoalCategoryOrderStore.load()
        removedItems = RemovedItemsStore.load()
        customTrackingGoals = CustomTrackingGoalsStore.load()
        customTrackingIntakes = CustomTrackingIntakesStore.load()
        customTrackingRestDays = CustomTrackingRestDaysStore.load()
        userCategories = CustomGoalCategoriesStore.load()
        unifiedCategoryItems = UnifiedCategoryOrderStore.load()
    }
}


#Preview {
    TodayView()
        .environment(AppRouter())
}

// MARK: - Entrada das metas

private extension View {
    /// Escondida: um pouco abaixo e invisível. Ao revelar, sobe com mola, cada categoria
    /// um pouquinho depois da anterior.
    func goalsEntrance(index: Int, hidden: Bool) -> some View {
        self
            .offset(y: hidden ? 140 : 0)
            .opacity(hidden ? 0 : 1)
            .animation(.spring(response: 0.75, dampingFraction: 0.8).delay(Double(index) * 0.12), value: hidden)
    }
}
