// ⌘
//  GymNutshellCore/Services/WatchConnectivityManager.swift
//
//  Propósito: Sincronização bidirecional iPhone ↔ Apple Watch via WatchConnectivity.
//             - iPhone → Watch: snapshot completo via applicationContext
//                                (preferências + ingestões do dia).
//             - Watch → iPhone: delta de uma única ingestão via transferUserInfo
//                                (FIFO, persistente, entregue mesmo se app fechado).
//
//  Estratégia:
//    * `applicationContext`: só guarda o último snapshot. Se mandar 5x seguidas,
//       só o último chega, perfeito pra dizer "esse é o estado atual".
//    * `transferUserInfo`: queue persistente. Se Watch tá sem rede, fica esperando.
//
//  Ambos os lados aplicam os recebidos no UserDefaults. As views com @AppStorage
//  reagem automaticamente, sem código extra de invalidação.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-04-26.
// ⌘

#if canImport(WatchConnectivity)

import Foundation
import WatchConnectivity

// MARK: - WatchConnectivityManager

public final class WatchConnectivityManager: NSObject, @unchecked Sendable {

    public static let shared = WatchConnectivityManager()

    /// Chaves de ingestão diária, sincronizadas em ambas as direções.
    private static let intakeKeys: [String] = [
        "workoutIntake", "cardioIntake", "sleepHours", "waterIntake",
        "proteinIntake", "carbIntake", "goodFatIntake",
        "fiberIntake", "creatineIntake"
    ]

    /// Chaves de preferência, sincronizadas só do iPhone pro Watch
    /// (Watch não muda essas configurações).
    private static let preferenceKeys: [String] = [
        // Aparência e perfil
        AppTheme.storageKey,
        UserProfile.sexKey,
        AppAccentColor.storageKey,

        // Idioma, o iPhone escreve essa chave em sendSnapshot() antes de ler preferenceKeys.
        // O Watch aplica no init() antes do SwiftUI inicializar, garantindo o idioma correto.
        "app.preferredLanguage",

        // Ordem e visibilidade das metas (incluindo agrupamento por categoria)
        "tracking.fixedOrder",
        "app.removedBuiltinItems",
        "goal.category.order",
        "goal.category.unifiedOrder",

        // Toggles de "dia de descanso", sincronizam com o ON/OFF do Watch
        "workoutRestDay",
        "cardioRestDay",

        // Valores-alvo de cada meta, o Watch precisa pra mostrar `0/N`
        // com o N que o usuário configurou no iPhone.
        "tracking.workout",
        "tracking.cardio",
        "tracking.sleep",
        "tracking.water",
        "tracking.protein",
        "tracking.carbs",
        "tracking.goodFat",
        "tracking.fiber",
        "tracking.creatine"
    ]

    /// Última cópia de cada chave de ingestão que foi enviada/recebida.
    /// Usado pra detectar mudanças locais e evitar reenvio em loop quando
    /// um valor é aplicado a partir de um update remoto.
    private var lastKnownIntakes: [String: Int] = [:]

    /// Flag de supressão temporária do observer durante a aplicação de updates remotos.
    /// Sem isso, escrever no UserDefaults durante `applySnapshot` dispara o observer,
    /// que detecta a "mudança" e tenta mandar o snapshot de volta, ping-pong infinito.
    private var suppressObservation: Bool = false

    /// Assinatura textual do conjunto de preferências, usado pra detectar mudança
    /// em qualquer chave de preferência sem precisar comparar tipos heterogêneos.
    private var lastPrefsSignature: String = ""

    /// Snapshot dos dados de histórico de notificações, para detectar mudanças no iPhone
    /// e incluir o histórico atualizado no próximo sendSnapshot. Apenas iOS.
    private var lastKnownHistoryData: Data? = nil

    private static let historyKey = "notifications.history.v1"

    /// Último resumo de estatísticas calculado pelo iPhone, incluído no próximo sendSnapshot.
    private var cachedStatsSummaryData: Data? = nil

    private func currentPrefsSignature() -> String {
        let defaults = UserDefaults.standard
        var parts: [String] = []
        for key in Self.preferenceKeys {
            if let v = defaults.object(forKey: key) {
                parts.append("\(key)=\(v)")
            } else {
                parts.append("\(key)=nil")
            }
        }
        return parts.joined(separator: "|")
    }

    private override init() { super.init() }

    // MARK: - Ativação

    /// Configura o WCSession e ativa. Idempotente, chamar várias vezes é seguro.
    /// Deve ser chamado cedo no ciclo de vida do app (no `init` do App).
    public func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        if session.activationState != .activated {
            session.activate()
        }

        // Snapshot inicial das ingestões e preferências pra ter base de comparação.
        let defaults = UserDefaults.standard
        for key in Self.intakeKeys {
            lastKnownIntakes[key] = defaults.integer(forKey: key)
        }
        lastPrefsSignature = currentPrefsSignature()
        #if os(iOS)
        lastKnownHistoryData = defaults.data(forKey: Self.historyKey)
        #endif

        // Observa qualquer mudança em UserDefaults, quando uma chave de ingestão muda,
        // envia o delta pra contraparte automaticamente. Isso garante sync em tempo
        // real iPhone ↔ Watch sem precisar de chamada explícita em cada view.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDefaultsDidChange),
            name: UserDefaults.didChangeNotification,
            object: UserDefaults.standard
        )
    }

    @objc private func userDefaultsDidChange() {
        // Quando estamos aplicando um update remoto, ignora, caso contrário o
        // próprio set dispara observer → reenvia → loop.
        guard !suppressObservation else { return }

        let defaults = UserDefaults.standard

        // Ingestões, delta por chave (mais leve, melhor pra real-time bidirecional).
        var intakeChanged = false
        for key in Self.intakeKeys {
            let current = defaults.integer(forKey: key)
            if lastKnownIntakes[key] != current {
                lastKnownIntakes[key] = current
                sendIntakeUpdate(key: key, value: current)
                intakeChanged = true
            }
        }
        #if os(iOS)
        if intakeChanged {
            NotificationCenter.default.post(name: .gymNutshellIntakeDidChange, object: nil)
        }
        #endif

        // Preferências, qualquer mudança dispara snapshot completo. Como prefs
        // mudam pouco (settings page), o overhead é ínfimo e simplifica o protocolo.
        let signature = currentPrefsSignature()
        if signature != lastPrefsSignature {
            lastPrefsSignature = signature
            sendSnapshot()
            return
        }

        // Histórico de notificações, detectado apenas no iPhone (Watch nunca envia snapshot).
        // Quando uma entrada é adicionada ou removida no iPhone, envia snapshot atualizado pro Watch.
        #if os(iOS)
        let currentHistoryData = defaults.data(forKey: Self.historyKey)
        if currentHistoryData != lastKnownHistoryData {
            lastKnownHistoryData = currentHistoryData
            sendSnapshot()
        }
        #endif
    }

    // MARK: - Envio (iPhone → Watch)

    /// Envia snapshot completo do estado atual.
    /// `updateApplicationContext` substitui qualquer snapshot anterior, ideal pra "estado atual".
    public func sendSnapshot() {
        guard WCSession.default.activationState == .activated else { return }
        let defaults = UserDefaults.standard

        var intakes: [String: Int] = [:]
        for key in Self.intakeKeys {
            intakes[key] = defaults.integer(forKey: key)
        }

        // Captura o idioma ativo do iPhone (respeita o per-app language do iOS Settings)
        // e persiste antes de construir prefs, pra entrar no snapshot via preferenceKeys.
        #if os(iOS)
        if let lang = Bundle.main.preferredLocalizations.first {
            defaults.set(lang, forKey: "app.preferredLanguage")
        }
        #endif

        var prefs: [String: Any] = [:]
        for key in Self.preferenceKeys {
            if let value = defaults.object(forKey: key) {
                prefs[key] = value
            }
        }

        var payload: [String: Any] = [
            "intakes": intakes,
            "preferences": prefs
        ]

        // Inclui o histórico de notificações no snapshot (iPhone → Watch).
        // Data é plist-compatível e WatchConnectivity aceita diretamente.
        if let historyData = UserDefaults.standard.data(forKey: Self.historyKey) {
            payload["notificationHistory"] = historyData
        }

        // Inclui o resumo de estatísticas calculado pelo iPhone.
        if let statsData = cachedStatsSummaryData {
            payload["statsSummary"] = statsData
        }

        // Inclui snapshot pré-computado pra complication do Watch.
        // buildCurrent() lê UserDefaults.standard do iPhone, só faz sentido no iOS.
        #if os(iOS)
        if let snapshotData = try? JSONEncoder().encode(WidgetSnapshot.buildCurrent()) {
            payload["widgetSnapshot"] = snapshotData
        }
        #endif

        do {
            try WCSession.default.updateApplicationContext(payload)
        } catch {
            // Falha silenciosa, próximo scenePhase tenta de novo.
        }
    }

    // MARK: - Envio (Watch → iPhone)

    /// Envia uma única atualização de ingestão como delta.
    /// Estratégia em duas camadas:
    ///   1. Se a contraparte estiver `isReachable` (ambos apps em foreground), usa
    ///      `sendMessage`, entrega imediata (~ms).
    ///   2. Caso contrário (ou se sendMessage falhar), cai pra `transferUserInfo`
    ///      que é uma fila FIFO persistente entregue quando a contraparte abrir.
    public func sendIntakeUpdate(key: String, value: Int) {
        let payload: [String: Any] = [
            "type": "intakeUpdate",
            "key": key,
            "value": value,
            "timestamp": Date().timeIntervalSince1970
        ]
        let session = WCSession.default
        guard session.activationState == .activated else {
            // Fila persistente cobre o caso de session ainda não ativada.
            session.transferUserInfo(payload)
            return
        }
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { _ in
                // Falha de entrega imediata → cai pra fila persistente.
                session.transferUserInfo(payload)
            }
        } else {
            session.transferUserInfo(payload)
        }
    }

    /// Atualiza o resumo de estatísticas e o inclui no próximo sendSnapshot.
    /// Chamado pelo iPhone sempre que os dados de SwiftData mudam (scenePhase).
    public func updateStatsSummary(_ summary: WatchStatsSummary) {
        cachedStatsSummaryData = try? JSONEncoder().encode(summary)
        sendSnapshot()
    }

    /// Envia uma exclusão de entrada do histórico como delta.
    /// Mesma estratégia de duas camadas que `sendIntakeUpdate`.
    public func sendHistoryDelete(id: UUID) {
        let payload: [String: Any] = [
            "type": "notificationHistoryDelete",
            "id": id.uuidString,
            "timestamp": Date().timeIntervalSince1970
        ]
        let session = WCSession.default
        guard session.activationState == .activated else {
            session.transferUserInfo(payload)
            return
        }
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { _ in
                session.transferUserInfo(payload)
            }
        } else {
            session.transferUserInfo(payload)
        }
    }

    // MARK: - Aplicação dos recebidos

    private func applyIntakeUpdate(_ payload: [String: Any]) {
        guard let type = payload["type"] as? String else { return }
        switch type {
        case "intakeUpdate":
            guard let key = payload["key"] as? String,
                  let value = payload["value"] as? Int else { return }
            suppressObservation = true
            defer { suppressObservation = false }
            lastKnownIntakes[key] = value
            UserDefaults.standard.set(value, forKey: key)
        case "notificationHistoryDelete":
            guard let idString = payload["id"] as? String,
                  let id = UUID(uuidString: idString) else { return }
            suppressObservation = true
            defer { suppressObservation = false }
            MainActor.assumeIsolated {
                NotificationHistoryStore.shared.delete(id: id)
            }
        default:
            break
        }
    }

    private func applySnapshot(_ payload: [String: Any]) {
        suppressObservation = true
        defer { suppressObservation = false }

        let defaults = UserDefaults.standard
        if let intakes = payload["intakes"] as? [String: Int] {
            for (key, value) in intakes {
                lastKnownIntakes[key] = value
                defaults.set(value, forKey: key)
            }
        }
        if let prefs = payload["preferences"] as? [String: Any] {
            for (key, value) in prefs {
                defaults.set(value, forKey: key)
            }
        }
        // Aplica histórico de notificações recebido do iPhone.
        // MainActor.assumeIsolated é seguro aqui porque applySnapshot é sempre chamado
        // dentro de DispatchQueue.main.async.
        if let historyData = payload["notificationHistory"] as? Data {
            MainActor.assumeIsolated {
                NotificationHistoryStore.shared.applyRemote(historyData)
            }
        }

        // Aplica resumo de estatísticas recebido do iPhone.
        if let statsData = payload["statsSummary"] as? Data {
            MainActor.assumeIsolated {
                WatchStatsStore.shared.apply(statsData)
            }
        }
        // Salva snapshot pra complication no App Group do Watch e dispara reload.
        #if os(watchOS)
        if let snapshotData = payload["widgetSnapshot"] as? Data,
           let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: snapshotData) {
            WidgetSnapshotStore.save(snapshot)
            NotificationCenter.default.post(name: .gymNutshellWatchWidgetReload, object: nil)
        }
        #endif

        // Sincroniza signature pra que o próximo observer (após defer) não veja
        // como mudança local.
        lastPrefsSignature = currentPrefsSignature()
        #if os(iOS)
        lastKnownHistoryData = defaults.data(forKey: Self.historyKey)
        #endif
    }
}

// MARK: - Notification names

extension Notification.Name {
    public static let gymNutshellWatchWidgetReload = Notification.Name("gymnutshell.watchWidgetReload")
    /// Postada no iPhone sempre que um intake muda localmente.
    /// GymNutshellApp observa isso pra recalcular WatchStatsSummary e WidgetSnapshot.
    public static let gymNutshellIntakeDidChange   = Notification.Name("gymnutshell.intakeDidChange")
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {

    public func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        // No-op. Erros são silenciosos, próximo activate() retenta.
    }

    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {
        // No-op, chamado quando o iPhone troca de Watch pareado.
    }

    public func sessionDidDeactivate(_ session: WCSession) {
        // Reativa pra continuar recebendo do (próximo) Watch pareado.
        WCSession.default.activate()
    }
    #endif

    public func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        // [String: Any] não é Sendable; capturamos via nonisolated(unsafe) porque
        // o uso é restrito a UserDefaults.set, que é thread-safe.
        nonisolated(unsafe) let snapshot = applicationContext
        DispatchQueue.main.async {
            self.applySnapshot(snapshot)
        }
    }

    public func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String: Any] = [:]
    ) {
        nonisolated(unsafe) let payload = userInfo
        DispatchQueue.main.async {
            self.applyIntakeUpdate(payload)
        }
    }

    /// Recebe `sendMessage`, entregue só quando a contraparte está reachable.
    /// Tratamos a mesma payload de `applyIntakeUpdate` que o transferUserInfo.
    public func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        nonisolated(unsafe) let payload = message
        DispatchQueue.main.async {
            self.applyIntakeUpdate(payload)
        }
    }
}

#endif // canImport(WatchConnectivity)
