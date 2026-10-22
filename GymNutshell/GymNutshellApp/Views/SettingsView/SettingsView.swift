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
enum SettingsPage: Hashable, CaseIterable, Identifiable {
    case goals, fitnessGoal, profile
    case theme, colors, widgets, controls
    case health, notifications, measurement, backup
    case about, watch, ring, tier

    var id: Self { self }

    var titleKey: String {
        switch self {
        case .goals:         return "settings.goals.edit"
        case .fitnessGoal:   return "settings.fitness.goal.edit"
        case .profile:       return "settings.section.physicaldata"
        case .theme:         return "settings.theme.title"
        case .colors:        return "settings.color.title"
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
        }
    }

    var symbol: String {
        switch self {
        case .goals:         return "target"
        case .fitnessGoal:   return "flame"
        case .profile:       return "person.circle"
        case .theme:         return "face.smiling"
        case .colors:        return "paintpalette"
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
        case .watch:                  return .green
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
    @State private var widePage: SettingsPage = .goals

    private var accentColor: AppAccentColor {
        AppAccentColor(rawValue: storedColorRaw) ?? .blue
    }

    /// Mesma regra de layout largo da Hoje: iPad e iPhone Duo aberto (deitado ou em pé).
    private func isWide(_ width: CGFloat) -> Bool {
        width >= 700 || (horizontalSizeClass == .regular && width >= 560)
    }

    var body: some View {
        GeometryReader { geo in
            if isWide(geo.size.width) {
                // Lista à esquerda e a página escolhida à direita. As páginas que empilham outras (ex.: Metas →
                // detalhe) empilham no stack raiz, em tela cheia.
                HStack(spacing: 0) {
                    settingsList(wide: true)
                        .frame(width: geo.size.width < 744 ? 300 : 340)
                    Divider()
                        .ignoresSafeArea()
                    destination(for: widePage)
                        .id(widePage)
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

            // Seção Seus dados, metas, objetivo fitness e perfil do usuário.
            section("settings.section.edit", pages: [.goals, .fitnessGoal, .profile], wide: wide)

            // Seção Aparência, tema, cores de destaque, widgets e estilo dos controles.
            section("settings.section.preferences", pages: [.theme, .colors, .widgets, .controls], wide: wide)

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

            // Seção Sobre, conquista, anel de progresso e info de versão.
            section("settings.section.about", pages: [.about, .watch, .ring, .tier], wide: wide)
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
