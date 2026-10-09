// ⌘
//  GymNutshellCore/Services/HealthKitManager.swift
//
//  Propósito: Centraliza autorização do Apple Health (HealthKit), gravação de entradas de
//             Análise de Sono e leitura de amostras de Treino pra detecção automática de check-in.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-01-08.
// ⌘

import Foundation
import HealthKit

/// Centraliza a autorização e gravações no Apple Health (HealthKit) pra o app.
public final class HealthKitManager: @unchecked Sendable {

    public static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()

    private init() {}

    // MARK: - Classificação de treinos

    private static let cardioActivityTypes: Set<HKWorkoutActivityType> = [
        .walking, .running, .cycling, .swimming, .elliptical,
        .rowing, .stairClimbing, .hiking, .cardioDance, .socialDance, .jumpRope,
        .stepTraining, .downhillSkiing, .crossCountrySkiing,
        .snowboarding, .skatingSports, .waterSports, .paddleSports,
        .soccer, .basketball, .tennis, .volleyball, .baseball,
        .americanFootball, .rugby, .hockey, .racquetball, .squash,
        .badminton, .handball, .lacrosse, .golf, .softball
    ]

    private static let strengthActivityTypes: Set<HKWorkoutActivityType> = [
        .traditionalStrengthTraining, .functionalStrengthTraining,
        .crossTraining, .highIntensityIntervalTraining,
        .boxing, .wrestling, .martialArts, .coreTraining,
        .gymnastics, .climbing, .mixedCardio
    ]

    // MARK: - Autorização

    public func requestSleepAuthorizationIfNeeded() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        let typesToShare: Set<HKSampleType> = [sleepType]
        let typesToRead: Set<HKObjectType> = [sleepType]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { _, _ in
            // Ignorado intencionalmente.
        }
    }

    /// Pede de uma vez só tudo que o app usa do Apple Saúde (sono: leitura + escrita; treinos: leitura).
    /// Usado no fim da Welcome pra mostrar uma única folha de permissão. Retorna false se o Saúde
    /// não existe no aparelho ou se o pedido falhou; recusar não bloqueia nada.
    public func requestOnboardingAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return false }
        let toShare: Set<HKSampleType> = [sleepType]
        let toRead: Set<HKObjectType> = [sleepType, HKObjectType.workoutType()]
        return await withCheckedContinuation { continuation in
            healthStore.requestAuthorization(toShare: toShare, read: toRead) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }

    /// Indica se o Apple Saúde existe neste aparelho (iPad sem Saúde, por exemplo, retorna false).
    public static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    public func requestWorkoutReadAuthorizationIfNeeded() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let workoutType = HKObjectType.workoutType()
        healthStore.requestAuthorization(toShare: nil, read: [workoutType]) { _, _ in
            // Ignorado intencionalmente.
        }
    }

    // MARK: - Nomes de exibição das atividades

    public static func displayName(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .running:                      return String(localized: "healthkit.activity.running", bundle: .gymNutshellCore)
        case .walking:                      return String(localized: "healthkit.activity.walking", bundle: .gymNutshellCore)
        case .cycling:                      return String(localized: "healthkit.activity.cycling", bundle: .gymNutshellCore)
        case .swimming:                     return String(localized: "healthkit.activity.swimming", bundle: .gymNutshellCore)
        case .elliptical:                   return String(localized: "healthkit.activity.elliptical", bundle: .gymNutshellCore)
        case .rowing:                       return String(localized: "healthkit.activity.rowing", bundle: .gymNutshellCore)
        case .stairClimbing:                return String(localized: "healthkit.activity.stairClimbing", bundle: .gymNutshellCore)
        case .hiking:                       return String(localized: "healthkit.activity.hiking", bundle: .gymNutshellCore)
        case .jumpRope:                     return String(localized: "healthkit.activity.jumpRope", bundle: .gymNutshellCore)
        case .cardioDance, .socialDance:    return String(localized: "healthkit.activity.dance", bundle: .gymNutshellCore)
        case .traditionalStrengthTraining:  return String(localized: "healthkit.activity.strengthTraining", bundle: .gymNutshellCore)
        case .functionalStrengthTraining:   return String(localized: "healthkit.activity.functionalTraining", bundle: .gymNutshellCore)
        case .crossTraining:                return String(localized: "healthkit.activity.crossTraining", bundle: .gymNutshellCore)
        case .highIntensityIntervalTraining: return String(localized: "healthkit.activity.hiit", bundle: .gymNutshellCore)
        case .boxing:                       return String(localized: "healthkit.activity.boxing", bundle: .gymNutshellCore)
        case .martialArts:                  return String(localized: "healthkit.activity.martialArts", bundle: .gymNutshellCore)
        case .coreTraining:                 return String(localized: "healthkit.activity.coreTraining", bundle: .gymNutshellCore)
        case .climbing:                     return String(localized: "healthkit.activity.climbing", bundle: .gymNutshellCore)
        default:                            return String(localized: "healthkit.activity.other", bundle: .gymNutshellCore)
        }
    }

    // MARK: - Leitura de treinos

    public func checkTodayWorkouts(completion: @escaping @MainActor @Sendable (
        _ workoutMinutes: Int, _ cardioMinutes: Int,
        _ workoutName: String?, _ cardioName: String?
    ) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            Task { @MainActor in completion(0, 0, nil, nil) }
            return
        }

        let workoutType = HKObjectType.workoutType()

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        let query = HKSampleQuery(
            sampleType: workoutType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { _, samples, _ in
            var workoutMinutes: Int = 0
            var cardioMinutes: Int = 0
            var workoutName: String?
            var cardioName: String?

            for sample in samples ?? [] {
                guard let workout = sample as? HKWorkout else { continue }
                let type = workout.workoutActivityType
                let durationMinutes = Int((workout.duration / 60).rounded())

                if Self.strengthActivityTypes.contains(type) {
                    workoutMinutes += durationMinutes
                    if workoutName == nil { workoutName = Self.displayName(for: type) }
                } else if Self.cardioActivityTypes.contains(type) {
                    cardioMinutes += durationMinutes
                    if cardioName == nil { cardioName = Self.displayName(for: type) }
                }
            }

            let wMin = workoutMinutes
            let cMin = cardioMinutes
            let wName = workoutName
            let cName = cardioName
            Task { @MainActor in completion(wMin, cMin, wName, cName) }
        }

        healthStore.execute(query)
    }

    // MARK: - Gravações

    public func writeSleepIfNeeded(for date: Date, hours: Int) {
        guard hours > 0 else { return }
        guard UserDefaults.standard.bool(forKey: "healthkit.syncSleepEnabled") else { return }
        guard HKHealthStore.isHealthDataAvailable() else { return }
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        let status = healthStore.authorizationStatus(for: sleepType)
        guard status == .sharingAuthorized else { return }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = start.addingTimeInterval(TimeInterval(hours) * 60 * 60)

        let sample = HKCategorySample(
            type: sleepType,
            value: HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            start: start,
            end: end
        )

        healthStore.save(sample) { success, _ in
            if success {
                NotificationManager.shared.fireHealthLogged(.sleep, value: hours)
            }
        }
    }
}
