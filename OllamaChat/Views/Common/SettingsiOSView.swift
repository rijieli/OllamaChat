//
//  SettingsiOSView.swift
//  OllamaChat
//
//  Created by Roger on 2025/1/25.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

#if os(iOS)
import SwiftUI
import UIKit

struct SettingsiOSView: View {

    @Environment(\.dismiss) var dismiss

    @State var localIP: NetworkAddresses? = nil

    @StateObject var chatViewModel: ChatViewModel = .shared
    
    @State private var globalSystemPrompt = AppSettings.globalSystem

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ollama Service Config")
                                .font(.headline)
                            NumericTextField(title: "Host IP:", text: $chatViewModel.host)
                            
                            if let localIP {
                                VStack(spacing: 2) {
                                    Group {
                                        Text("Current Local IPv4:")
                                        Text("\(localIP.ipv4 ?? "nil")")
                                        Text("Current Local IPv6:")
                                        Text("\(localIP.ipv6 ?? "nil")")
                                    }
                                    .maxWidth(alignment: .leading)
                                    .lineLimit(1)
                                }
                            }
                            
                            NumericTextField(title: "Port", text: $chatViewModel.port)
                            NumericTextField(
                                title: "Request Timeout",
                                text: $chatViewModel.timeoutRequest
                            )
                            NumericTextField(
                                title: "Resources Timeout",
                                text: $chatViewModel.timeoutResource
                            )
                        }
                        .textFieldStyle(.roundedBorder)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    UIApplication.shared.endEditing()
                                }
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Global System Prompt:")
                                        .font(.headline)
                                    Text("Automatic apply to each chat.")
                                        .font(.footnote)
                                }
                                Spacer()
                                Button("Save") {
                                    AppSettings.globalSystem = globalSystemPrompt
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            TextEditor(text: $globalSystemPrompt)
                                .disableAutoQuotes()
                                .font(.body)
                                .frame(height: 100)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.black.opacity(0.1), lineWidth: 1)
                                )
                        }
                    }
                    .padding(16)
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .fontWeight(.bold)
                    }
                }
            }
            .task {
                localIP = UIApplication.shared.getNetworkAddresses()
            }
        }
    }

}

private struct NumericTextField: View {
    let title: String
    @Binding var text: String
    var allowedCharacters: String = "0123456789"

    var body: some View {
        LabeledContent {
            TextField(title, text: $text)
                .keyboardType(.asciiCapable)
        } label: {
            Text(title)
        }
    }
}
#endif
