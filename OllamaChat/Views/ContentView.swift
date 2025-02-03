//
//  ContentView.swift
//  Ollama Swift
//
//  Created by Karim ElGhandour on 14.10.23.
//

import SwiftUI

struct ContentView: View {

    @ObservedObject var viewModel: ChatViewModel = .shared

    var body: some View {
        #if os(macOS)
            NavigationSplitView {
                ChatListView()
            } detail: {
                if viewModel.currentChat == nil {
                    ChatPlaceholderView()
                } else {
                    ChatView()
                }
            }
            .navigationTitle(viewModel.currentChat?.name ?? "Ollama Chat")
        #else
            NavigationStack {
                ChatListView()
                    .navigationTitle("Chats")
            }
        #endif
    }
}
