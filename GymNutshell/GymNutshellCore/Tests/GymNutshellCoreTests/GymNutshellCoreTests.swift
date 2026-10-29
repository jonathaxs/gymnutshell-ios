import Testing
import Foundation
@testable import GymNutshellCore

// MARK: - Metas padrão (tabela objetivo × sexo)

@Test func metasMasculinasManutencao() {
    let r = GoalsCalculator.calculate(sex: "male", goal: .maintenance)
    #expect(r.water == 2750)
    #expect(r.protein == 150)
    #expect(r.carbs == 260)
    #expect(r.goodFat == 70)
    #expect(r.fiber == 37)
}

@Test func metasFemininasCutting() {
    let r = GoalsCalculator.calculate(sex: "female", goal: .cutting)
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
        #expect(bulk.carbs > cut.carbs)
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
            #expect(r.protein == t.protein)
            #expect(r.carbs == t.carbs)
            #expect(r.goodFat == t.goodFat)
            #expect(r.fiber == t.fiber)
        }
    }
}

@Test func recalculoRespeitaValorPersonalizado() {
    var mine = GoalsCalculator.calculate(sex: "male", goal: .maintenance)
    mine.carbs = 300   // personalizado, acima da tabela
    let r = GoalsCalculator.rescale(current: mine, sex: "male", from: .maintenance, to: .bulking)
    // 300 * 340 / 260 = 392.3 -> 390 (passo de 10)
    #expect(r.carbs == 390)
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
    mine.carbs = 1000
    mine.protein = 10
    let r = GoalsCalculator.rescale(current: mine, sex: "male", from: .maintenance, to: .bulking)
    #expect(r.carbs == 1000)
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
    defaults.set(180, forKey: "tracking.protein")

    UserProfile.migrateLegacyProfile(defaults: defaults)

    #expect(defaults.object(forKey: "profile.weight") == nil)
    #expect(defaults.object(forKey: "profile.height") == nil)
    #expect(defaults.object(forKey: "profile.age") == nil)
    #expect(defaults.object(forKey: "profile.birthday") == nil)
    #expect(defaults.string(forKey: UserProfile.sexKey) == "male")
    // Metas já definidas na 1.0 continuam intactas.
    #expect(defaults.integer(forKey: "tracking.protein") == 180)
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
    #expect(payload.goals.protein == 150)
}

@Test func backupCodificadoMantemCampoCaloriesParaAndroid() throws {
    let goals = BackupPayload.GoalsSnapshot(
        sleep: 8, water: 2500, protein: 150, carbs: 260, goodFat: 70, fiber: 30
    )
    let data = try JSONEncoder().encode(goals)
    let dict = try JSONSerialization.jsonObject(with: data) as? [String: Int]
    #expect(dict?["calories"] == 2000)
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

// MARK: - Tipo de categoria (2.0)

@Test func categoriaDaV10ViraTipoPeloDescanso() throws {
    let comDescanso = #"{"id":"a","name":"Corrida","supportsRestDay":true}"#.data(using: .utf8)!
    let semDescanso = #"{"id":"b","name":"Leitura","supportsRestDay":false}"#.data(using: .utf8)!
    #expect(try JSONDecoder().decode(CustomGoalCategory.self, from: comDescanso).kind == .restDay)
    #expect(try JSONDecoder().decode(CustomGoalCategory.self, from: semDescanso).kind == .standard)
}

@Test func categoriaCheckInViajaNoJSONComCampoAntigo() throws {
    let original = CustomGoalCategory(name: "Vitaminas", kind: .checkIn)
    let data = try JSONEncoder().encode(original)
    let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    #expect(dict?["kind"] as? String == "checkIn")
    #expect(dict?["supportsRestDay"] as? Bool == false)
    #expect(try JSONDecoder().decode(CustomGoalCategory.self, from: data).kind == .checkIn)
}

@Test func tipoDesconhecidoCaiNoPadrao() throws {
    let json = #"{"id":"c","name":"X","kind":"futuro","supportsRestDay":false}"#.data(using: .utf8)!
    #expect(try JSONDecoder().decode(CustomGoalCategory.self, from: json).kind == .standard)
}

@Test func atalhoDeDescansoNaoMexeNoCheckIn() {
    var c = CustomGoalCategory(name: "Meditar", kind: .checkIn)
    c.supportsRestDay = false
    #expect(c.kind == .checkIn)
    c.supportsRestDay = true
    #expect(c.kind == .restDay)
    c.supportsRestDay = false
    #expect(c.kind == .standard)
}

@Test func categoriasFixasTemTipoFixo() {
    #expect(GoalCategory.treino.kind == .restDay)
    #expect(GoalCategory.suplemento.kind == .checkIn)
    #expect(GoalCategory.essencial.kind == .standard)
    #expect(GoalCategory.nutricao.kind == .standard)
}

@Test func metaHerdaTipoDaCategoria() {
    let vitaminas = CustomGoalCategory(id: "v", name: "Vitaminas", kind: .checkIn)
    let emSuplemento = CustomTrackingGoal(emoji: "💊", name: "Vitamina D", unit: "UI", goal: 2000, increment: 2000,
                                          category: .suplemento)
    let emPersonalizada = CustomTrackingGoal(emoji: "🧠", name: "5-HTP", unit: "mg", goal: 100, increment: 100,
                                             customCategoryId: "v")
    let semCategoria = CustomTrackingGoal(emoji: "📖", name: "Ler", unit: "pág", goal: 10, increment: 1)
    let categoriaApagada = CustomTrackingGoal(emoji: "🧘", name: "Meditar", unit: "min", goal: 10, increment: 5,
                                              customCategoryId: "sumiu")
    #expect(emSuplemento.kind(in: []) == .checkIn)
    #expect(emPersonalizada.kind(in: [vitaminas]) == .checkIn)
    #expect(semCategoria.kind(in: [vitaminas]) == .standard)
    #expect(categoriaApagada.kind(in: [vitaminas]) == .standard)
}

@Test func checkInGravaMetaOuZero() {
    #expect(CategoryKind.checkInValue(done: true, goal: 5) == 5)
    #expect(CategoryKind.checkInValue(done: false, goal: 5) == 0)
    #expect(CategoryKind.isCheckInDone(current: 5, goal: 5))
    #expect(!CategoryKind.isCheckInDone(current: 3, goal: 5))
    #expect(!CategoryKind.isCheckInDone(current: 0, goal: 0))
}

// MARK: - Estilo de controle no backup (2.0)

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

// MARK: - Níveis (5 faixas de 20%)

@Test func faixasDosCincoNiveis() {
    #expect(DailyAchievement.from(percent: 0) == .level1)
    #expect(DailyAchievement.from(percent: 20) == .level1)
    #expect(DailyAchievement.from(percent: 21) == .level2)
    #expect(DailyAchievement.from(percent: 40) == .level2)
    #expect(DailyAchievement.from(percent: 41) == .level3)
    #expect(DailyAchievement.from(percent: 61) == .level4)
    #expect(DailyAchievement.from(percent: 80) == .level4)
    #expect(DailyAchievement.from(percent: 81) == .level5)
    #expect(DailyAchievement.from(progress: 1) == .level5)
    #expect(DailyAchievement.level2.percentRange == "21 – 40%")
    #expect(DailyAchievement.level5.next == nil)
}

/// O nível de um dia salvo é lido de volta pelo emoji, então nenhum emoji pode se repetir entre temas/níveis.
@Test func emojisDosNiveisSaoUnicos() {
    let all = AppTheme.allCases.flatMap { theme in DailyAchievement.allCases.map { theme.emoji(for: $0) } }
    #expect(Set(all).count == all.count)
    for theme in AppTheme.allCases {
        for tier in DailyAchievement.allCases {
            #expect(DailyAchievement.from(emoji: theme.emoji(for: tier)) == tier)
        }
    }
}

@Test func registroAntigoReclassificadoPelaPorcentagem() {
    // Dia antigo com 70%: era nível 3, nas faixas novas é nível 4 do mesmo tema.
    let record = DailyRecord(water: 0, protein: 0, carbs: 0, goodFat: 0, fiber: 0, sleep: 0, percent: 70,
                             achievementTitle: "", achievementEmoji: AppTheme.dog.emoji(for: .level3), points: 60)
    record.normalizeAchievement()
    #expect(record.achievementEmoji == AppTheme.dog.emoji(for: .level4))
    #expect(record.points == DailyAchievement.level4.points)
}

// MARK: - Plurais (Localizable.stringsdict)

/// Formata uma chave com plural no idioma pedido, do mesmo jeito que as telas fazem (String(format:)).
private func plural(_ key: String, _ lang: String, _ args: CVarArg...) -> String {
    let path = Bundle.gymNutshellCore.path(forResource: lang, ofType: "lproj")!
    let format = Bundle(path: path)!.localizedString(forKey: key, value: nil, table: nil)
    return String(format: format, arguments: args)
}

@Test func pluralDosDiasEmPortugues() {
    // O zero fica no plural ("0 dias"), mesmo a regra oficial tratando o 0 como singular.
    #expect(plural("statistics.tier.days", "pt-BR", 0) == "0 dias")
    #expect(plural("statistics.tier.days", "pt-BR", 1) == "1 dia")
    #expect(plural("statistics.tier.days", "pt-BR", 5) == "5 dias")
    #expect(plural("statistics.goals.active", "pt-BR", 1) == "1 ativa")
}

@Test func pluralPeloTotalQuandoONumeroVemEmSegundo() {
    #expect(plural("today.category.a11y.value", "pt-BR", 0, 1) == "0 de 1 meta concluída")
    #expect(plural("today.category.a11y.value", "en", 2, 3) == "2 of 3 goals completed")
    #expect(plural("a11y.stats.tier.row.format", "en", "Rooster", 1) == "Rooster, 1 day")
}
