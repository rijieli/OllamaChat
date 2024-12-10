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

    @FocusState var promptFieldIsFocused: Bool

    @Namespace var bottomID

    var body: some View {
        ZStack {
            messagesList
        }
        .frame(minWidth: 400, idealWidth: 700, minHeight: 600, idealHeight: 800)
        .background(Color(NSColor.controlBackgroundColor))
        .task {
            self.getTags()
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                HStack {
                    Picker("Model:", selection: $viewModel.model) {
                        ForEach(viewModel.tags.models, id: \.self) { model in
                            Text(model.modelInfo.model).tag(model.name)
                        }
                    }
                }
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
                    Text("Server:")
                    Label("Connected", systemImage: "circle.fill")
                        .foregroundStyle(.green)
                }
                Button {
                    self.getTags()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 20, height: 20, alignment: .center)
                }
            }
        }
        .sheet(isPresented: $viewModel.showSystemConfig) {
            SystemEditorView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showModelConfig) {
            ManageModelsView()
        }
        .sheet(isPresented: $viewModel.showEditingMessage) {
            MessageEditorView(viewModel: viewModel)
        }
    }

    func actionButton(_ sfName: String, action: (() -> Void)?) -> some View {
        Button {
            action?()
        } label: {
            Image(systemName: sfName)
                .frame(width: 20, height: 20, alignment: .center)
                .frame(width: 40, height: 32)
                .foregroundStyle(.white)
                .background(Capsule().fill(Color.blue))
        }
        .buttonStyle(.plain)
    }

    func getTags() {
        Task {
            do {
                viewModel.disabledButton = false
                viewModel.waitingResponse = false
                viewModel.errorModel.showError = false
                viewModel.tags = try await getLocalModels(
                    host: "\(viewModel.host):\(viewModel.port)",
                    timeoutRequest: viewModel.timeoutRequest,
                    timeoutResource: viewModel.timeoutResource
                )
                if viewModel.tags.models.count > 0 {
                    viewModel.model = viewModel.tags.models[0].name
                } else {
                    viewModel.model = ""
                    viewModel.errorModel = noModelsError(error: nil)
                }
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
}
