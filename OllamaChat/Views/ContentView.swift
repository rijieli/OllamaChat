//
//  ContentView.swift
//  Ollama Swift
//
//  Created by Karim ElGhandour on 14.10.23.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.appearsActive) var appearsActive

    @ObservedObject var viewModel: ChatViewModel = .shared

    var body: some View {
        NavigationSplitView {
            ChatListView().navigationSplitViewColumnWidth(min: 240, ideal: 320, max: 400)
        } detail: {
            if viewModel.currentChat == nil {
                ChatPlaceholderView()
            } else {
                ChatView().navigationSplitViewColumnWidth(min: 400, ideal: 600)
            }
        }
        .navigationTitle(viewModel.currentChat?.name ?? "Ollama Chat")
        .onChange(of: appearsActive) { newValue in
            if newValue == true {
                log.debug("Refresh Models")
                Task {
                    do {
                        _ = try await fetchOllamaModels(timeout: 5)
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
}
