// ⌘
//  GymNutshell/GymNutshellApp/Views/AchievementsView/AchievementsView.swift
//
//  Propósito: Tela de histórico que lista os DailyRecords e StreakBonus salvos,
//             mostra o saldo total de pontos e permite editar registros recentes.
//
//  Created by Jonathas Motta (@jonathaxs) on 2025-11-14.
// ⌘

import SwiftUI
import GymNutshellCore
import SwiftData

// View de calendário customizado pra exibir emojis de conquista por dia.
// (Definida em MonthlyCalendarView.swift)

// MARK: - Tela de conquistas
// Exibe todos os DailyRecord e StreakBonus salvos via SwiftData,
// ordenados do mais recente pro mais antigo. Bônus de streak aparecem inline na lista.
struct AchievementsView: View {

    /// Query do SwiftData que busca todos os registros diários.
    /// Ordenar por data em ordem reversa coloca o dia mais recente primeiro.
    @Query(sort: \DailyRecord.date, order: .reverse) private var records: [DailyRecord]

    /// Query do SwiftData para entradas de bônus de streak (semanal e mensal).
    @Query(sort: \StreakBonus.anchorDate, order: .reverse) private var bonuses: [StreakBonus]

    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppTheme.storageKey) private var selectedTheme: AppTheme = .gym
    @AppStorage(AppAccentColor.storageKey) private var storedColorRaw: String = AppAccentColor.blue.rawValue
    private var accentColor: Color { (AppAccentColor(rawValue: storedColorRaw) ?? .blue).color }
    @AppStorage(UserProfile.sexKey) private var sex: String = "male"

    /// Controla qual registro está sendo exibido em um sheet.
    /// - view: detalhes somente leitura pra qualquer dia
    /// - edit: sheet editável pra entradas recentes
    @State private var activeSheet: ActiveSheet?
    @State private var showBonusInfoSheet = false

    private enum ActiveSheet: Identifiable {
        case view(DailyRecord)
        case edit(DailyRecord)

        var id: String {
            switch self {
            case .view(let record):
                return "view-\(record.id)"
            case .edit(let record):
                return "edit-\(record.id)"
            }
        }

        var record: DailyRecord {
            switch self {
            case .view(let record), .edit(let record):
                return record
            }
        }
    }

    private enum FilterMode: String {
        case all
        case day
    }

    // Persiste a última seleção do usuário nos filtros da tela de conquistas.
    @AppStorage(UserProfile.achievementsFilterModeKey) private var storedFilterMode: String = FilterMode.day.rawValue
    @AppStorage(UserProfile.achievementsSelectedDateKey) private var storedSelectedDateTimestamp: Double = Date().timeIntervalSince1970

    // Controla a filtragem da lista na tela de conquistas.
    @State private var filterMode: FilterMode = .all
    @State private var selectedDate: Date = Date()
    @State private var visibleMonthDate: Date = Date()

    // Define por quanto tempo um registro permanece editável após ser criado.
    private static let editWindowHours: Int = 72
    private static let editWindow: TimeInterval = TimeInterval(Self.editWindowHours * 60 * 60)

    // MARK: - Saldo de pontos

    /// Total de pontos ganhos em todos os registros diários e bônus de streak.
    /// É a pontuação acumulada do usuário mostrada no topo da tela.
    private var totalPoints: Int {
        let dailyTotal = records.reduce(0) { $0 + $1.points }
        let bonusTotal = bonuses.reduce(0) { $0 + $1.bonusPoints }
        return dailyTotal + bonusTotal
    }

    // MARK: - Lista de histórico unificada

    /// Uma entrada da lista que representa um registro diário ou um bônus de streak.
    /// Usada pra que os dois tipos possam ser renderizados juntos num único ForEach ordenado.
    private enum HistoryItem: Identifiable {
        case daily(DailyRecord)
        case bonus(StreakBonus)

        var id: String {
            switch self {
            case .daily(let r): return "daily-\(r.id)"
            case .bonus(let b): return "bonus-\(b.id)"
            }
        }

        // Data usada pra ordenação, daily usa a data do registro, bonus usa anchorDate.
        var date: Date {
            switch self {
            case .daily(let r): return r.date
            case .bonus(let b): return b.anchorDate
            }
        }
    }

    /// Mescla registros diários e bônus de streak em uma lista única ordenada do mais recente.
    /// No modo de filtro "day", só itens do dia selecionado são incluídos.
    private var visibleItems: [HistoryItem] {
        let calendar = Calendar.current

        let filteredRecords: [DailyRecord]
        let filteredBonuses: [StreakBonus]

        switch filterMode {
        case .all:
            filteredRecords = records
            filteredBonuses = bonuses
        case .day:
            filteredRecords = records.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
            filteredBonuses = bonuses.filter { calendar.isDate($0.anchorDate, inSameDayAs: selectedDate) }
        }

        let dailyItems = filteredRecords.map { HistoryItem.daily($0) }
        let bonusItems = filteredBonuses.map { HistoryItem.bonus($0) }

        // Ordena do mais recente pro mais antigo, igual ao comportamento da lista de registros diários.
        return (dailyItems + bonusItems).sorted { $0.date > $1.date }
    }

    // MARK: - Mapeamento de emojis do calendário

    // Cria um mapeamento de cada dia registrado -> emoji pra mostrar no calendário.
    // Emojis diários são convertidos pro tema atual. Emojis de bônus (✍️ 🪽 🦾 ☠️)
    // têm prioridade nas datas âncora. Bônus mensal vence sobre o semanal na mesma data.
    private var emojiByDay: [Date: String] {
        let calendar = Calendar.current

        // Usa o emoji do tema atual pra cada registro diário (não o achievementEmoji salvo)
        // pra que o calendário sempre reflita o tema ativo, mesmo pra registros antigos.
        var result: [Date: String] = Dictionary(
            uniqueKeysWithValues: records.map {
                let tier = DailyAchievement.from(emoji: $0.achievementEmoji)
                return (calendar.startOfDay(for: $0.date), selectedTheme.emoji(for: tier))
            }
        )

        // Aplica bônus semanais primeiro, depois mensais pra que o mensal tenha prioridade na sobreposição.
        let weeklyBonuses = bonuses.filter { $0.bonusType.hasPrefix("weekly") }
        let monthlyBonuses = bonuses.filter { $0.bonusType.hasPrefix("monthly") }

        for bonus in weeklyBonuses + monthlyBonuses {
            let key = calendar.startOfDay(for: bonus.anchorDate)
            result[key] = bonus.displayEmoji
        }

        return result
    }

    /// Mesmo conjunto de dias que `emojiByDay`, mas com o nome a ser falado no
    /// VoiceOver (nome do tier do tema atual; substituído pelo título do bônus
    /// quando há StreakBonus na mesma data, bônus mensal vence sobre semanal).
    private var tierNameByDay: [Date: String] {
        let calendar = Calendar.current
        var result: [Date: String] = Dictionary(
            uniqueKeysWithValues: records.map {
                let tier = DailyAchievement.from(emoji: $0.achievementEmoji)
                return (calendar.startOfDay(for: $0.date), selectedTheme.name(for: tier, sex: sex))
            }
        )

        let weeklyBonuses = bonuses.filter { $0.bonusType.hasPrefix("weekly") }
        let monthlyBonuses = bonuses.filter { $0.bonusType.hasPrefix("monthly") }
        for bonus in weeklyBonuses + monthlyBonuses {
            let key = calendar.startOfDay(for: bonus.anchorDate)
            result[key] = bonus.displayTitle
        }
        return result
    }

    // MARK: - Ações

    // Apaga o registro diário selecionado do banco de dados.
    // Bônus de streak não são deletáveis pelo usuário, são calculados a partir de períodos concluídos.
    private func deleteItem(offsets: IndexSet) {
        for index in offsets {
            if case .daily(let record) = visibleItems[index] {
                modelContext.delete(record)
            }
        }
    }

    // Um registro só pode ser editado dentro da janela de edição configurada (padrão: 72 horas).
    private func canEdit(_ record: DailyRecord) -> Bool {
        let now = Date()
        let interval = now.timeIntervalSince(record.date)
        return interval >= 0 && interval <= Self.editWindow
    }

    private func dailyAchievement(for record: DailyRecord) -> DailyAchievement {
        // Usa o emoji salvo como fonte da verdade pro nível histórico.
        // Isso evita inconsistências quando `percent` é arredondado perto dos limiares.
        return DailyAchievement.from(emoji: record.achievementEmoji)
    }

    // Retorna o início do mês pra qualquer data fornecida.
    private func startOfMonth(for date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }

    // Título do mês legível usado acima do calendário customizado.
    private var visibleMonthTitle: String {
        AppDateFormatters.monthYear.string(from: visibleMonthDate)
    }

    // Move o mês visível pelo offset fornecido (ex.: -1 = mês anterior).
    private func changeMonth(by offset: Int) {
        let calendar = Calendar.current
        if let next = calendar.date(byAdding: .month, value: offset, to: visibleMonthDate) {
            visibleMonthDate = startOfMonth(for: next)
        }
    }

    // MARK: - Seção de calendário (extraída pra reuso no layout wide/narrow)

    @ViewBuilder
    private var calendarSection: some View {
        Section {
            Picker(String(localized: "achievements.filter.title", bundle: .gymNutshellCore), selection: $filterMode) {
                Text(String(localized: "achievements.filter.day", bundle: .gymNutshellCore))
                    .accessibilityLabel(String(localized: "a11y.achievements.filter.day", bundle: .gymNutshellCore))
                    .tag(FilterMode.day)
                Text(String(localized: "achievements.filter.all", bundle: .gymNutshellCore))
                    .accessibilityLabel(String(localized: "a11y.achievements.filter.all", bundle: .gymNutshellCore))
                    .tag(FilterMode.all)
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))

            if filterMode == .day {
                // Calendário num card próprio (o card já traz fundo e cantos).
                AchievementsCalendarSection(
                    visibleMonthTitle: visibleMonthTitle,
                    visibleMonthDate: visibleMonthDate,
                    selectedDate: $selectedDate,
                    emojiByDay: emojiByDay,
                    tierNameByDay: tierNameByDay,
                    onChangeMonth: { changeMonth(by: $0) }
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
            }
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let isWide = geo.size.width >= 700
                Group {
                    if isWide {
                        // Wide: cap em 860pt e centralizado, com cabeçalho customizado
                        // alinhado à mesma borda que o conteúdo (igual StatisticsView).
                        VStack(alignment: .leading, spacing: 0) {
                            wideTitleBar
                            if filterMode == .day {
                                // Calendário à esquerda, histórico à direita.
                                HStack(alignment: .top, spacing: 0) {
                                    List {
                                        calendarSection
                                    }
                                    .frame(maxWidth: 400)
                                    .listStyle(.insetGrouped)

                                    Divider()

                                    List {
                                        if visibleItems.isEmpty {
                                            Section {
                                                AchievementsEmptyState(accentColor: accentColor)
                                                    .listRowBackground(Color.clear)
                                            }
                                        } else {
                                            // Section header invisível só pra forçar o mesmo
                                            // inset superior que o calendário tem por causa do
                                            // header da `calendarSection`. Sem isso, no macOS e
                                            // iPhone landscape o `.insetGrouped` deixa a lista
                                            // colada no topo enquanto o calendário tem respiro.
                                            Section {
                                                historySection
                                            } header: {
                                                Color.clear.frame(height: 0)
                                            }
                                        }
                                    }
                                    .listStyle(.insetGrouped)
                                }
                            } else {
                                // Lista completa: painel único sem coluna de calendário.
                                List {
                                    calendarSection

                                    if visibleItems.isEmpty {
                                        Section {
                                            AchievementsEmptyState(accentColor: accentColor)
                                                .listRowBackground(Color.clear)
                                        }
                                    } else {
                                        historySection
                                    }
                                }
                                .listStyle(.insetGrouped)
                            }
                        }
                        .frame(maxWidth: 860)
                        .frame(maxWidth: .infinity)
                    } else {
                        // Narrow (iPhone portrait): layout original com tudo numa List.
                        List {
                            calendarSection

                            if visibleItems.isEmpty {
                                Section {
                                    AchievementsEmptyState(accentColor: accentColor)
                                        .listRowBackground(Color.clear)
                                }
                            } else {
                                historySection
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Fundo cinza por toda a viewport, sem isso, no modo wide, as
                // margens fora do cap de 860pt ficam brancas em light mode.
                .background(Color(.systemGroupedBackground))
                .toolbar(.hidden, for: .navigationBar)
                .safeAreaInset(edge: .top, spacing: 0) {
                    if !isWide {
                        AppTabHeader(title: String(localized: "achievements.header.title", bundle: .gymNutshellCore))
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                            .background(Color(.systemGroupedBackground))
                    }
                }
            }
            .navigationTitle(String(localized: "achievements.header.title", bundle: .gymNutshellCore))
            .onAppear {
                filterMode = FilterMode(rawValue: storedFilterMode) ?? .all
                selectedDate = Date(timeIntervalSince1970: storedSelectedDateTimestamp)
                visibleMonthDate = startOfMonth(for: selectedDate)
            }
            .onChange(of: filterMode) { _, newValue in
                storedFilterMode = newValue.rawValue
            }
            .onChange(of: selectedDate) { _, newValue in
                storedSelectedDateTimestamp = newValue.timeIntervalSince1970
                visibleMonthDate = startOfMonth(for: newValue)
            }
            // Deep-link das notificações de Conquista / Bônus, força filtro "dia" na data
            // que veio no userInfo (data real da conquista); cai pra hoje se ausente.
            .onReceive(NotificationCenter.default.publisher(for: .gaAchievementsShowToday)) { note in
                let target: Date
                if let ts = note.userInfo?["achievementDate"] as? Double {
                    target = Date(timeIntervalSince1970: ts)
                } else {
                    target = Date()
                }
                filterMode = .day
                selectedDate = target
                visibleMonthDate = startOfMonth(for: target)
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .view(let record):
                NavigationStack {
                    RecordDetailView(
                        canEdit: canEdit(record),
                        onEdit: {
                            activeSheet = .edit(record)
                        },
                        record: record
                    )
                }
            case .edit(let record):
                EditTodayView(record: record)
            }
        }
        .sheet(isPresented: $showBonusInfoSheet) {
            NavigationStack {
                StreakBonusInfoView(isSheet: true)
            }
        }
    }

    // Cabeçalho customizado usado no wideLayout, bell + título alinhados ao
    // mesmo maxWidth (860pt) do conteúdo, mesma técnica usada em StatisticsView.
    @ViewBuilder
    private var wideTitleBar: some View {
        AppTabHeader(title: String(localized: "achievements.header.title", bundle: .gymNutshellCore))
            .padding(.horizontal)
            .padding(.top, 12)
            .frame(maxWidth: 860)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Seção de histórico (extraída pra reuso no layout wide/narrow)

    @ViewBuilder
    private var historySection: some View {
        ForEach(visibleItems) { item in
            switch item {
            case .daily(let record):
                let achievement = dailyAchievement(for: record)
                HistoryDailyRow(
                    record: record,
                    tierName: selectedTheme.name(for: achievement, sex: sex),
                    tierEmoji: selectedTheme.emoji(for: achievement),
                    canEdit: canEdit(record),
                    onTap: { activeSheet = .view(record) },
                    onEdit: { activeSheet = .edit(record) }
                )
            case .bonus(let bonus):
                HistoryBonusRow(bonus: bonus, onTap: { showBonusInfoSheet = true })
            }
        }
        .onDelete { offsets in
            // Só registros diários podem ser deletados; linhas de bônus são silenciosamente ignoradas.
            deleteItem(offsets: offsets)
        }
    }
}

#Preview {
    AchievementsView()
        .modelContainer(for: [DailyRecord.self, StreakBonus.self], inMemory: true)
}
