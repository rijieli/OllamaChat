//
//  ChatView.swift
//  Ollama Swift
//
//  Created by Karim ElGhandour on 08.10.23.
//

import Hue
import SwiftUI
import SwiftUIIntrospect

struct ChatView: View {

    @StateObject var viewModel = ChatViewModel.shared
    @StateObject var apiManager = APIManager.shared
    @StateObject var speechCenter = TextSpeechCenter.shared
    @ObservedObject var modelRegistry = UnifiedModelRegistry.shared

    @FocusState var promptFieldIsFocused: Bool

    @Namespace var bottomID
    
    static let maxWidth: CGFloat = 800
    static let padding: CGFloat = 16

    var statusTitle: LocalizedStringKey {
        viewModel.errorModel == nil ? "Connected" : "Error"
    }

    var body: some View {
        VStack(spacing: 0) {
            messagesList
            messageInput
                .padding(.horizontal, ChatView.padding)
                .frame(maxWidth: ChatView.maxWidth)
        }
        .frame(minWidth: 400, idealWidth: 700, minHeight: 500, idealHeight: 800)
        .background(Color.ocPrimaryBackground)
        .task {
            await UnifiedModelRegistry.shared.fetchAllModels()
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                modelPicker()

                Button {
                    viewModel.clearError()
                } label: {
                    Image(systemName: "circle.fill")
                        .frame(width: 24, height: 24)
                        .frame(width: 28, height: 28)
                        .foregroundStyle(viewModel.errorModel == nil ? .green : .red)
                        .contentShape(.rect)
                }
                .buttonStyle(.simpleVisualEffect)
                .help(statusTitle)
                .popover(
                    item: $viewModel.errorModel
                ) { errorModel in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(errorModel.errorTitle)
                            .font(.system(size: 14, weight: .semibold))
                            .textSelection(.enabled)
                        Text(errorModel.errorMessage)
                            .font(.system(size: 13))
                            .textSelection(.enabled)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 12)
                    .frame(width: 320)
                    .interactiveDismissDisabled()
                }

                Button {
                    Task {
                        await UnifiedModelRegistry.shared.refreshModels()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 20, height: 20, alignment: .center)
                }
            }
        }
    }
}
