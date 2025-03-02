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
    let fontSize: CGFloat = 15

    @State private var showingErrorPopover: Bool = false

    @ObservedObject var viewModel = ChatViewModel.shared
    @ObservedObject var speechCenter = TextSpeechCenter.shared

    @FocusState var promptFieldIsFocused: Bool

    @Namespace var bottomID

    var body: some View {
        VStack(spacing: 0) {
            messagesList
            messageInput
        }
        .frame(minWidth: 400, idealWidth: 700, minHeight: 600, idealHeight: 800)
        .background(Color.ocPrimaryBackground)
        .task {
            await getTags()
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                modelPicker()

                if viewModel.errorModel.showError {
                    Button {
                        self.showingErrorPopover.toggle()
                    } label: {
                        Label("Error", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                    .popover(isPresented: self.$showingErrorPopover) {
                        VStack(alignment: .leading) {
                            Text(viewModel.errorModel.errorTitle)
                                .font(.title2)
                                .textSelection(.enabled)
                            Text(viewModel.errorModel.errorMessage)
                                .textSelection(.enabled)
                        }
                        .padding()
                    }
                } else {
                    Label("Connected", systemImage: "circle.fill")
                        .foregroundStyle(.green)
                }
                Button {
                    Task {
                        await getTags()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 20, height: 20, alignment: .center)
                }
            }
        }
    }

    func getTags() async {
        do {
            viewModel.waitingResponse = false
            viewModel.errorModel.showError = false
            _ = try await fetchOllamaModels()
        } catch let NetError.invalidURL(error) {
            viewModel.errorModel = invalidURLError(error: error)
        } catch let NetError.invalidData(error) {
            viewModel.errorModel = invalidTagsDataError(error: error)
        } catch let NetError.invalidResponse(error) {
            viewModel.errorModel = invalidResponseError(error: error)
        } catch let NetError.unreachable(error) {
            viewModel.errorModel = unreachableError(error: error)
        } catch {
            viewModel.errorModel = genericError(error: error)
        }
    }
}
