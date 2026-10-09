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
