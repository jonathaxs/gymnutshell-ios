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

// MARK: - Lembretes por horário (suplementos)

private func dataFixa(_ dia: Int, _ hora: Int, _ minuto: Int) -> Date {
    var c = DateComponents()
    c.year = 2026; c.month = 11; c.day = dia; c.hour = hora; c.minute = minuto
    return Calendar.current.date(from: c)!
}

private let manha = ReminderTime(hour: 8, minute: 0)
private let noite = ReminderTime(hour: 22, minute: 30)

@Test func lembretePulaHorariosQueJaPassaram() {
    let creatina = SupplementReminderEntry(id: "creatine", emoji: "🧪", name: "Creatina",
                                           times: [manha, noite], doneToday: false)
    let plano = SupplementReminderPlanner.plan(entries: [creatina], now: dataFixa(1, 10, 0), grouped: false)
    // Hoje só as 22:30; amanhã e depois, os dois horários.
    #expect(plano.count == 5)
    #expect(plano.first?.fireDate == dataFixa(1, 22, 30))
    #expect(plano.allSatisfy { $0.fireDate > dataFixa(1, 10, 0) })
}

@Test func lembretePulaHojeQuandoJaFeito() {
    let creatina = SupplementReminderEntry(id: "creatine", emoji: "🧪", name: "Creatina",
                                           times: [noite], doneToday: true)
    let plano = SupplementReminderPlanner.plan(entries: [creatina], now: dataFixa(1, 10, 0), grouped: false)
    #expect(plano.map(\.fireDate) == [dataFixa(2, 22, 30), dataFixa(3, 22, 30)])
}

@Test func lembreteUmAvisoPorSuplementoPorPadrao() {
    let a = SupplementReminderEntry(id: "a", emoji: "🧪", name: "Creatina", times: [manha], doneToday: false)
    let b = SupplementReminderEntry(id: "b", emoji: "🐟", name: "Ômega 3", times: [manha], doneToday: false)
    let plano = SupplementReminderPlanner.plan(entries: [a, b], now: dataFixa(1, 6, 0), grouped: false, days: 1)
    #expect(plano.count == 2)
    #expect(Set(plano.map(\.identifier)).count == 2)
}

@Test func lembreteAgrupadoJuntaMesmoHorario() {
    let a = SupplementReminderEntry(id: "a", emoji: "🧪", name: "Creatina", times: [manha, noite], doneToday: false)
    let b = SupplementReminderEntry(id: "b", emoji: "🐟", name: "Ômega 3", times: [manha], doneToday: false)
    let plano = SupplementReminderPlanner.plan(entries: [a, b], now: dataFixa(1, 6, 0), grouped: true, days: 1)
    #expect(plano.count == 2)
    #expect(plano[0].entryIds == ["a", "b"])
    #expect(plano[1].entryIds == ["a"])
}

@Test func lembreteSemEmojiPorPadrao() {
    let a = SupplementReminderEntry(id: "a", emoji: "🧪", name: "Creatina", times: [manha], doneToday: false)
    let b = SupplementReminderEntry(id: "b", emoji: "🐟", name: "Ômega 3", times: [manha], doneToday: false)
    let sozinho = SupplementReminderPlanner.plan(entries: [a], now: dataFixa(1, 6, 0), grouped: false, days: 1)
    #expect(sozinho.first?.title == "Creatina")
    let agrupado = SupplementReminderPlanner.plan(entries: [a, b], now: dataFixa(1, 6, 0), grouped: true, days: 1)
    #expect(agrupado.first?.body.contains("🧪") == false)
    #expect(agrupado.first?.title.hasPrefix("⏰") == false)
}

@Test func lembreteComEmojiQuandoLigado() {
    let a = SupplementReminderEntry(id: "a", emoji: "🧪", name: "Creatina", times: [manha], doneToday: false)
    let b = SupplementReminderEntry(id: "b", emoji: "🐟", name: "Ômega 3", times: [manha], doneToday: false)
    let sozinho = SupplementReminderPlanner.plan(entries: [a], now: dataFixa(1, 6, 0), grouped: false,
                                                 showEmoji: true, days: 1)
    #expect(sozinho.first?.title == "🧪 Creatina")
    let agrupado = SupplementReminderPlanner.plan(entries: [a, b], now: dataFixa(1, 6, 0), grouped: true,
                                                  showEmoji: true, days: 1)
    #expect(agrupado.first?.body.contains("🐟 Ômega 3") == true)
    #expect(agrupado.first?.title.hasPrefix("⏰ ") == true)
}

@Test func lembreteRespeitaOTeto() {
    let horarios = (0..<24).map { ReminderTime(hour: $0, minute: 0) }
    let a = SupplementReminderEntry(id: "a", emoji: "🧪", name: "A", times: horarios, doneToday: false)
    let plano = SupplementReminderPlanner.plan(entries: [a], now: dataFixa(1, 0, 30), grouped: false)
    #expect(plano.count == SupplementReminderPlanner.maxPending)
    #expect(plano.map(\.fireDate) == plano.map(\.fireDate).sorted())
}

@Test func horarioDoLembreteIdaEVoltaNoBackup() {
    #expect(ReminderTime(storageString: "08:05") == ReminderTime(hour: 8, minute: 5))
    #expect(ReminderTime(hour: 22, minute: 30).storageString == "22:30")
    #expect(ReminderTime(storageString: "25:00") == nil)
}

// MARK: - Bônus de sequência e pontos

private func bonusDay(_ y: Int, _ m: Int, _ d: Int) -> Date {
    StreakBonusCalculator.weekCalendar.date(from: DateComponents(year: y, month: m, day: d))!
}

/// Dias seguidos a partir de `start` com os níveis dados.
private func bonusLevels(from start: Date, _ numbers: [Int]) -> [Date: DailyAchievement] {
    var result: [Date: DailyAchievement] = [:]
    for (i, n) in numbers.enumerated() {
        let date = StreakBonusCalculator.weekCalendar.date(byAdding: .day, value: i, to: start)!
        result[date] = DailyAchievement.allCases[n - 1]
    }
    return result
}

@Test func pontosDoDiaSaoONumeroDoNivel() {
    #expect(DailyAchievement.allCases.map(\.points) == [1, 2, 3, 4, 5])
}

@Test func semanaNivel4ou5DaOitoPontos() {
    // 2026-11-02 é segunda; a semana fecha no domingo 08.
    let bonuses = StreakBonusCalculator.bonuses(levels: bonusLevels(from: bonusDay(2026, 11, 2), [4, 5, 4, 5, 5, 4, 5]))
    #expect(bonuses.map(\.kind) == [.weeklyLevel4])
    #expect(bonuses.first?.anchorDate == bonusDay(2026, 11, 8))
    #expect(bonuses.first?.points == 8)
}

@Test func semanaSoNivel5DaSoOBonusMaior() {
    let bonuses = StreakBonusCalculator.bonuses(levels: bonusLevels(from: bonusDay(2026, 11, 2), Array(repeating: 5, count: 7)))
    #expect(bonuses.map(\.kind) == [.weeklyLevel5])
    #expect(bonuses.first?.points == 12)
}

@Test func semanaComNivel3OuDiaFaltandoNaoDaBonus() {
    #expect(StreakBonusCalculator.bonuses(levels: bonusLevels(from: bonusDay(2026, 11, 2), [5, 5, 3, 5, 5, 5, 5])).isEmpty)
    var falta = bonusLevels(from: bonusDay(2026, 11, 2), Array(repeating: 5, count: 7))
    falta[bonusDay(2026, 11, 4)] = nil
    #expect(StreakBonusCalculator.bonuses(levels: falta).isEmpty)
    // Domingo a sábado não é semana de bônus (a semana vai de segunda a domingo).
    #expect(StreakBonusCalculator.bonuses(levels: bonusLevels(from: bonusDay(2026, 11, 1), Array(repeating: 5, count: 7))).isEmpty)
}

@Test func mesInteiroDaBonusMensalAlemDosSemanais() {
    // Fevereiro de 2027: 28 dias, de segunda 1 a domingo 28, todos nível 5.
    let bonuses = StreakBonusCalculator.bonuses(levels: bonusLevels(from: bonusDay(2027, 2, 1), Array(repeating: 5, count: 28)))
    #expect(bonuses.filter { $0.kind == .monthlyLevel5 }.count == 1)
    #expect(bonuses.filter { $0.kind == .weeklyLevel5 }.count == 4)
    #expect(bonuses.first?.kind == .monthlyLevel5)
    #expect(bonuses.reduce(0) { $0 + $1.points } == 33 + 4 * 12)

    var misto = bonusLevels(from: bonusDay(2027, 2, 1), Array(repeating: 5, count: 28))
    misto[bonusDay(2027, 2, 10)] = .level4
    let mistoBonuses = StreakBonusCalculator.bonuses(levels: misto)
    #expect(mistoBonuses.filter { $0.kind == .monthlyLevel4 }.count == 1)
    #expect(mistoBonuses.filter { $0.kind == .weeklyLevel4 }.count == 1)
}

@Test func idDoBonusEhEstavel() {
    let bonus = EarnedStreakBonus(kind: .weeklyLevel5, anchorDate: bonusDay(2026, 11, 8))
    #expect(bonus.id == "weekly.level5.2026-11-08")
}

// MARK: - CSV de treino do ML

@Test func csvDeTreinoOrdenaEFormata() {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "UTC")!
    let sabado = cal.date(from: DateComponents(year: 2026, month: 11, day: 7))!
    let domingo = cal.date(from: DateComponents(year: 2026, month: 11, day: 8))!
    func dia(_ date: Date, _ percent: Int) -> TrainingDay {
        TrainingDay(date: date, water: 2000, protein: 120, carbs: 200, goodFat: 50, fiber: 30, sleep: 7,
                    didWorkout: true, didCardio: false, workoutRestDay: false, cardioRestDay: true,
                    percent: percent, points: 10)
    }
    let csv = TrainingCSV.make(days: [dia(domingo, 40), dia(sabado, 90)], calendar: cal)
    let linhas = csv.split(separator: "\n").map(String.init)
    #expect(linhas.count == 3)
    #expect(linhas[0] == TrainingCSV.header)
    #expect(linhas[1] == "2026-11-07,7,2000,120,200,50,30,7,1,0,0,1,90,10")
    #expect(linhas[2] == "2026-11-08,1,2000,120,200,50,30,7,1,0,0,1,40,10")
}

// MARK: - Modelo de dia de risco (ML)

private func calendarioUTC() -> Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "UTC")!
    return cal
}

/// Histórico sintético: `count` dias seguidos a partir de 2026-01-05 (segunda), percent por regra.
private func historico(_ count: Int, _ cal: Calendar, percent: (Int, Date) -> Int) -> [TrainingDay] {
    let inicio = cal.date(from: DateComponents(year: 2026, month: 1, day: 5))!
    return (0..<count).map { i in
        let d = cal.date(byAdding: .day, value: i, to: inicio)!
        return TrainingDay(date: d, water: 2000, protein: 100, carbs: 200, goodFat: 50, fiber: 30, sleep: 7,
                           didWorkout: true, didCardio: false, workoutRestDay: false, cardioRestDay: false,
                           percent: percent(i, d), points: 0)
    }
}

@Test func sigmoidNoZeroEMeio() {
    #expect(LogisticRegression.sigmoid(0) == 0.5)
}

@Test func regressaoLogisticaSeparaCasoSimples() {
    let x: [[Double]] = [[-2], [-1], [1], [2]]
    let y: [Double] = [0, 0, 1, 1]
    let m = LogisticRegression.train(x: x, y: y, epochs: 500, l2: 0)
    #expect(m.weights[0] > 0)
    #expect(m.probability([2]) > 0.8)
    #expect(m.probability([-2]) < 0.2)
}

@Test func normalizacaoUsaMediaEDesvio() {
    let s = Standardizer(fitting: [[1, 5], [3, 5]])
    #expect(s.means == [2, 5])
    #expect(s.stds == [1, 1])  // segunda coluna é constante: desvio vira 1
    #expect(s.transform([3, 5]) == [1, 0])
}

@Test func featuresOlhamSoOPassado() {
    let cal = calendarioUTC()
    let dias = historico(10, cal) { i, _ in i == 8 ? 30 : 90 }
    let idx = RiskFeatures.index(dias, calendar: cal)
    // Dia 9 (quarta 14/01): ontem foi o dia fraco (30%), sequência zerada.
    let v = RiskFeatures.vector(for: dias[9].date, history: idx, weakThreshold: 60, calendar: cal)
    #expect(v.count == RiskFeatures.names.count)
    #expect(v[3] == 1)               // quarta
    #expect(v[7] == 0.3)             // ontem_percent
    #expect(v[8] == 0)               // ontem tem registro
    #expect(v[11] == 0)              // sequência
    // Dia 8 olhando pra trás: 7 dias bons seguidos antes dele (o dia 0 fica fora da janela de 7).
    let v8 = RiskFeatures.vector(for: dias[8].date, history: idx, weakThreshold: 60, calendar: cal)
    #expect(v8[11] == 8.0 / 14)
    #expect(v8[10] == 1)
}

@Test func riscoPrecisaDeDiasMinimos() {
    let cal = calendarioUTC()
    #expect(RiskModel.evaluate(days: historico(20, cal) { _, _ in 90 }, calendar: cal) == nil)
}

@Test func riscoComPadraoDeSabadoEmpataComARegra() {
    // Sábado sempre fraco: a regra do dia da semana já acerta tudo, o modelo não pode "ganhar".
    let cal = calendarioUTC()
    let dias = historico(70, cal) { _, d in cal.component(.weekday, from: d) == 7 ? 20 : 90 }
    let r = RiskModel.evaluate(days: dias, calendar: cal)!
    #expect(r.trainCount == 56)
    #expect(r.validationCount == 14)
    #expect(r.weekdayAccuracy == 1)
    #expect(r.modelAccuracy == 1)
    #expect(!r.beatsBaseline)
    let sabado = cal.date(byAdding: .day, value: 75, to: dias[0].date)!  // 2026-03-21, sábado
    #expect(RiskModel.riskProbability(for: sabado, days: dias, report: r, calendar: cal) > 0.5)
}

@Test func riscoComPadraoDeOntemGanhaDaRegra() {
    // Ciclo de 5 dias (3 bons, 2 fracos): não bate com a semana, mas "ontem" e a sequência explicam.
    let cal = calendarioUTC()
    let dias = historico(100, cal) { i, _ in i % 5 >= 3 ? 30 : 90 }
    let r = RiskModel.evaluate(days: dias, calendar: cal)!
    #expect(r.modelAccuracy > r.weekdayAccuracy)
    #expect(r.beatsBaseline)
}

// MARK: - Média por dia da semana

@Test func mediaPorDiaDaSemanaCalculaCorretamente() {
    var cal = calendarioUTC()
    cal.firstWeekday = 1
    // 14 dias (2 semanas completas): em cada dia da semana w, a 1ª semana tem 10*w e a 2ª tem 10*w + 10.
    let dias = historico(14, cal) { i, d in
        let w = cal.component(.weekday, from: d)
        return i < 7 ? w * 10 : w * 10 + 10
    }
    let medias = WeekdayStats.averages(days: dias, calendar: cal)
    #expect(medias.count == 7)
    #expect(medias.map(\.weekday) == [1, 2, 3, 4, 5, 6, 7])
    for item in medias {
        #expect(item.count == 2)
        #expect(item.average == Double(item.weekday * 10 + 5))
    }
}

@Test func mediaPorDiaDaSemanaSegueFirstWeekdayEOmiteSemRegistro() {
    var cal = calendarioUTC()
    cal.firstWeekday = 2 // começa na segunda-feira (2)
    let semana = historico(7, cal) { i, _ in (i + 1) * 10 }
    // Só domingo (índice 6, weekday 1), segunda (índice 0, weekday 2) e quarta (índice 2, weekday 4).
    let dias = [semana[6], semana[0], semana[2]]
    let medias = WeekdayStats.averages(days: dias, calendar: cal)
    #expect(medias.map(\.weekday) == [2, 4, 1])
    #expect(medias.map(\.average) == [10, 30, 70])
    #expect(medias.map(\.count) == [1, 1, 1])
}

