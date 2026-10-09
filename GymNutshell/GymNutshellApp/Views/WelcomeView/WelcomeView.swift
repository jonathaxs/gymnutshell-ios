// ⌘
//  GymNutshell/GymNutshellApp/Views/WelcomeView/WelcomeView.swift
//
//  Propósito: Onboarding em múltiplas etapas que coleta o perfil do usuário e calcula as metas diárias.
//             Dona do estado e faz a navegação entre as views de cada etapa.
//             Etapas: início → objetivo + sexo → metas → estilo de controle → tema → tudo pronto (permissões).
//
//  Created by Jonathas Motta (@jonathaxs) on 2025-11-24.
// ⌘

import SwiftUI
import GymNutshellCore
import SwiftData
import UniformTypeIdentifiers

/// Tela de onboarding multi-etapas mostrada só no primeiro lançamento.
/// Coleta objetivo fitness e sexo, depois define e persiste as metas diárias padrão do usuário.
///
/// Cada etapa fica no próprio arquivo dentro de Views/WelcomeView/.
struct WelcomeView: View {

    // MARK: - Callback de conclusão

    /// Chamado quando o usuário termina o onboarding pra o GymNutshellApp trocar pra MainView.
    let onComplete: () -> Void

    // Contexto de dados, necessário pra restauração de backup via painel esquerdo no modo wide.
    @Environment(\.modelContext) private var modelContext

    // MARK: - Controle de etapas
    // O enum WelcomeStep + textos de painel ficam em WelcomeStep.swift.

    @State private var currentStep: WelcomeStep

    // MARK: - Init

    init(onComplete: @escaping () -> Void) {
        _currentStep = State(initialValue: .start)
        self.onComplete = onComplete
    }

    // Controla a direção da navegação pra a animação de slide funcionar certo.
    @State private var isGoingForward: Bool = true

    // MARK: - Sistema de medidas

    // Detectado a partir do locale do device no início do onboarding.
    // O usuário pode mudar essa escolha depois em Settings.
    @State private var measurementSystem: MeasurementSystem = MeasurementSystemStore.detectDefault()

    // MARK: - Seleção de tema

    // O tema de mascote escolhido no onboarding. Padrão é Academia.
    // Persistido no final de finishOnboarding() pra todo o app atualizar imediatamente.
    @State private var onboardingTheme: AppTheme = .gym

    // MARK: - Campos em edição

    @State private var name: String = ""
    @State private var sex: String = "male"
    @State private var userGoal: UserGoal = .maintenance
    @State private var controlStyle: ControlStyle = .default

    // MARK: - Seleções de metas opcionais

    // Se o usuário escolheu incluir Good Fat no rastreio.
    @State private var includeFats: Bool = false
    // Se o usuário escolheu incluir a meta de check-in Creatina.
    @State private var includeCreatine: Bool = false

    // MARK: - Resultado calculado exibido na etapa de resumo

    @State private var calculatedGoals: GoalsCalculator.Result? = nil
    @State private var summaryScrolledToEnd = false

    // MARK: - Ações

    private func advance() {
        isGoingForward = true
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .start:
                currentStep = .goal
            case .goal:
                summaryScrolledToEnd = false
                calculatedGoals = GoalsCalculator.calculate(sex: sex, goal: userGoal)
                currentStep = .summary
            case .summary:
                currentStep = .controlStyle
            case .controlStyle:
                currentStep = .theme
            case .theme:
                currentStep = .ready
            case .ready:
                finishOnboarding()
            }
        }
    }

    private func goBack() {
        guard let prev = WelcomeStep(rawValue: currentStep.rawValue - 1) else { return }
        isGoingForward = false
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = prev
        }
    }

    private func finishOnboarding() {
        let defaults = UserDefaults.standard
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        // Persiste os dados do perfil.
        defaults.set(trimmedName,              forKey: UserProfile.nameKey)
        defaults.set(sex,                      forKey: UserProfile.sexKey)
        defaults.set(userGoal.rawValue,     forKey: UserProfile.userGoalKey)
        // Persiste o sistema de medidas escolhido no onboarding.
        defaults.set(measurementSystem.rawValue, forKey: UserProfile.measurementSystemKey)
        // Persiste o estilo de controle (slider ou − / +).
        defaults.set(controlStyle.rawValue, forKey: ControlStyle.storageKey)
        // Persiste o tema de mascote escolhido no onboarding.
        defaults.set(onboardingTheme.rawValue, forKey: AppTheme.storageKey)
        // Persiste a cor de destaque padrão baseada no sexo escolhido.
        // O usuário pode sobrescrever em Settings > Cores.
        defaults.set(AppAccentColor.defaultForSex(sex).rawValue, forKey: AppAccentColor.storageKey)

        // Persiste as metas calculadas pra o GoalsProvider pegar imediatamente.
        if let goals = calculatedGoals {
            GoalsProvider.save(goals)
        }

        // Marca metas opcionais de rastreio como removidas se o usuário não incluiu.
        if !includeFats  { RemovedItemsStore.remove("tracking.goodFat") }

        // Marca metas opcionais de suplementos como removidas se o usuário não incluiu.
        if !includeCreatine { RemovedItemsStore.remove("tracking.creatine") }

        // Agenda as notificações com as metas já salvas (só tem efeito se a permissão foi dada).
        NotificationManager.shared.rescheduleAllActive()

        // Marca o onboarding como concluído.
        defaults.set(true, forKey: UserProfile.didCompleteOnboardingKey)

        onComplete()
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            if geo.size.width >= 700 {
                // Landscape / iPad: painel contextual à esquerda, conteúdo da etapa à direita.
                HStack(spacing: 0) {
                    WelcomeContextPanel(
                        currentStep: currentStep,
                        sexColor: sexColor,
                        continueButtonColor: continueButtonColor,
                        continueButtonLabel: continueButtonLabel,
                        isCurrentStepValid: isCurrentStepValid,
                        onAdvance: advance,
                        onGoBack: goBack,
                        onRestoreComplete: onComplete,
                        modelContext: modelContext
                    )
                    .frame(width: 340)
                    Divider()
                    stepContent(isWide: true)
                        .frame(maxWidth: .infinity)
                }
            } else {
                // Portrait / iPhone: layout original com largura limitada.
                stepContent(isWide: false)
                    .frame(maxWidth: 600)
                    .frame(maxWidth: .infinity)
            }
        }
        .background { welcomeBackground }
    }

    // Fundo agrupado com um brilho suave da cor de destaque no topo.
    private var welcomeBackground: some View {
        ZStack(alignment: .top) {
            Color(.systemGroupedBackground)
            LinearGradient(
                colors: [sexColor.opacity(0.22), sexColor.opacity(0)],
                startPoint: .top,
                endPoint: .center
            )
        }
        .animation(.easeInOut(duration: 0.4), value: sex)
        .ignoresSafeArea()
    }

    // MARK: - Conteúdo da etapa (progress bar + step + botões opcionais)

    @ViewBuilder
    private func stepContent(isWide: Bool) -> some View {
        VStack(spacing: 0) {

            // Botão de voltar e barra de progresso no topo.
            HStack(spacing: 14) {
                // Botão de voltar redondo de vidro, escondido na primeira etapa e no modo wide
                // (no wide os botões ficam no painel).
                if currentStep != .start && !isWide {
                    Button(action: goBack) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .frame(width: 24, height: 24)
                    }
                    .appCircleButton(fallbackPadding: 8)
                    .accessibilityLabel(String(localized: "a11y.welcome.back.button",
                                               bundle: .gymNutshellCore))
                    .transition(.scale.combined(with: .opacity))
                }

                WelcomeProgressBar(currentStep: currentStep, activeColor: sexColor)
            }
            .frame(minHeight: 44)
            .padding(.horizontal, AppStyle.horizontalPadding)
            .padding(.top, 12)

            // Conteúdo da etapa com transição de slide.
            Group {
                switch currentStep {
                case .start:
                    WelcomeStartStep(
                        onRestore: onComplete,
                        onNewProfile: advance,
                        accentColor: sexColor,
                        isWide: isWide
                    )
                case .goal:
                    WelcomeUserGoalStep(userGoal: $userGoal, sex: $sex, accentColor: sexColor, isWide: isWide)
                case .summary:
                    WelcomeSummaryStep(
                        goals: $calculatedGoals,
                        measurementSystem: measurementSystem,
                        userGoal: userGoal,
                        accentColor: sexColor,
                        includeFats: $includeFats,
                        includeCreatine: $includeCreatine,
                        scrolledToEnd: $summaryScrolledToEnd,
                        isWide: isWide
                    )
                case .controlStyle:
                    WelcomeControlStyleStep(selection: $controlStyle, accentColor: sexColor, isWide: isWide)
                case .ready:
                    WelcomeReadyStep(accentColor: sexColor, isWide: isWide)
                case .theme:
                    WelcomeThemeStep(selectedTheme: $onboardingTheme, sex: sex, accentColor: sexColor, isWide: isWide)
                }
            }
            .frame(maxHeight: .infinity)
            // Esmaece o conteúdo nas bordas, em vez de cortar seco no topo e acima do botão.
            .mask {
                VStack(spacing: 0) {
                    LinearGradient(colors: [.black.opacity(0), .black], startPoint: .top, endPoint: .bottom)
                        .frame(height: 16)
                    Color.black
                    LinearGradient(colors: [.black, .black.opacity(0)], startPoint: .top, endPoint: .bottom)
                        .frame(height: 28)
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: isGoingForward ? .trailing : .leading),
                removal: .move(edge: isGoingForward ? .leading : .trailing)
            ))
            .animation(.easeInOut(duration: 0.3), value: currentStep)

            // Botão de rodapé, só no modo narrow e fora da etapa inicial.
            // O voltar fica no botão redondo do topo.
            if currentStep != .start && !isWide {
                WelcomeContinueButton(
                    label: continueButtonLabel,
                    color: continueButtonColor,
                    isEnabled: isCurrentStepValid,
                    action: advance
                )
                .padding(.horizontal, AppStyle.horizontalPadding)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
        }
        // O VStack externo ignora a safe area do teclado: os botões ficam fixos na base,
        // o ScrollView interno de cada etapa ajusta seu contentInset pra mostrar os campos.
        .ignoresSafeArea(.keyboard)
    }

    // MARK: - Cores dinâmicas

    // Cor de destaque baseada no sexo selecionado.
    // Delega pra AppAccentColor.defaultForSex pra manter uma única fonte da verdade.
    private var sexColor: Color {
        AppAccentColor.defaultForSex(sex).color
    }

    // Cor do botão Continuar: segue o objetivo na etapa de goal, e o sexo nas demais.
    private var continueButtonColor: Color {
        switch currentStep {
        case .goal:
            switch userGoal {
            case .bulking:     return .orange
            case .maintenance: return Color.accentColor
            case .cutting:     return .green
            }
        case .summary, .controlStyle, .theme, .ready:
            return sexColor
        default:
            return Color.accentColor
        }
    }

    // MARK: - Validação e label do continuar

    private var isCurrentStepValid: Bool {
        switch currentStep {
        case .start:        return true
        case .goal:         return true
        case .summary:      return summaryScrolledToEnd
        case .controlStyle: return true
        case .theme:        return true
        case .ready:        return true
        }
    }

    private var continueButtonLabel: String {
        currentStep == .ready
            ? String(localized: "welcome.button.start", bundle: .gymNutshellCore)
            : String(localized: "welcome.button.continue", bundle: .gymNutshellCore)
    }
}

#Preview {
    WelcomeView(onComplete: {})
}
