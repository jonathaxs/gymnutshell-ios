// ⌘
//  GymNutshellWatch/ContentView.swift
//
//  Propósito: Tela principal do Watch app, hero superior (WatchHeroView) com anel
//             de progresso médio e nome do nível. Embaixo, cards de metas
//             (WatchGoalCard) com fundo preenchendo conforme o progresso.
//             A lista respeita a ordem e o filtro de remoção definidos no iPhone
//             (via GoalOrderStore / RemovedItemsStore).
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-04-26.
// ⌘

import SwiftUI
import WatchKit
import WidgetKit
import GymNutshellCore

struct ContentView: View {

    // MARK: - Ingestões (chaves alinhadas com o iPhone pra facilitar o sync futuro)

    @AppStorage("workoutIntake")  private var workoutIntake:  Int = 0
    @AppStorage("cardioIntake")   private var cardioIntake:   Int = 0
    @AppStorage("sleepHours")     private var sleepHours:     Int = 0
    @AppStorage("waterIntake")    private var waterIntake:    Int = 0
    @AppStorage("proteinIntake")  private var proteinIntake:  Int = 0
    @AppStorage("carbIntake")     private var carbIntake:     Int = 0
    @AppStorage("goodFatIntake")  private var goodFatIntake:  Int = 0
    @AppStorage("fiberIntake")    private var fiberIntake:    Int = 0
    @AppStorage("creatineIntake") private var creatineIntake: Int = 0

    // MARK: - Preferências

    @AppStorage(AppTheme.storageKey)              private var storedThemeRaw:       String = AppTheme.gym.rawValue
    @AppStorage(UserProfile.sexKey)               private var sex:                  String = "male"
    @AppStorage(AppAccentColor.storageKey)        private var storedColorRaw:       String = AppAccentColor.blue.rawValue

    // Valores-alvo das metas, observados como @AppStorage pra que SwiftUI
    // re-renderize quando o iPhone mandar novos valores via WatchConnectivity.
    @AppStorage("tracking.workout")  private var workoutGoalValue:  Int = DefaultGoals.workout
    @AppStorage("tracking.cardio")   private var cardioGoalValue:   Int = DefaultGoals.cardio
    @AppStorage("tracking.sleep")    private var sleepGoalValue:    Int = DefaultGoals.sleep
    @AppStorage("tracking.water")    private var waterGoalValue:    Int = DefaultGoals.water
    @AppStorage("tracking.protein")  private var proteinGoalValue:  Int = DefaultGoals.protein
    @AppStorage("tracking.carbs")    private var carbsGoalValue:    Int = DefaultGoals.carbs
    @AppStorage("tracking.goodFat")  private var goodFatGoalValue:  Int = DefaultGoals.goodFat
    @AppStorage("tracking.fiber")    private var fiberGoalValue:    Int = DefaultGoals.fiber
    @AppStorage("tracking.creatine") private var creatineGoalValue: Int = DefaultGoals.creatine

    // Trigger de refresh, quando UserDefaults muda (incluindo a ordem de metas
    // ou removedItems), incrementa pra forçar re-render do goalEntries (que é
    // computed property baseada em GoalOrderStore.load() / RemovedItemsStore.load()).
    @State private var refreshTick: Int = 0

    // Toggles de "dia de descanso", sincronizam iPhone ↔ Watch via WatchConnectivity.
    @AppStorage("workoutRestDay") private var workoutRestDay: Bool = false
    @AppStorage("cardioRestDay")  private var cardioRestDay:  Bool = false

    @State private var expandedId: String?

    private var theme: AppTheme            { AppTheme(rawValue: storedThemeRaw) ?? .gym }
    private var accent: AppAccentColor     { AppAccentColor(rawValue: storedColorRaw) ?? .blue }

    // MARK: - Metas exibidas

    /// Constrói uma entrada `GoalEntry` a partir de uma chave do GoalOrderStore.
    /// Retorna nil se a chave não for reconhecida (defesa contra dados corrompidos).
    private func entry(forTrackingKey key: String) -> GoalEntry? {
        switch key {
        case "tracking.workout":
            return GoalEntry(
                id: key, emoji: "🏋️",
                displayName: String(localized: "today.goals.workout", bundle: .gymNutshellCore),
                current: workoutIntake, goal: workoutGoalValue,
                unit: "min", increment: DefaultGoals.workoutIncrement,
                update: { workoutIntake = $0 }
            )
        case "tracking.cardio":
            return GoalEntry(
                id: key, emoji: "🏃",
                displayName: String(localized: "today.goals.cardio", bundle: .gymNutshellCore),
                current: cardioIntake, goal: cardioGoalValue,
                unit: "min", increment: DefaultGoals.cardioIncrement,
                update: { cardioIntake = $0 }
            )
        case "tracking.sleep":
            return GoalEntry(
                id: key, emoji: "💤",
                displayName: String(localized: "today.metric.sleep", bundle: .gymNutshellCore),
                current: sleepHours, goal: sleepGoalValue,
                unit: "h", increment: 1,
                update: { sleepHours = $0 }
            )
        case "tracking.water":
            return GoalEntry(
                id: key, emoji: "💧",
                displayName: String(localized: "today.metric.water", bundle: .gymNutshellCore),
                current: waterIntake, goal: waterGoalValue,
                unit: "ml", increment: 250,
                update: { waterIntake = $0 }
            )
        case "tracking.protein":
            return GoalEntry(
                id: key, emoji: "🍗",
                displayName: String(localized: "today.metric.protein", bundle: .gymNutshellCore),
                current: proteinIntake, goal: proteinGoalValue,
                unit: "g", increment: 5,
                update: { proteinIntake = $0 }
            )
        case "tracking.carbs":
            return GoalEntry(
                id: key, emoji: "🍞",
                displayName: String(localized: "today.metric.carbs", bundle: .gymNutshellCore),
                current: carbIntake, goal: carbsGoalValue,
                unit: "g", increment: 10,
                update: { carbIntake = $0 }
            )
        case "tracking.goodFat":
            return GoalEntry(
                id: key, emoji: "🧈",
                displayName: String(localized: "today.metric.fats", bundle: .gymNutshellCore),
                current: goodFatIntake, goal: goodFatGoalValue,
                unit: "g", increment: 5,
                update: { goodFatIntake = $0 }
            )
        case "tracking.fiber":
            return GoalEntry(
                id: key, emoji: "🌾",
                displayName: String(localized: "today.metric.fiber", bundle: .gymNutshellCore),
                current: fiberIntake, goal: fiberGoalValue,
                unit: "g", increment: 5,
                update: { fiberIntake = $0 }
            )
        case "tracking.creatine":
            return GoalEntry(
                id: key, emoji: "🧪",
                displayName: String(localized: "today.goals.creatine", bundle: .gymNutshellCore),
                current: creatineIntake, goal: creatineGoalValue,
                unit: "g", increment: DefaultGoals.creatineIncrement,
                update: { creatineIntake = $0 },
                isCheckIn: GoalCategory.suplemento.kind == .checkIn
            )
        default:
            return nil
        }
    }

    /// Lista final de metas a exibir, respeita:
    ///   1. Ordem das categorias (`GoalCategoryOrderStore`), mesma escolhida em
    ///      App Settings → Goals → Categories.
    ///   2. Dentro de cada categoria, ordem das metas (`GoalOrderStore`).
    ///   3. Filtro de itens removidos (`RemovedItemsStore`).
    ///
    /// Acessa `refreshTick` pra que SwiftUI saiba que precisa recalcular quando
    /// o iPhone mandar uma nova ordem via WatchConnectivity.
    private var goalEntries: [GoalEntry] {
        _ = refreshTick // dependência explícita pro SwiftUI
        let removed = RemovedItemsStore.load()
        let allKeys = GoalOrderStore.load().filter { !removed.contains($0) }
        let categoryOrder = GoalCategoryOrderStore.load()

        var result: [GoalEntry] = []
        var usedKeys = Set<String>()

        // Itera categoria por categoria, dentro de cada uma, mantém ordem do GoalOrderStore.
        for category in categoryOrder {
            for key in allKeys where !usedKeys.contains(key) {
                guard GoalCategory.defaultCategory(for: key) == category else { continue }
                if let entry = entry(forTrackingKey: key) {
                    result.append(entry)
                    usedKeys.insert(key)
                }
            }
        }

        // Defesa: chaves sem categoria reconhecida vão pro final.
        for key in allKeys where !usedKeys.contains(key) {
            if let entry = entry(forTrackingKey: key) {
                result.append(entry)
            }
        }

        return result
    }

    private var averageProgress: Double {
        // Usa o MESMO algoritmo que o iPhone (WidgetSnapshot.buildCurrent), só que
        // executado localmente sobre o UserDefaults do Watch. Garante:
        //  - Paridade exata de % com iPhone (mesmo set de chaves, mesma ordem, mesma matemática)
        //  - Atualização imediata ao incrementar metas no Watch (cálculo local, não depende
        //    do snapshot que vem do iPhone).
        // refreshTick força SwiftUI a recomputar quando UserDefaults muda.
        _ = refreshTick
        return WidgetSnapshot.buildCurrent().progressNormalized
    }

    private var tier: DailyAchievement { DailyAchievement.from(progress: averageProgress) }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                WatchHeroView(
                    averageProgress: averageProgress,
                    theme: theme,
                    tier: tier,
                    sex: sex
                )
                .padding(.bottom, 4)

                ForEach(goalEntries) { entry in
                    WatchGoalCard(
                        entry: entry,
                        isExpanded: expandedId == entry.id,
                        accentColor: accent.color,
                        restActive: restDayActive(for: entry.id),
                        onToggleExpand: {
                            expandedId = (expandedId == entry.id) ? nil : entry.id
                        },
                        onToggleRestDay: { toggleRestDay(for: entry.id) },
                        storageKeyForId: storageKey(for:)
                    )
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UserDefaults.didChangeNotification,
            object: UserDefaults.standard
        )) { _ in
            // Filtra por UserDefaults.standard, sem isso, o save abaixo (que escreve
            // no App Group) dispara outra notificação e cai num loop infinito que trava
            // o app no carregamento.
            refreshTick &+= 1
            // Recalcula snapshot localmente e atualiza o widget do Watch, assim o
            // progresso na complication acompanha incrementos feitos no próprio Watch
            // (não depende mais do iPhone enviar de volta).
            WidgetSnapshotStore.save(WidgetSnapshot.buildCurrent())
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    // MARK: - Rest day helpers

    /// Retorna o estado atual do toggle de "dia de descanso" pra metas que suportam,
    /// ou nil pras que não suportam (não mostra ON/OFF).
    private func restDayActive(for goalId: String) -> Bool? {
        switch goalId {
        case "tracking.workout": return workoutRestDay
        case "tracking.cardio":  return cardioRestDay
        default:                 return nil
        }
    }

    /// Inverte o toggle de "dia de descanso" da meta.
    private func toggleRestDay(for goalId: String) {
        switch goalId {
        case "tracking.workout": workoutRestDay.toggle()
        case "tracking.cardio":  cardioRestDay.toggle()
        default: break
        }
    }

    /// Mapeia o id do GoalEntry (que é a chave do GoalOrderStore, ex: "tracking.water")
    /// para a chave do UserDefaults usada pra persistir a ingestão (ex: "waterIntake").
    private func storageKey(for goalId: String) -> String {
        switch goalId {
        case "tracking.workout":  return "workoutIntake"
        case "tracking.cardio":   return "cardioIntake"
        case "tracking.sleep":    return "sleepHours"
        case "tracking.water":    return "waterIntake"
        case "tracking.protein":  return "proteinIntake"
        case "tracking.carbs":    return "carbIntake"
        case "tracking.goodFat":  return "goodFatIntake"
        case "tracking.fiber":    return "fiberIntake"
        case "tracking.creatine": return "creatineIntake"
        default:                  return goalId
        }
    }
}

#Preview {
    ContentView()
}
