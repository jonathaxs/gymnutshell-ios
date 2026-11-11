// ⌘
//  GymNutshell/GymNutshellApp/Views/SettingsView/Backup/RiskModelDebugView.swift
//
//  Propósito: Tela de debug do "dia de risco". Treina o modelo com os dias registrados no
//             aparelho e mostra a acurácia na validação comparada com as regras simples,
//             os pesos aprendidos e a chance de hoje. Só existe em build de debug.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-11-10.
// ⌘

#if DEBUG
import SwiftUI
import SwiftData
import GymNutshellCore

struct RiskModelDebugView: View {

    @Query(sort: \DailyRecord.date, order: .forward) private var records: [DailyRecord]

    private var days: [TrainingDay] { records.map(TrainingDay.init(record:)) }

    var body: some View {
        // Treino é rápido (poucos dias × 15 features), dá pra rodar direto no body.
        let days = days
        let report = RiskModel.evaluate(days: days)

        List {
            if let report {
                resultSection(report, days: days)
                accuracySection(report)
                weightsSection(report)
            } else {
                Section {
                    Text("Precisa de pelo menos \(RiskModel.minimumDays) dias registrados. Hoje: \(days.count).")
                }
            }
        }
        .navigationTitle("Modelo × regra")
    }

    // MARK: - Seções

    private func resultSection(_ report: RiskModelReport, days: [TrainingDay]) -> some View {
        let today = Calendar.current.startOfDay(for: .now)
        let risk = RiskModel.riskProbability(for: today, days: days, report: report)
        return Section {
            row("Veredito", report.beatsBaseline ? "Modelo ganha" : "Usar a regra")
            row("Chance de hoje ser fraco", percent(risk))
            row("Dias fracos no histórico", percent(report.weakRate))
            row("Treino / validação", "\(report.trainCount) / \(report.validationCount) dias")
        } header: {
            Text("Resultado")
        } footer: {
            Text("Dia fraco = percent até \(RiskModel.defaultWeakThreshold). A validação usa os dias mais recentes.")
        }
    }

    private func accuracySection(_ report: RiskModelReport) -> some View {
        Section("Acurácia na validação") {
            row("Modelo (regressão logística)", percent(report.modelAccuracy))
            row("Regra do dia da semana", percent(report.weekdayAccuracy))
            row("Regra da maioria", percent(report.majorityAccuracy))
        }
    }

    // Peso positivo puxa pra "dia fraco"; ordenado pelo tamanho do efeito.
    private func weightsSection(_ report: RiskModelReport) -> some View {
        let pairs = zip(RiskFeatures.names, report.model.weights)
            .sorted { abs($0.1) > abs($1.1) }
        return Section {
            ForEach(Array(pairs.enumerated()), id: \.offset) { _, pair in
                row(pair.0, String(format: "%+.3f", pair.1))
            }
            row("bias", String(format: "%+.3f", report.model.bias))
        } header: {
            Text("Pesos")
        } footer: {
            Text("Positivo aumenta a chance de dia fraco; negativo diminui.")
        }
    }

    // MARK: - Auxiliares

    private func row(_ title: String, _ value: String) -> some View {
        LabeledContent(title) {
            Text(value).monospacedDigit()
        }
    }

    private func percent(_ value: Double) -> String {
        value.formatted(.percent.precision(.fractionLength(0)))
    }
}
#endif
