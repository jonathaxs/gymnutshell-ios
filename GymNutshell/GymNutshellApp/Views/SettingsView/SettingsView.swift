// ⌘
//  GymNutshell/GymNutshellApp/Views/SettingsView/SettingsView.swift
//
//  Propósito: Página de Ajustes (empurrada no stack raiz). Contém links pra edição de perfil,
//             gerenciamento de metas e preferências do app. Mostra as infos de versão como rodapé.
//
//  Created by Jonathas Motta (@jonathaxs) on 2025-11-24.
// ⌘

import SwiftUI
import GymNutshellCore

struct SettingsView: View {
    // Cor de destaque e tema, usados pra colorir ícones e passar ao TierInfoView.
    @AppStorage(AppAccentColor.storageKey) private var storedColorRaw: String = AppAccentColor.blue.rawValue
    @AppStorage(AppTheme.storageKey) private var selectedTheme: AppTheme = .gym
    @AppStorage(UserProfile.sexKey) private var sex: String = "male"

    // Usado pelo botão "Idioma" pra abrir Ajustes do iOS na página do Gym Nutshell.
    @Environment(\.openURL) private var openURL

    // Histórico de notificações, aberto pelo sino no canto superior direito (antes ficava na Hoje).
    @State private var showNotificationHistory = false

    private var accentColor: AppAccentColor {
        AppAccentColor(rawValue: storedColorRaw) ?? .blue
    }

    var body: some View {
        // Lista simples empurrada no stack raiz; no iPad fica centralizada com largura máxima.
        List {
            // Seção Seus dados, metas, objetivo fitness e perfil do usuário.
            Section(header: Text(String(localized: "settings.section.edit", bundle: .gymNutshellCore)).foregroundStyle(accentColor.color)) {
                NavigationLink {
                    TrackingGoalsSettingsView()
                } label: {
                    Label { Text(String(localized: "settings.goals.edit", bundle: .gymNutshellCore)) } icon: { GlassIcon(systemName: "target", color: .red) }
                        .foregroundStyle(.primary)
                }
                NavigationLink {
                    UserGoalChangeView()
                } label: {
                    Label { Text(String(localized: "settings.fitness.goal.edit", bundle: .gymNutshellCore)) } icon: { GlassIcon(systemName: "flame", color: .orange) }
                        .foregroundStyle(.primary)
                }
                NavigationLink {
                    ProfileSettingsView()
                } label: {
                    Label { Text(String(localized: "settings.section.physicaldata", bundle: .gymNutshellCore)) } icon: { GlassIcon(systemName: "person.circle", color: .blue) }
                        .foregroundStyle(.primary)
                }
            }

            // Seção Aparência, tema, cores de destaque, widgets e estilo dos controles.
            Section(header: Text(String(localized: "settings.section.preferences", bundle: .gymNutshellCore)).foregroundStyle(accentColor.color)) {
                // Tema, controla os emojis de mascote e nomes de nível em todo o app.
                NavigationLink {
                    ThemeSettingsView()
                } label: {
                    Label { Text(String(localized: "settings.theme.title", bundle: .gymNutshellCore)) } icon: { GlassIcon(systemName: "face.smiling", color: .purple) }
                        .foregroundStyle(.primary)
                }
                // Cores de destaque, cor do app independente do sexo.
                NavigationLink {
                    ColorSettingsView()
                } label: {
                    Label { Text(String(localized: "settings.color.title", bundle: .gymNutshellCore)) } icon: { GlassIcon(systemName: "paintpalette", color: .pink) }
                        .foregroundStyle(.primary)
                }
                // Widgets, fundo personalizado pros widgets da tela inicial.
                NavigationLink {
                    WidgetBackgroundSettingsView()
                } label: {
                    Label { Text(String(localized: "settings.edit.widgets", bundle: .gymNutshellCore)) } icon: { GlassIcon(systemName: "square.on.square", color: .indigo) }
                        .foregroundStyle(.primary)
                }

                // Estilo dos controles de registro (slider ou − / +).
                NavigationLink {
                    ControlStyleSettingsView()
                } label: {
                    Label { Text(String(localized: "settings.preference.controlStyle", bundle: .gymNutshellCore)) } icon: { GlassIcon(systemName: "slider.horizontal.3", color: .gray) }
                        .foregroundStyle(.primary)
                }
            }

            // Seção Sistema, integrações de plataforma, notificações, medidas e backup.
            Section(header: Text(String(localized: "settings.section.system", bundle: .gymNutshellCore)).foregroundStyle(accentColor.color)) {
                // Apple Health, abre uma página dedicada pra sincronização de sono e auto check-in.
                NavigationLink {
                    HealthSettingsView()
                } label: {
                    Label { Text(String(localized: "settings.preference.appleHealth", bundle: .gymNutshellCore)) } icon: { GlassIcon(systemName: "heart.fill", color: .pink) }
                        .foregroundStyle(.primary)
                }

                // Notificações, configuração completa das notificações locais do app.
                NavigationLink {
                    NotificationsSettingsView()
                } label: {
                    Label { Text(String(localized: "settings.preference.notifications", bundle: .gymNutshellCore)) } icon: { GlassIcon(systemName: "bell.badge", color: .red) }
                        .foregroundStyle(.primary)
                }

                // Sistema de medidas, abre uma página de seleção dedicada.
                NavigationLink {
                    MeasurementSettingsView()
                } label: {
                    Label { Text(String(localized: "settings.preference.measurementSystem", bundle: .gymNutshellCore)) } icon: { GlassIcon(systemName: "ruler", color: .teal) }
                        .foregroundStyle(.primary)
                }

                // Backup, exportação/importação via iCloud e local.
                NavigationLink {
                    BackupSettingsView()
                } label: {
                    Label { Text(String(localized: "settings.backup.nav.title", bundle: .gymNutshellCore)) } icon: { GlassIcon(systemName: "externaldrive", color: .gray) }
                        .foregroundStyle(.primary)
                }

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
            Section(header: Text(String(localized: "settings.section.about", bundle: .gymNutshellCore)).foregroundStyle(accentColor.color)) {
                NavigationLink {
                    AboutView()
                } label: {
                    Label { Text(String(localized: "settings.about.link", bundle: .gymNutshellCore)) } icon: { GlassIcon(systemName: "info.circle", color: .gray) }
                        .foregroundStyle(.primary)
                }
                NavigationLink {
                    AppleWatchInstructionsView()
                } label: {
                    Label { Text(String(localized: "settings.preference.appleWatch", bundle: .gymNutshellCore)) } icon: { GlassIcon(systemName: "applewatch", color: .green) }
                        .foregroundStyle(.primary)
                }
                NavigationLink {
                    ProgressRingInfoView()
                } label: {
                    Label { Text(String(localized: "settings.about.progressRing", bundle: .gymNutshellCore)) } icon: { GlassIcon(systemName: "circle.dotted", color: .orange) }
                        .foregroundStyle(.primary)
                }
                NavigationLink {
                    TierInfoView(theme: selectedTheme, sex: sex)
                } label: {
                    Label { Text(String(localized: "settings.about.achievement", bundle: .gymNutshellCore)) } icon: { GlassIcon(systemName: "trophy.fill", color: .yellow) }
                        .foregroundStyle(.primary)
                }
            }

        }
        .frame(maxWidth: 700)
        .frame(maxWidth: .infinity)
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
