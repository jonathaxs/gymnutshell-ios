// ⌘
//  GymNutshell/GymNutshellApp/Views/TodayView/Components/TodayGoalsListView.swift
//
//  Propósito: Container estrutural pra lista de metas, limita o conteúdo a uma largura
//             máxima (330 pt por padrão) e centraliza horizontalmente.
//             Usado tanto no layout retrato quanto no layout wide da TodayView.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-03-29.
// ⌘

import SwiftUI

/// Wrapper centralizado com largura máxima pras linhas de metas da TodayView.
struct TodayGoalsListView<Content: View>: View {

    var maxWidth: CGFloat = 330
    let content: Content

    init(maxWidth: CGFloat = 330, @ViewBuilder content: () -> Content) {
        self.maxWidth = maxWidth
        self.content = content()
    }

    var body: some View {
        // Cada item é uma categoria inteira (cabeçalho + card), por isso o espaço maior.
        VStack(spacing: 20) {
            content
        }
        .padding(.top, 4)
        .frame(maxWidth: maxWidth)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
