// ⌘
//  GymNutshell/GymNutshellApp/Views/WelcomeView/WelcomeView.swift
//
//  Propósito: Onboarding em múltiplas etapas que coleta o perfil do usuário e calcula as metas diárias.
//             Dona do estado e faz a navegação entre as views de cada etapa.
//             Etapas: início → objetivo + sexo → resumo (metas) → tema.
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
                currentStep = .theme
            case .theme:
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
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    // MARK: - Conteúdo da etapa (progress bar + step + botões opcionais)

    @ViewBuilder
    private func stepContent(isWide: Bool) -> some View {
        VStack(spacing: 0) {

            // Botão de voltar e barra de progresso no topo.
            HStack(spacing: 12) {
                // Botão de voltar, escondido na primeira etapa e no modo wide (botões ficam no painel).
                if currentStep != .start && !isWide {
                    Button(action: goBack) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "a11y.welcome.back.button",
                                               bundle: .gymNutshellCore))
                }

                WelcomeProgressBar(currentStep: currentStep, activeColor: sexColor)
            }
            .padding(.horizontal)
            .padding(.top, 20)

            // Conteúdo da etapa com transição de slide.
            Group {
                switch currentStep {
                case .start:
                    WelcomeStartStep(
                        onRestore: onComplete,
                        onNewProfile: advance,
                        isWide: isWide
                    )
                case .goal:
                    WelcomeUserGoalStep(userGoal: $userGoal, sex: $sex, isWide: isWide)
                case .summary:
                    WelcomeSummaryStep(
                        goals: calculatedGoals,
                        measurementSystem: measurementSystem,
                        userGoal: userGoal,
                        accentColor: sexColor,
                        includeFats: $includeFats,
                        includeCreatine: $includeCreatine,
                        scrolledToEnd: $summaryScrolledToEnd,
                        isWide: isWide
                    )
                case .theme:
                    WelcomeThemeStep(selectedTheme: $onboardingTheme, sex: sex, accentColor: sexColor, isWide: isWide)
                }
            }
            .frame(maxHeight: .infinity)
            .transition(.asymmetric(
                insertion: .move(edge: isGoingForward ? .trailing : .leading),
                removal: .move(edge: isGoingForward ? .leading : .trailing)
            ))
            .animation(.easeInOut(duration: 0.3), value: currentStep)

            // Botões de rodapé, só no modo narrow e fora da etapa inicial.
            if currentStep != .start && !isWide {
                VStack(spacing: 8) {
                    WelcomeContinueButton(
                        label: continueButtonLabel,
                        color: continueButtonColor,
                        isEnabled: isCurrentStepValid,
                        action: advance
                    )

                    Button(action: goBack) {
                        Text(String(localized: "welcome.button.back", bundle: .gymNutshellCore))
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
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
        case .summary, .theme:
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
        case .theme:        return true
        }
    }

    private var continueButtonLabel: String {
        currentStep == .theme
            ? String(localized: "welcome.button.start", bundle: .gymNutshellCore)
            : String(localized: "welcome.button.continue", bundle: .gymNutshellCore)
    }
}

#Preview {
    WelcomeView(onComplete: {})
}
