// ⌘
//  GymNutshell/GymNutshellApp/Views/SettingsView/SettingsView.swift
//
//  Propósito: Página de Ajustes (empurrada no stack raiz). Contém links pra edição de perfil,
//             gerenciamento de metas e preferências do app. No layout largo (iPad, iPhone Duo aberto) fica
//             como os Ajustes do iPad: lista à esquerda e a página escolhida à direita.
//
//  Created by Jonathas Motta (@jonathaxs) on 2025-11-24.
// ⌘

import SwiftUI
import GymNutshellCore

/// Páginas dos Ajustes, na ordem da lista. Cada uma tem o título, o ícone de vidro e a seção.
/// `ring`, `tier`, `bonus` e `dayInsight` aparecem na seção Detalhes da página do Gym Nutshell (AboutView).
enum SettingsPage: Hashable, CaseIterable, Identifiable {
    case profile, fitnessGoal, goals, theme
    case health, notifications, measurement, backup
    case colors, widgets, controls
    case about, watch, ring, tier, bonus, dayInsight

    var id: Self { self }

    var titleKey: String {
        switch self {
        case .goals:         return "settings.goals.edit"
        case .fitnessGoal:   return "settings.fitness.goal.edit"
        case .profile:       return "settings.section.physicaldata"
        case .theme:         return "settings.theme.title"
        case .colors:        return "settings.appearance.title"
        case .widgets:       return "settings.edit.widgets"
        case .controls:      return "settings.preference.controlStyle"
        case .health:        return "settings.preference.appleHealth"
        case .notifications: return "settings.preference.notifications"
        case .measurement:   return "settings.preference.measurementSystem"
        case .backup:        return "settings.backup.nav.title"
        case .about:         return "settings.about.link"
        case .watch:         return "settings.preference.appleWatch"
        case .ring:          return "settings.about.progressRing"
        case .tier:          return "settings.about.achievement"
        case .bonus:         return "settings.about.streakBonus"
        case .dayInsight:    return "settings.about.dayInsight"
        }
    }

    var symbol: String {
        switch self {
        case .goals:         return "target"
        case .fitnessGoal:   return "flame"
        case .profile:       return "person.circle"
        case .theme:         return "face.smiling"
        case .colors:        return "circle.lefthalf.filled"
        case .widgets:       return "square.on.square"
        case .controls:      return "slider.horizontal.3"
        case .health:        return "heart.fill"
        case .notifications: return "bell.badge"
        case .measurement:   return "ruler"
        case .backup:        return "externaldrive"
        case .about:         return "info.circle"
        case .watch:         return "applewatch"
        case .ring:          return "circle.dotted"
        case .tier:          return "trophy.fill"
        case .bonus:         return "calendar.badge.checkmark"
        case .dayInsight:    return "text.quote"
        }
    }

    /// Páginas feitas com List. As outras usam ScrollView, com largura máxima e padding próprios.
    /// No layout largo dos Ajustes só a List precisa de margens explícitas (ver SettingsView.body).
    var usesList: Bool {
        switch self {
        case .profile, .fitnessGoal, .colors, .widgets, .controls: return false
        default:                                                   return true
        }
    }

    var color: Color {
        switch self {
        case .goals:                  return .red
        case .fitnessGoal, .ring:     return .orange
        case .profile:                return .blue
        case .theme:                  return .purple
        case .colors, .health:        return .pink
        case .widgets:                return .indigo
        case .controls, .backup, .about: return .gray
        case .notifications:          return .red
        case .measurement:            return .teal
        case .watch, .bonus:          return .green
        case .dayInsight:             return .cyan
        case .tier:                   return .yellow
        }
    }
}

struct SettingsView: View {
    // Cor de destaque e tema, usados pra colorir ícones e passar ao TierInfoView.
    @AppStorage(AppAccentColor.storageKey) private var storedColorRaw: String = AppAccentColor.blue.rawValue
    @AppStorage(AppTheme.storageKey) private var selectedTheme: AppTheme = .gym
    @AppStorage(UserProfile.sexKey) private var sex: String = "male"

    // Usado pelo botão "Idioma" pra abrir Ajustes do iOS na página do Gym Nutshell.
    @Environment(\.openURL) private var openURL
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // Histórico de notificações, aberto pelo sino no canto superior direito (antes ficava na Hoje).
    @State private var showNotificationHistory = false

    /// Página aberta à direita no layout largo (como os Ajustes do iPad).
    @State private var widePage: SettingsPage = .profile

    private var accentColor: AppAccentColor {
        AppAccentColor(rawValue: storedColorRaw) ?? .blue
    }

    /// Mesma regra de layout largo da Hoje: iPad e iPhone Duo aberto (deitado ou em pé).
    private func isWide(_ width: CGFloat) -> Bool {
        width >= 700 || (horizontalSizeClass == .regular && width >= 560)
    }

    /// Largura máxima das páginas com ScrollView (frame de 600 com o padding padrão dos dois lados).
    private static let pageMaxWidth: CGFloat = 600

    /// Margem lateral das páginas com List no layout largo: a mesma das páginas com ScrollView, ou seja, no
    /// mínimo a padrão e, com espaço sobrando, cartões na mesma largura máxima, centralizados.
    private static func listPageMargin(paneWidth: CGFloat) -> CGFloat {
        max(AppStyle.horizontalPadding, (paneWidth - pageMaxWidth) / 2 + AppStyle.horizontalPadding)
    }

    var body: some View {
        GeometryReader { geo in
            if isWide(geo.size.width) {
                // Lista à esquerda e a página escolhida à direita. As páginas que empilham outras (ex.: Metas →
                // detalhe) empilham no stack raiz, em tela cheia.
                let listWidth: CGFloat = geo.size.width < 744 ? 300 : 340
                let listMargin = Self.listPageMargin(paneWidth: geo.size.width - listWidth - 1)
                HStack(spacing: 0) {
                    settingsList(wide: true)
                        .frame(width: listWidth)
                        // Encostada na divisória, a List fica sem margem desse lado: margem explícita nos dois.
                        .contentMargins(.leading, AppStyle.horizontalPadding + geo.safeAreaInsets.leading,
                                        for: .scrollContent)
                        .contentMargins(.trailing, AppStyle.horizontalPadding, for: .scrollContent)
                    Divider()
                        .ignoresSafeArea()
                    destination(for: widePage)
                        .id(widePage)
                        // Páginas com List: mesmas margens e largura máxima das com ScrollView, centralizadas.
                        // A margem da List conta da borda da tela, por isso soma a área segura da direita
                        // (a barra lateral do iPhone Duo aberto). nil deixa a margem automática das outras.
                        .contentMargins(.leading, widePage.usesList ? listMargin : nil, for: .scrollContent)
                        .contentMargins(.trailing, widePage.usesList ? listMargin + geo.safeAreaInsets.trailing : nil,
                                        for: .scrollContent)
                        .frame(maxWidth: .infinity)
                }
            } else {
                // Lista simples empurrada no stack raiz.
                settingsList(wide: false)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(String(localized: "settings.header.title", bundle: .gymNutshellCore))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showNotificationHistory = true
                } label: {
                    Image(systemName: "bell")
                }
                .accessibilityLabel(String(localized: "a11y.notification.history.bell", bundle: .gymNutshellCore))
                .accessibilityHint(String(localized: "a11y.notification.history.bell.hint", bundle: .gymNutshellCore))
            }
        }
        .sheet(isPresented: $showNotificationHistory) {
            NotificationHistorySheet()
        }
    }

    // MARK: - Lista

    private func settingsList(wide: Bool) -> some View {
        List {
            // No layout largo a barra mostra o título da página da direita; o "Ajustes" fica no topo da lista.
            if wide {
                Text(String(localized: "settings.header.title", bundle: .gymNutshellCore))
                    .font(.largeTitle.bold())
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                    .accessibilityAddTraits(.isHeader)
            }

            // Seção Perfil: seus dados, objetivo fitness, metas e emoji.
            section("settings.section.edit", pages: [.profile, .fitnessGoal, .goals, .theme], wide: wide)

            // Seção Sistema, integrações de plataforma, notificações, medidas e backup.
            Section(header: sectionHeader("settings.section.system")) {
                ForEach([SettingsPage.health, .notifications, .measurement, .backup]) { row($0, wide: wide) }

                // Idioma, abre Ajustes do iOS na página do Gym Nutshell (onde aparece
                // o seletor "Idioma preferido" gerado automaticamente pelo sistema).
                Button {
                    if let url = NotificationManager.systemSettingsURL {
                        openURL(url)
                    }
                } label: {
                    HStack {
                        Label { Text(String(localized: "settings.preference.language", bundle: .gymNutshellCore)) } icon: { GlassIcon(systemName: "globe", color: .blue) }
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.forward.app")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tertiary)
                            // Ícone de "abre fora" é decorativo, o Button já diz "Language".
                            .accessibilityHidden(true)
                    }
                }
                .foregroundStyle(.primary)
            }

            // Seção Visual: aparência (modo claro/escuro e cor de destaque), widgets e estilo dos controles.
            section("settings.section.visual", pages: [.colors, .widgets, .controls], wide: wide)

            // Seção Sobre: a página do Gym Nutshell (que abre os detalhes da conquista, do bônus, do anel e
            // da frase do dia) e o Apple Watch.
            section("settings.section.about", pages: [.about, .watch], wide: wide)
        }
    }

    private func sectionHeader(_ key: String) -> some View {
        Text(String(localized: String.LocalizationValue(key), bundle: .gymNutshellCore))
            .foregroundStyle(accentColor.color)
    }

    private func section(_ headerKey: String, pages: [SettingsPage], wide: Bool) -> some View {
        Section(header: sectionHeader(headerKey)) {
            ForEach(pages) { row($0, wide: wide) }
        }
    }

    private func rowLabel(_ page: SettingsPage) -> some View {
        Label { Text(String(localized: String.LocalizationValue(page.titleKey), bundle: .gymNutshellCore)) } icon: { GlassIcon(systemName: page.symbol, color: page.color) }
            .foregroundStyle(.primary)
    }

    /// No iPhone empurra a página; no layout largo só troca a página da direita e marca a linha.
    @ViewBuilder
    private func row(_ page: SettingsPage, wide: Bool) -> some View {
        if wide {
            let isSelected = widePage == page
            Button {
                widePage = page
            } label: {
                rowLabel(page)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .listRowBackground(isSelected ? accentColor.color.opacity(0.18) : Color(.secondarySystemGroupedBackground))
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        } else {
            NavigationLink {
                destination(for: page)
            } label: {
                rowLabel(page)
            }
        }
    }

    @ViewBuilder
    private func destination(for page: SettingsPage) -> some View {
        switch page {
        case .goals:         TrackingGoalsSettingsView()
        case .fitnessGoal:   UserGoalChangeView()
        case .profile:       ProfileSettingsView()
        case .theme:         ThemeSettingsView()
        case .colors:        ColorSettingsView()
        case .widgets:       WidgetBackgroundSettingsView()
        case .controls:      ControlStyleSettingsView()
        case .health:        HealthSettingsView()
        case .notifications: NotificationsSettingsView()
        case .measurement:   MeasurementSettingsView()
        case .backup:        BackupSettingsView()
        case .about:         AboutView()
        case .watch:         AppleWatchInstructionsView()
        case .ring:          ProgressRingInfoView()
        case .tier:          TierInfoView(theme: selectedTheme, sex: sex)
        case .bonus:         StreakBonusInfoView()
        case .dayInsight:    DayInsightInfoView()
        }
    }
}

// MARK: - Apple Watch instructions page

/// Página com passos manuais pra instalar o app no Apple Watch, usada porque
/// a Apple não expõe URL scheme público pra abrir o app companion Watch.
private struct AppleWatchInstructionsView: View {
    @AppStorage(AppAccentColor.storageKey) private var storedColorRaw: String = AppAccentColor.blue.rawValue
    private var accentColor: Color {
        (AppAccentColor(rawValue: storedColorRaw) ?? .blue).color
    }

    var body: some View {
        List {
            // Ícone do app, redondo, no padrão watchOS.
            Section {
                HStack {
                    Spacer()
                    appIcon
                    Spacer()
                }
                .padding(.top, 12)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 6, trailing: 16))
            }

            Section {
                Text(String(localized: "appleWatch.sheet.intro", bundle: .gymNutshellCore))
                    .font(.body)
            }
            .listRowBackground(Color.clear)

            Section {
                step(number: 1, text: String(localized: "appleWatch.sheet.step1", bundle: .gymNutshellCore))
                step(number: 2, text: String(localized: "appleWatch.sheet.step2", bundle: .gymNutshellCore))
                step(number: 3, text: String(localized: "appleWatch.sheet.step3", bundle: .gymNutshellCore))
            } footer: {
                Text(String(localized: "appleWatch.sheet.note", bundle: .gymNutshellCore))
            }
        }
        .navigationTitle(String(localized: "appleWatch.sheet.title", bundle: .gymNutshellCore))
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Ícone do app clipado em círculo, espelha o estilo da face do app no watchOS.
    private var appIcon: some View {
        let size: CGFloat = 80
        return Image("AppleWatchIcon")
            .resizable()
            .interpolation(.high)
            .frame(width: size, height: size)
            .clipShape(Circle())
    }

    @ViewBuilder
    private func step(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.body.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(accentColor))
            Text(text)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}
