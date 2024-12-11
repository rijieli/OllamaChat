//
//  ChatPlaceholderView.swift
//  OllamaChat
//
//  Created by Roger on 2024/12/10.
//  Copyright © 2024 IdeasForm. All rights reserved.
//

import SwiftUI

struct ChatPlaceholderView: View {

    @ObservedObject var viewModel: ChatViewModel = .shared

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            VStack(spacing: 8) {
                Image(systemName: "message.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                Text("No chat selected")
                    .font(.title)
                Text("Please select a chat from the list or create a new one")
            }

            Button("New Chat") {
                viewModel.newChat()
            }

            Spacer()
        }
    }
}
