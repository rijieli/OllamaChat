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

private let timeFormatter: DateFormatter = {
    let fmt = DateFormatter()
    fmt.dateStyle = .short
    fmt.timeStyle = .short
    fmt.locale = Locale.current
    return fmt
}()

struct ChatListView: View {
    
    #if os(macOS)
    let cornerRadius: CGFloat = 8
    #else
    let cornerRadius: CGFloat = 16
    #endif

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

    var body: some View {
        VStack(spacing: 0) {
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

            footerView
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
        }
        .sheet(isPresented: $chatViewModel.showSystemConfig) {
            SystemEditorView(viewModel: chatViewModel)
            #if os(iOS)
            .presentationDetents([.medium, .large])
            #endif
        }
        .sheet(isPresented: $chatViewModel.showEditingMessage) {
            MessageEditorView(viewModel: chatViewModel)
            #if os(iOS)
            .presentationDetents([.medium, .large])
            #endif
        }
        #if os(macOS)
        .sheet(isPresented: $chatViewModel.showModelConfig) {
            ManageModelsView()
        }
        .sheet(isPresented: $chatViewModel.showSettingsView) {
            SettingsView()
        }
        #else
        .sheet(isPresented: $chatViewModel.showSettingsView) {
            SettingsiOSView()
        }
        .navigationDestination(item: $chatViewModel.currentChat) { _ in
            ChatView()
        }
        #endif
    }

    var footerView: some View {
#if os(macOS)
        VStack(spacing: 8) {
            Button {
                chatViewModel.newChat()
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
        .font(.system(size: 20, weight: .bold))
        .padding(.bottom, 16)
        .padding(.horizontal, 12)
        #else
        HStack(spacing: 16) {
            Button{
                chatViewModel.showSettingsView = true
            } label: {
                gearLabel
            }
            
            Spacer()
            
            Button {
                chatViewModel.newChat()
            } label: {
                Image(systemName: "plus")
                    .frame(width: 32, height: 32)
            }
        }
        .font(.system(size: 20, weight: .semibold))
        .padding(.horizontal, 16)
        .frame(height: 44)
        #endif
    }

    var gearLabel: some View {
        Image(systemName: "gear").frame(width: 32, height: 32)
    }
}

extension ChatListView {

    func cell(item: SingleChat, selected: Bool) -> some View {
        VStack(spacing: 4) {
            Text("\(item.name)")
                .font(.headline)
                .maxWidth(alignment: .leading)
                .foregroundStyle(selected ? Color.accentColor : Color.primary)
            Text("\(timeFormatter.string(from: item.createdAt))")
                .font(.subheadline)
                .maxWidth(alignment: .leading)
                .foregroundStyle(selected ? Color.accentColor : Color.secondary)
        }
        .overlay {
            Text("\(item.messages.count)")
                .font(.system(size: 13, weight: .regular))
                .maxWidth(alignment: .trailing)
                .foregroundStyle(selected ? Color.accentColor : Color.secondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .maxWidth()
        .lineLimit(1)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius).fill(.background)
                .overlay {
                    #if os(macOS)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            selected ? Color.accentColor : Color.black.opacity(0.1),
                            lineWidth: selected ? 2 : 0.5
                        )
                    #else
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            selected ? Color.accentColor : Color.black.opacity(0.1),
                            lineWidth: 1
                        )
                    #endif
                }
        )
        .contentShape(.rect)
        #if os(iOS)
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: cornerRadius))
        #endif
        .ifGeometryGroup()
    }

}
