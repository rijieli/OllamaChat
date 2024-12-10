//
//  ChatListView.swift
//  OllamaChat
//
//  Created by Roger on 2024/7/21.
//  Copyright © 2024 IdeasForm. All rights reserved.
//

import CoreData
import Foundation
import SwiftUI

struct ChatListView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \SingleChat.createdAt, ascending: false)
        ],
        animation: .default
    )
    private var items: FetchedResults<SingleChat>

    @State var showRenameDialog = false
    @State private var newName: String = ""
    @State var renameItem: SingleChat? = nil

    @ObservedObject var chatViewModel = ChatViewModel.shared

    let formatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateStyle = .short
        fmt.timeStyle = .short
        fmt.locale = Locale.current
        return fmt
    }()

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(items) { item in
                        let isSelected = chatViewModel.currentChat?.id == item.id
                        cell(item: item, selected: isSelected)
                            .onTapGesture {
                                chatViewModel.loadChat(item)
                            }
                            .contextMenu {
                                Button("Rename") {
                                    renameItem = item
                                    newName = item.name
                                    showRenameDialog = true
                                }
                                Button("Duplicate") {
                                    DispatchQueue.main.async {
                                        let duplicated = SingleChat.duplicate(
                                            item
                                        )
                                        CoreDataStack.shared.saveContext()
                                        chatViewModel.loadChat(duplicated)
                                    }
                                }
                                Button("Delete") {
                                    DispatchQueue.main.async {
                                        CoreDataStack.shared.context.delete(
                                            item
                                        )
                                        CoreDataStack.shared.saveContext()
                                    }
                                    chatViewModel.loadChat(nil)
                                }
                            }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .maxFrame()
            VStack(spacing: 8) {
                Button {
                    let newChat = SingleChat.createNewSingleChat(
                        messages: [],
                        model: chatViewModel.model
                    )
                    CoreDataStack.shared.saveContext()
                    chatViewModel.loadChat(newChat)
                } label: {
                    Label("New Chat", systemImage: "plus")
                        .fontWeight(.bold)
                        .frame(height: 32)
                        .frame(maxWidth: .infinity)
                }
                HStack(spacing: 8) {
                    Button {
                        chatViewModel.showModelConfig = true
                    } label: {
                        Image(systemName: "cube")
                            .fontWeight(.bold)
                            .frame(width: 32, height: 32)
                    }

                    if #available(macOS 14.0, *) {
                        SettingsLink {
                            gearLabel
                        }
                    } else {
                        Button(
                            action: {
                                if #available(macOS 13.0, *) {
                                    NSApp.sendAction(
                                        Selector(("showSettingsWindow:")),
                                        to: nil,
                                        from: nil
                                    )
                                } else {
                                    NSApp.sendAction(
                                        Selector(("showPreferencesWindow:")),
                                        to: nil,
                                        from: nil
                                    )
                                }
                            },
                            label: {
                                gearLabel
                            }
                        )
                    }
                    Spacer()
                }
            }
            .padding(.bottom, 16)
            .padding(.horizontal, 12)
        }
        .animation(.smooth, value: chatViewModel.currentChat)
        .alert("Rename this chat", isPresented: $showRenameDialog) {
            TextField("Enter your name", text: $newName)
            Button("Rename") {
                if let item = renameItem {
                    item.name = newName
                    CoreDataStack.shared.saveContext()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Xcode will print whatever you type.")
        }
    }

    var gearLabel: some View {
        Image(systemName: "gear")
            .fontWeight(.bold)
            .frame(width: 32, height: 32)
    }
}

extension ChatListView {

    func cell(item: SingleChat, selected: Bool) -> some View {
        VStack(spacing: 4) {
            Text("\(item.name)")
                .font(.headline)
                .maxWidth(alignment: .leading)
            Text("\(formatter.string(from: item.createdAt))")
                .font(.subheadline)
                .maxWidth(alignment: .leading)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .maxWidth()
        .foregroundStyle(selected ? Color.accentColor : Color.primary)
        .background(
            RoundedRectangle(cornerRadius: 8).fill(.background)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            selected ? Color.accentColor : Color.black.opacity(0.1),
                            lineWidth: selected ? 2 : 0.5
                        )
                }
        )
        .contentShape(.rect)
    }

}
