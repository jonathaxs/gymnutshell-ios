// ⌘
//  GymNutshell/GymNutshellApp/Views/WelcomeView/WelcomeView.swift
//
//  Propósito: Onboarding em múltiplas etapas que coleta o perfil do usuário e calcula as metas diárias.
//             Dona do estado e faz a navegação entre as views de cada etapa.
//             Etapas: início → sobre você (sexo + exercício favorito) → objetivo → medidas (só EUA) → metas → estilo de controle → tema → tudo pronto (permissões).
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

    // A etapa de medidas só aparece em aparelhos no sistema americano.
    private let showsUnitsStep = MeasurementSystemStore.needsChoice
    private var visibleSteps: [WelcomeStep] { WelcomeStep.visible(includeUnits: showsUnitsStep) }

    // MARK: - Seleção de tema

    // O tema de mascote escolhido no onboarding. Padrão é Academia.
    // Persistido no final de finishOnboarding() pra todo o app atualizar imediatamente.
    @State private var onboardingTheme: AppTheme = .gym

    // MARK: - Campos em edição

    @State private var name: String = ""
    @State private var sex: String = "male"
    @State private var favoriteExercise: FavoriteExercise = .unknown
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

    // MARK: - Botões do rodapé (narrow)

    @State private var showRestoreOptions = false
    @State private var restoreRequest: WelcomeRestoreSource? = nil
    // Onde ficam os botões do rodapé e o espaço que as etapas Início e Tudo pronto reservam pra eles.
    @State private var footerFrame: CGRect? = nil
    @State private var slotFrames: [WelcomeStep: CGRect] = [:]
    @State private var buttonsHeight: CGFloat = 112
    // A primeira posição (Início, ao abrir) entra sem animação.
    @State private var didPlaceButtons = false

    // MARK: - Ações

    private func advance() {
        isGoingForward = true
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .start:
                currentStep = .about
            case .about:
                currentStep = .goal
            case .goal:
                summaryScrolledToEnd = false
                calculatedGoals = GoalsCalculator.calculate(sex: sex, goal: userGoal)
                currentStep = showsUnitsStep ? .units : .summary
            case .units:
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
        guard let index = visibleSteps.firstIndex(of: currentStep), index > 0 else { return }
        let prev = visibleSteps[index - 1]
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
        defaults.set(favoriteExercise.rawValue, forKey: UserProfile.favoriteExerciseKey)
        defaults.set(userGoal.rawValue,     forKey: UserProfile.userGoalKey)
        // Persiste o sistema de medidas escolhido no onboarding.
        defaults.set(measurementSystem.rawValue, forKey: UserProfile.measurementSystemKey)
        // Persiste o estilo de controle (slider ou − / +).
        defaults.set(controlStyle.rawValue, forKey: ControlStyle.storageKey)
        // Persiste o tema de mascote escolhido no onboarding.
        defaults.set(onboardingTheme.rawValue, forKey: AppTheme.storageKey)
        // Persiste a cor de destaque padrão baseada no sexo escolhido.
        // O usuário pode sobrescrever em Settings > Cores de destaque.
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
        defaults.set(true, forKey: UserProfile.pendingRingCelebrationKey)
        defaults.set(true, forKey: UserProfile.pendingGoalsEntranceKey)
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
                        restoreRequest: $restoreRequest
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

    // Fundo agrupado com um brilho suave da cor da etapa no topo (sexo, ou objetivo na etapa de objetivo).
    private var welcomeBackground: some View {
        ZStack(alignment: .top) {
            Color(.systemGroupedBackground)
            LinearGradient(
                colors: [stepColor.opacity(0.22), stepColor.opacity(0)],
                startPoint: .top,
                endPoint: .center
            )
        }
        .animation(.easeInOut(duration: 0.4), value: stepColor)
        .ignoresSafeArea()
    }

    // MARK: - Conteúdo da etapa (progress bar + step + botões opcionais)

    @ViewBuilder
    private func stepContent(isWide: Bool) -> some View {
        VStack(spacing: 0) {

            // Barra de progresso no topo. O voltar fica no rodapé, abaixo do Continuar.
            WelcomeProgressBar(currentStep: currentStep, activeColor: stepColor, steps: visibleSteps)
                .frame(minHeight: 44)
            .padding(.horizontal, AppStyle.horizontalPadding)
            .padding(.top, 12)

            // Conteúdo da etapa com transição de slide.
            Group {
                switch currentStep {
                case .start:
                    WelcomeStartStep(
                        onRestore: onComplete,
                        restoreRequest: $restoreRequest,
                        accentColor: sexColor,
                        isWide: isWide
                    )
                case .about:
                    WelcomeAboutStep(sex: $sex, favoriteExercise: $favoriteExercise, accentColor: sexColor, isWide: isWide)
                case .goal:
                    WelcomeUserGoalStep(userGoal: $userGoal, accentColor: stepColor, isWide: isWide)
                case .units:
                    WelcomeUnitsStep(selection: $measurementSystem, accentColor: sexColor, isWide: isWide)
                case .summary:
                    WelcomeSummaryStep(
                        goals: $calculatedGoals,
                        measurementSystem: measurementSystem,
                        accentColor: stepColor,
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
            .environment(\.welcomeButtonsHeight, buttonsHeight)
            .environment(\.welcomeButtonsSlotReporter, WelcomeButtonsSlotReporter(report: reportSlot))

            // Botões de rodapé, só no modo narrow: Continuar e, abaixo, Voltar.
            if !isWide {
                footerButtons
            }
        }
        // O VStack externo ignora a safe area do teclado: os botões ficam fixos na base,
        // o ScrollView interno de cada etapa ajusta seu contentInset pra mostrar os campos.
        .ignoresSafeArea(.keyboard)
        // Arrastar da borda esquerda pra direita volta uma etapa, como no padrão do iOS.
        .overlay(alignment: .leading) {
            if currentStep != .start && !isWide {
                backSwipeEdge
            }
        }
    }

    // MARK: - Botões do rodapé

    /// Um só par de botões pra todas as etapas. No Início eles ficam logo abaixo do "Olá", mais estreitos,
    /// como Começar / Restaurar backup e, ao avançar, descem pro rodapé se alargando e viram Continuar / Voltar.
    /// No Tudo pronto sobem pra logo abaixo das permissões (o caminho inverso).
    private var footerButtons: some View {
        VStack(spacing: 10) {
            WelcomeContinueButton(
                label: continueButtonLabel,
                color: continueButtonColor,
                isEnabled: isCurrentStepValid,
                action: advance
            )

            Button {
                if currentStep == .start { showRestoreOptions = true } else { goBack() }
            } label: {
                Text(currentStep == .start
                     ? String(localized: "welcome.start.restore", bundle: .gymNutshellCore)
                     : String(localized: "welcome.button.back", bundle: .gymNutshellCore))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .appSecondaryButton(continueButtonColor)
            // Restaurar backup abre um balão logo abaixo, como o Detalhes dos emojis.
            .downwardPopover(isPresented: $showRestoreOptions) {
                WelcomeRestorePopover(accentColor: continueButtonColor) { source in
                    showRestoreOptions = false
                    restoreRequest = source
                }
            }
        }
        // No Início ficam mais estreitos, na proporção do "Olá!"; ao descer pro rodapé se alargam.
        .frame(maxWidth: currentStep == .start ? 260 : .infinity)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { buttonsHeight = $0 }
        .offset(y: buttonsOffset)
        // Até saber onde fica o espaço do Início, os botões não aparecem (evita o pulo ao abrir).
        .opacity(didPlaceButtons ? 1 : 0)
        .padding(.horizontal, AppStyle.horizontalPadding)
        .padding(.top, 8)
        .padding(.bottom, 16)
        // Medido fora do offset: é a posição de repouso no rodapé.
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { footerFrame = $0 }
    }

    /// Quanto os botões sobem do rodapé até o espaço reservado pela etapa (0 = no rodapé).
    private var buttonsOffset: CGFloat {
        guard let footerFrame, let slot = slotFrames[currentStep] else { return 0 }
        // O VStack dos botões começa 8pt abaixo do topo do rodapé (padding de cima).
        return slot.minY - (footerFrame.minY + 8)
    }

    /// Recebe a posição do espaço reservado por uma etapa. Só vale a da etapa atual,
    /// pra a etapa que sai deslizando não puxar os botões junto.
    private func reportSlot(_ step: WelcomeStep, _ frame: CGRect) {
        guard step == currentStep else { return }
        if didPlaceButtons {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) { slotFrames[step] = frame }
        } else {
            slotFrames[step] = frame
            DispatchQueue.main.async { didPlaceButtons = true }
        }
    }

    /// Faixa fina na borda esquerda que reconhece o gesto de voltar. Fica só na borda pra não
    /// disputar o arraste com as listas e os controles de cada etapa.
    private var backSwipeEdge: some View {
        Color.clear
            .frame(width: 20)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onEnded { value in
                        let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                        if isHorizontal && (value.translation.width > 60 || value.predictedEndTranslation.width > 140) {
                            goBack()
                        }
                    }
            )
            // O VoiceOver já tem o botão Voltar no rodapé.
            .accessibilityHidden(true)
    }

    // MARK: - Cores dinâmicas

    // Cor de destaque baseada no sexo selecionado.
    // Delega pra AppAccentColor.defaultForSex pra manter uma única fonte da verdade.
    private var sexColor: Color {
        AppAccentColor.defaultForSex(sex).color
    }

    // Cor da etapa: segue o objetivo escolhido nas etapas de objetivo e de metas e o sexo nas demais.
    // Pinta o fundo, a barra de progresso e os botões do rodapé.
    private var stepColor: Color {
        guard currentStep == .goal || currentStep == .summary else { return sexColor }
        switch userGoal {
        case .bulking:     return .orange
        case .maintenance: return .cyan
        case .cutting:     return .green
        }
    }

    private var continueButtonColor: Color { stepColor }

    // MARK: - Validação e label do continuar

    private var isCurrentStepValid: Bool {
        switch currentStep {
        case .start:        return true
        case .about:        return true
        case .goal:         return true
        case .units:        return true
        case .summary:      return summaryScrolledToEnd
        case .controlStyle: return true
        case .theme:        return true
        case .ready:        return true
        }
    }

    private var continueButtonLabel: String {
        switch currentStep {
        case .start: return String(localized: "welcome.start.new", bundle: .gymNutshellCore)
        case .ready: return String(localized: "welcome.button.start", bundle: .gymNutshellCore)
        default:     return String(localized: "welcome.button.continue", bundle: .gymNutshellCore)
        }
    }
}

// MARK: - Espaço reservado pros botões

extension EnvironmentValues {
    /// Altura do par de botões do rodapé, pra a etapa reservar o mesmo espaço.
    @Entry var welcomeButtonsHeight: CGFloat = 112
    /// Avisa a WelcomeView onde a etapa reservou o espaço dos botões.
    @Entry var welcomeButtonsSlotReporter = WelcomeButtonsSlotReporter()
}

/// Closure embrulhada num Equatable que nunca muda, pra o environment não invalidar a cada update.
struct WelcomeButtonsSlotReporter: Equatable {
    var report: (WelcomeStep, CGRect) -> Void = { _, _ in }
    static func == (lhs: Self, rhs: Self) -> Bool { true }
}

/// Espaço vazio do tamanho dos botões. Os botões de verdade ficam no rodapé da WelcomeView
/// e deslizam até aqui (Início e Tudo pronto).
struct WelcomeButtonsSlot: View {

    let step: WelcomeStep

    @Environment(\.welcomeButtonsHeight) private var height
    @Environment(\.welcomeButtonsSlotReporter) private var reporter

    var body: some View {
        Color.clear
            .frame(height: height)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { reporter.report(step, $0) }
            .accessibilityHidden(true)
    }
}

#Preview {
    WelcomeView(onComplete: {})
}
