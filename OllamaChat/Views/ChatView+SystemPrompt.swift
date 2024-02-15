//
//  ChatView+SystemPrompt.swift
//  OllamaChat
//
//  Created by Roger on 2024/2/15.
//

import Foundation
import SwiftUI

extension ChatView {
    
    struct SystemEditorView: View {
        
        @ObservedObject var viewModel: ViewModel
        
        @State var systemPrompt: String = ""
        
        @FocusState private var isPopupFocused: Bool
        
        var body: some View {
            ZStack {
                GeometryReader { proxy in
                    ZStack {
                        VStack(spacing: 0) {
                            TextEditor(text: $systemPrompt)
                                .font(.body)
                                .onSubmit {
                                    viewModel.current.system = systemPrompt
                                }
                                .focused(self.$isPopupFocused)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 16)
                            
                            HStack {
                                Button("Cancel") {
                                    isPopupFocused = false
                                    viewModel.showSystemConfig = false
                                }
                                
                                Button("Save") {
                                    viewModel.current.system = systemPrompt
                                    viewModel.showSystemConfig = false
                                }
                            }
                            .frame(height: 32)
                            .maxWidth(alignment: .trailing)
                            .padding(12)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.black.opacity(0.1), lineWidth: 1)
                    )
                    .background() {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white)
                    }
                    .transition(.push(from: .bottom))
                    .frame(
                        width: proxy.size.width > 400 ? 400 : proxy.size.width,
                        height: proxy.size.height > 300 ? 300 : proxy.size.height
                    )
                    .compositingGroup()
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    .maxFrame()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onTapGesture {
                viewModel.showSystemConfig = false
            }
            .animation(.default, value: viewModel.showSystemConfig)
            .task {
                systemPrompt = viewModel.current.system
                isPopupFocused = true
            }
        }
        
    }
    
    func systemPromptView() -> some View {
        SystemEditorView(viewModel: viewModel)
    }
    
}
