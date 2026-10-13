// ⌘
//  GymNutshell/GymNutshellApp/Views/AchievementsView/AchievementsView.swift
//
//  Propósito: Tela de histórico que lista os DailyRecords salvos,
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
// Exibe todos os DailyRecord salvos via SwiftData, ordenados do mais recente pro mais antigo.
struct AchievementsView: View {

    /// Query do SwiftData que busca todos os registros diários.
    /// Ordenar por data em ordem reversa coloca o dia mais recente primeiro.
    @Query(sort: \DailyRecord.date, order: .reverse) private var records: [DailyRecord]

    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppTheme.storageKey) private var selectedTheme: AppTheme = .gym
    @AppStorage(AppAccentColor.storageKey) private var storedColorRaw: String = AppAccentColor.blue.rawValue
    private var accentColor: Color { (AppAccentColor(rawValue: storedColorRaw) ?? .blue).color }
    @AppStorage(UserProfile.sexKey) private var sex: String = "male"

    /// Controla qual registro está sendo exibido em um sheet.
    /// - view: detalhes somente leitura pra qualquer dia
    /// - edit: sheet editável pra entradas recentes
    @State private var activeSheet: ActiveSheet?

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

    // MARK: - Lista de histórico

    /// Registros visíveis, do mais recente pro mais antigo.
    /// No modo de filtro "day", só os do dia selecionado.
    private var visibleRecords: [DailyRecord] {
        switch filterMode {
        case .all:
            return records
        case .day:
            return records.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
        }
    }

    // MARK: - Mapeamento de emojis do calendário

    // Cria um mapeamento de cada dia registrado -> emoji pra mostrar no calendário.
    // Emojis diários são convertidos pro tema atual.
    private var emojiByDay: [Date: String] {
        let calendar = Calendar.current

        // Usa o emoji do tema atual pra cada registro diário (não o achievementEmoji salvo)
        // pra que o calendário sempre reflita o tema ativo, mesmo pra registros antigos.
        return Dictionary(
            uniqueKeysWithValues: records.map {
                let tier = DailyAchievement.from(emoji: $0.achievementEmoji)
                return (calendar.startOfDay(for: $0.date), selectedTheme.emoji(for: tier))
            }
        )
    }

    /// Mesmo conjunto de dias que `emojiByDay`, mas com o nome a ser falado no
    /// VoiceOver (nome do tier do tema atual).
    private var tierNameByDay: [Date: String] {
        let calendar = Calendar.current
        return Dictionary(
            uniqueKeysWithValues: records.map {
                let tier = DailyAchievement.from(emoji: $0.achievementEmoji)
                return (calendar.startOfDay(for: $0.date), selectedTheme.name(for: tier, sex: sex))
            }
        )
    }

    // MARK: - Ações

    // Apaga o registro diário selecionado do banco de dados.
    private func deleteItem(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(visibleRecords[index])
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
        GeometryReader { geo in
            let isWide = geo.size.width >= 700
            Group {
                if isWide {
                    // Wide: cap em 860pt e centralizado.
                    VStack(alignment: .leading, spacing: 0) {
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
                                    if visibleRecords.isEmpty {
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

                                if visibleRecords.isEmpty {
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

                        if visibleRecords.isEmpty {
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
        }
        .navigationTitle(String(localized: "achievements.header.title", bundle: .gymNutshellCore))
        // Troca calendário ↔ lista (como o botão lista/grade da Hoje), só ícone.
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                filterModeButton
            }
        }
        .onAppear {
            filterMode = FilterMode(rawValue: storedFilterMode) ?? .day
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
        // Deep-link da notificação de Conquista, força filtro "dia" na data
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
    }

    // MARK: - Botão calendário ↔ lista

    /// Mostra o modo pra onde vai: no calendário, o ícone de lista; na lista, o de calendário.
    private var filterModeButton: some View {
        let next: FilterMode = filterMode == .day ? .all : .day
        return Button {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.easeInOut(duration: 0.25)) { filterMode = next }
        } label: {
            Image(systemName: next == .all ? "list.bullet" : "calendar")
                .contentTransition(.symbolEffect(.replace))
        }
        .accessibilityLabel(String(localized: next == .all ? "a11y.achievements.filter.all"
                                                            : "a11y.achievements.filter.day",
                                   bundle: .gymNutshellCore))
    }

    // MARK: - Seção de histórico (extraída pra reuso no layout wide/narrow)

    @ViewBuilder
    private var historySection: some View {
        ForEach(visibleRecords) { record in
            let achievement = dailyAchievement(for: record)
            HistoryDailyRow(
                record: record,
                tierName: selectedTheme.name(for: achievement, sex: sex),
                tierEmoji: selectedTheme.emoji(for: achievement),
                canEdit: canEdit(record),
                onTap: { activeSheet = .view(record) },
                onEdit: { activeSheet = .edit(record) }
            )
        }
        .onDelete { offsets in
            deleteItem(offsets: offsets)
        }
    }
}

#Preview {
    AchievementsView()
        .modelContainer(for: DailyRecord.self, inMemory: true)
}
