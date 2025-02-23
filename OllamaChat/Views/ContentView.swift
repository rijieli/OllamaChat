//
//  ContentView.swift
//  Ollama Swift
//
//  Created by Karim ElGhandour on 14.10.23.
//

import SwiftUI

struct ContentView: View {
    
    #if os(macOS)
    @Environment(\.appearsActive) var appearsActive
    #else
    @Environment(\.scenePhase) var scenePhase
    #endif

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
            .onChange(of: appearsActive) { newValue in
                if newValue == true {
                    print("Refresh Models")
                    Task {
                        do {
                            _ = try await getLocalModels(timeout: 5)
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
            }
        #else
            NavigationStack {
                ChatListView()
                    .navigationTitle("Chats")
            }
            .onChange(of: scenePhase) { newValue in
                onScenePhaseChanged(newValue)
            }
        #endif
    }
    
    func onScenePhaseChanged(_ phase: ScenePhase) {
        switch phase {
        case .active:
            print("Scene is now active")
        case .background:
            print("Scene is now in background")
        case .inactive:
            print("Scene is now inactive")
        @unknown default:
            print("Scene @unknown default")
        }
    }
}
