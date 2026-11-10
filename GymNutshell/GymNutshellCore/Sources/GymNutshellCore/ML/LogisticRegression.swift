// ⌘
//  GymNutshellCore/ML/LogisticRegression.swift
//
//  Propósito: Regressão logística escrita do zero, treinada no próprio aparelho.
//             Modelo: p = sigmoid(w · x + b), a chance de o dia ser fraco.
//             Treino: descida do gradiente na log-loss, com regularização L2 pra segurar
//             overfitting (poucos dados de uma pessoa só).
//             Sem aleatoriedade: pesos começam em zero, então o Android chega no mesmo resultado.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-11-10.
// ⌘

import Foundation

public struct LogisticRegression: Equatable, Sendable {
    public private(set) var weights: [Double]
    public private(set) var bias: Double

    public init(weights: [Double], bias: Double) {
        self.weights = weights
        self.bias = bias
    }

    /// Converte qualquer número numa probabilidade entre 0 e 1.
    public static func sigmoid(_ z: Double) -> Double { 1 / (1 + exp(-z)) }

    public func probability(_ x: [Double]) -> Double {
        var z = bias
        for j in weights.indices { z += weights[j] * x[j] }
        return Self.sigmoid(z)
    }

    /// Treina com descida do gradiente em lote (todas as linhas a cada passo).
    /// - learningRate: tamanho do passo. epochs: quantos passos. l2: força da regularização.
    public static func train(x: [[Double]], y: [Double],
                             learningRate: Double = 0.1, epochs: Int = 1000,
                             l2: Double = 0.01) -> LogisticRegression {
        let width = x.first?.count ?? 0
        let n = Double(x.count)
        var model = LogisticRegression(weights: [Double](repeating: 0, count: width), bias: 0)
        guard !x.isEmpty else { return model }

        for _ in 0..<epochs {
            var gradW = [Double](repeating: 0, count: width)
            var gradB = 0.0
            // O gradiente da log-loss é (previsto - real) vezes a entrada.
            for i in x.indices {
                let error = model.probability(x[i]) - y[i]
                for j in 0..<width { gradW[j] += error * x[i][j] }
                gradB += error
            }
            for j in 0..<width {
                // L2 puxa os pesos pra zero (o bias fica de fora).
                model.weights[j] -= learningRate * (gradW[j] / n + l2 * model.weights[j])
            }
            model.bias -= learningRate * gradB / n
        }
        return model
    }
}
