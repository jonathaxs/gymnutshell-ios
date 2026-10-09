import Testing
import Foundation
@testable import GymNutshellCore

// MARK: - Metas padrão (tabela objetivo × sexo)

@Test func metasMasculinasManutencao() {
    let r = GoalsCalculator.calculate(sex: "male", goal: .maintenance)
    #expect(r.calories == 2650)
    #expect(r.water == 2750)
    #expect(r.protein == 150)
    #expect(r.carbs == 260)
    #expect(r.goodFat == 70)
    #expect(r.fiber == 37)
}

@Test func metasFemininasCutting() {
    let r = GoalsCalculator.calculate(sex: "female", goal: .cutting)
    #expect(r.calories == 1650)
    #expect(r.water == 2250)
    #expect(r.protein == 135)
    #expect(r.carbs == 160)
    #expect(r.goodFat == 45)
    #expect(r.fiber == 23)
}

@Test func metasFixasParaTodos() {
    for sex in ["male", "female"] {
        for goal in UserGoal.allCases {
            let r = GoalsCalculator.calculate(sex: sex, goal: goal)
            #expect(r.sleep == 8)
            #expect(r.workout == 50)
            #expect(r.cardio == 15)
            #expect(r.creatine == 5)
        }
    }
}

@Test func sexoLegadoOtherUsaTabelaMasculina() {
    for goal in UserGoal.allCases {
        #expect(GoalsCalculator.calculate(sex: "other", goal: goal)
                == GoalsCalculator.calculate(sex: "male", goal: goal))
        #expect(GoalsCalculator.calculate(sex: "", goal: goal)
                == GoalsCalculator.calculate(sex: "male", goal: goal))
    }
}

@Test func bulkingTemMaisCaloriasQueCutting() {
    for sex in ["male", "female"] {
        let cut = GoalsCalculator.calculate(sex: sex, goal: .cutting)
        let bulk = GoalsCalculator.calculate(sex: sex, goal: .bulking)
        #expect(bulk.calories > cut.calories)
    }
}

// MARK: - Recálculo proporcional ao trocar de objetivo

@Test func recalculoDaTabelaCasaComATabela() {
    // Partindo exatamente dos valores de manutenção, o resultado é a linha do novo objetivo.
    for sex in ["male", "female"] {
        let base = GoalsCalculator.calculate(sex: sex, goal: .maintenance)
        for goal in [UserGoal.bulking, .cutting] {
            let r = GoalsCalculator.rescale(current: base, sex: sex, from: .maintenance, to: goal)
            let t = GoalsCalculator.calculate(sex: sex, goal: goal)
            #expect(r.calories == t.calories)
            #expect(r.protein == t.protein)
            #expect(r.carbs == t.carbs)
            #expect(r.goodFat == t.goodFat)
            #expect(r.fiber == t.fiber)
        }
    }
}

@Test func recalculoRespeitaValorPersonalizado() {
    var mine = GoalsCalculator.calculate(sex: "male", goal: .maintenance)
    mine.calories = 3000   // personalizado, acima da tabela
    let r = GoalsCalculator.rescale(current: mine, sex: "male", from: .maintenance, to: .bulking)
    // 3000 * 3050 / 2650 = 3452 -> 3450 (passo de 50)
    #expect(r.calories == 3450)
}

@Test func recalculoNaoMexeEmAguaSonoTreinoCardioCreatina() {
    var mine = GoalsCalculator.calculate(sex: "female", goal: .maintenance)
    mine.water = 3500; mine.sleep = 9; mine.creatine = 5; mine.workout = 90; mine.cardio = 30
    let r = GoalsCalculator.rescale(current: mine, sex: "female", from: .maintenance, to: .cutting)
    #expect(r.water == 3500)
    #expect(r.sleep == 9)
    #expect(r.creatine == 5)
    #expect(r.workout == 90)
    #expect(r.cardio == 30)
}

@Test func recalculoIdaEVoltaDevolveOValor() {
    for sex in ["male", "female"] {
        let base = GoalsCalculator.calculate(sex: sex, goal: .maintenance)
        for goal in [UserGoal.bulking, .cutting] {
            let there = GoalsCalculator.rescale(current: base, sex: sex, from: .maintenance, to: goal)
            let back = GoalsCalculator.rescale(current: there, sex: sex, from: goal, to: .maintenance)
            #expect(back == base)
        }
    }
}

@Test func recalculoMesmoObjetivoNaoMuda() {
    let base = GoalsCalculator.calculate(sex: "male", goal: .cutting)
    #expect(GoalsCalculator.rescale(current: base, sex: "male", from: .cutting, to: .cutting) == base)
}

@Test func recalculoLimitaAosRanges() {
    var mine = GoalsCalculator.calculate(sex: "male", goal: .maintenance)
    mine.calories = 10000
    mine.protein = 10
    let r = GoalsCalculator.rescale(current: mine, sex: "male", from: .maintenance, to: .bulking)
    #expect(r.calories == 10000)
    #expect(r.protein == 10)
}

// MARK: - Migração do perfil da 1.0

@Test func migracaoRemoveDadosFisicosENormalizaSexo() {
    let suite = "teste.migracao.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }

    defaults.set(80.0, forKey: "profile.weight")
    defaults.set(180, forKey: "profile.height")
    defaults.set(30, forKey: "profile.age")
    defaults.set(1_000_000.0, forKey: "profile.birthday")
    defaults.set("other", forKey: UserProfile.sexKey)
    defaults.set(2500, forKey: "tracking.calories")

    UserProfile.migrateLegacyProfile(defaults: defaults)

    #expect(defaults.object(forKey: "profile.weight") == nil)
    #expect(defaults.object(forKey: "profile.height") == nil)
    #expect(defaults.object(forKey: "profile.age") == nil)
    #expect(defaults.object(forKey: "profile.birthday") == nil)
    #expect(defaults.string(forKey: UserProfile.sexKey) == "male")
    // Metas já definidas na 1.0 continuam intactas.
    #expect(defaults.integer(forKey: "tracking.calories") == 2500)
}

@Test func sexoFemininoSobreviveAMigracao() {
    let suite = "teste.migracao.f.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    defaults.set("female", forKey: UserProfile.sexKey)
    UserProfile.migrateLegacyProfile(defaults: defaults)
    #expect(defaults.string(forKey: UserProfile.sexKey) == "female")
}

// MARK: - Backup da 1.0

@Test func backupDa10ComDadosFisicosAindaDecodifica() throws {
    let json = """
    {"version":4,"exportedAt":"2026-09-01T12:00:00Z",
     "profile":{"name":"Ana","height":170,"weight":65.5,"age":28,"sex":"other","fitnessGoal":"cutting"},
     "goals":{"calories":2000,"sleep":7,"water":3000,"protein":150,"carbs":300,"fats":80,"fiber":25},
     "goalsOrder":[],"customGoals":[],"dailyRecords":[]}
    """
    let payload = try BackupManager.decode(Data(json.utf8))
    #expect(payload.profile.name == "Ana")
    #expect(payload.goals.calories == 2000)
}

// MARK: - Categoria personalizada (compat com a 1.0)

@Test func categoriaDaV10SemIconeUsaIconePadrao() throws {
    let json = #"{"id":"abc","name":"Alongamento","supportsRestDay":true}"#.data(using: .utf8)!
    let c = try JSONDecoder().decode(CustomGoalCategory.self, from: json)
    #expect(c.symbolName == CustomGoalCategory.defaultSymbolName)
    #expect(c.supportsRestDay)
}

@Test func categoriaComIconeViajaNoJSON() throws {
    let original = CustomGoalCategory(name: "Yoga", supportsRestDay: false, symbolName: "figure.yoga")
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(CustomGoalCategory.self, from: data)
    #expect(decoded.symbolName == "figure.yoga")
}

// MARK: - Estilo de controle no backup (1.1)

@Test func estiloDeControleViajaNoBackup() throws {
    let prefs = BackupPayload.PreferencesSnapshot(
        widgetBackground: nil, widgetBackgroundMode: nil, orientationLock: nil,
        autoWorkoutCheckin: nil, controlStyle: "stepper",
        notificationEnabled: nil, notificationInterval: nil,
        notificationSound: nil, goalIncrements: nil
    )
    let data = try JSONEncoder().encode(prefs)
    let decoded = try JSONDecoder().decode(BackupPayload.PreferencesSnapshot.self, from: data)
    #expect(decoded.controlStyle == "stepper")
}

@Test func preferenciasDaV10SemEstiloDeControleDecodificam() throws {
    let json = #"{"widgetBackground":"x","orientationLock":"portrait"}"#.data(using: .utf8)!
    let prefs = try JSONDecoder().decode(BackupPayload.PreferencesSnapshot.self, from: json)
    #expect(prefs.controlStyle == nil)
    #expect(prefs.widgetBackground == "x")
}
