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
                        VStack(spacing: 12) {
                            Text("System")
                                .font(.title)
                                .fontWeight(.bold)
                                .padding(.leading, 12)
                                .maxWidth(alignment: .leading)
                                .padding(.bottom, 4)
                            ZStack {
                                TextEditor(text: $systemPrompt)
                                    .font(.body)
                                    .onSubmit {
                                        viewModel.current.system = systemPrompt
                                    }
                                    .focused(self.$isPopupFocused)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 16)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.black.opacity(0.1), lineWidth: 1)
                            )
                            .background()
                            
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
                        }
                        .padding(12)
                    }
                    .maxFrame()
                }
            }
            .frame(minWidth: 360, minHeight: 300, idealHeight: 300)
            .task {
                systemPrompt = viewModel.current.system
                isPopupFocused = true
            }
        }
        
    }
    
    struct MessageEditorView: View {
        
        @ObservedObject var viewModel: ViewModel
        
        @State var info: String = ""
        
        @FocusState private var isPopupFocused: Bool
        
        var body: some View {
            ZStack {
                GeometryReader { proxy in
                    ZStack {
                        VStack(spacing: 12) {
                            ZStack {
                                TextEditor(text: $info)
                                    .font(.body)
                                    .onSubmit {
                                        viewModel.sentPrompt[viewModel.editingCellIndex!] = info
                                    }
                                    .focused(self.$isPopupFocused)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 16)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.black.opacity(0.1), lineWidth: 1)
                            )
                            .background()
                            
                            HStack {
                                Button("Cancel") {
                                    isPopupFocused = false
                                    viewModel.editingCellIndex = nil
                                    viewModel.showEditingMessage = false
                                }
                                
                                Button("Save") {
                                    viewModel.sentPrompt[viewModel.editingCellIndex!] = info
                                    viewModel.resendUntil(viewModel.editingCellIndex!)
                                    viewModel.editingCellIndex = nil
                                    viewModel.showEditingMessage = false
                                }
                            }
                            .frame(height: 32)
                            .maxWidth(alignment: .trailing)
                        }
                        .padding(12)
                    }
                    .maxFrame()
                }
            }
            .frame(minWidth: 360, minHeight: 300, idealHeight: 300)
            .task {
                info = viewModel.sentPrompt[viewModel.editingCellIndex!]
                isPopupFocused = true
            }
        }
        
    }
}
