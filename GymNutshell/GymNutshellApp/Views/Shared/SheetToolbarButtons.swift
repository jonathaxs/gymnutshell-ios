// ⌘
//  GymNutshell/GymNutshellApp/Views/Shared/SheetToolbarButtons.swift
//
//  Propósito: Botões do topo das sheets (fechar, confirmar e ações com ícone).
//             iOS 26+: botões com ícone do sistema (X, ✓), que no iPhone Duo vão pra barra vertical
//             ao lado da tela; item só com texto fica fora dela. iOS 18: o texto de sempre.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-10-28.
// ⌘

import SwiftUI
import GymNutshellCore

/// Fechar, cancelar ou voltar de uma sheet. O título vira o nome lido pelo VoiceOver no iOS 26+.
struct SheetCloseButton: View {

    var title: String = String(localized: "common.close", bundle: .gymNutshellCore)
    let action: () -> Void

    var body: some View {
        if #available(iOS 26.0, *) {
            Button(role: .close, action: action)
                .accessibilityLabel(title)
        } else {
            Button(title, action: action)
        }
    }
}

/// Salvar ou concluir. No iOS 26+ é o ✓ em destaque do sistema.
struct SheetConfirmButton: View {

    let title: String
    let action: () -> Void

    var body: some View {
        if #available(iOS 26.0, *) {
            Button(role: .confirm, action: action)
                .accessibilityLabel(title)
        } else {
            Button(title, action: action)
        }
    }
}

/// Outra ação do topo (ex.: Editar): ícone no iOS 26+, texto no iOS 18.
struct SheetToolbarButton: View {

    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        if #available(iOS 26.0, *) {
            Button(action: action) {
                Label(title, systemImage: systemImage)
            }
        } else {
            Button(title, action: action)
        }
    }
}
