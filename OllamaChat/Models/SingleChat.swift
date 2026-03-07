//
//  SingleChat.swift
//  OllamaChat
//
//  Created by Roger on 2024/7/21.
//  Copyright © 2024 IdeasForm. All rights reserved.
//

import CoreData
import Foundation

@objc(SingleChat)
class SingleChat: NSManagedObject, Identifiable {
    @NSManaged public var history: String
    @NSManaged public var id: UUID
    @NSManaged public var model: String
    @NSManaged public var modelConfiguration: String?
    @NSManaged public var name: String
    @NSManaged public var createdAt: Date

    public var messages: [ChatMessage] {
        get {
            guard let data = history.data(using: .utf8) else {
                return []
            }
            let decoder = JSONDecoder()
            do {
                return try decoder.decode([ChatMessage].self, from: data)
            } catch {
                print("Failed to decode history string: \(error)")
                return []
            }
        }
        set {
            let encoder = JSONEncoder()
            do {
                let data = try encoder.encode(newValue)
                guard let historyString = String(data: data, encoding: .utf8) else {
                    assert(false, "Failed to convert encoded chat history into a UTF-8 string.")
                    history = "[]"
                    return
                }

                history = historyString
            } catch {
                print("Failed to encode messages: \(error)")
            }
        }
    }

    public var chatConfiguration: ChatConfiguration? {
        get {
            ChatConfiguration.decodeModelConfiguration(from: modelConfiguration)
        }
        set {
            modelConfiguration = newValue?.encodedModelConfiguration()
        }
    }
}

extension SingleChat {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SingleChat> {
        return NSFetchRequest<SingleChat>(entityName: "SingleChat")
    }

    public class func fetch(by id: UUID) -> SingleChat? {
        let fetchRequest: NSFetchRequest<SingleChat> = SingleChat.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1

        do {
            return try CoreDataStack.shared.context.fetch(fetchRequest).first
        } catch {
            print("Failed to fetch SingleChat by id: \(error)")
            return nil
        }
    }

    public class func fetchLastCreated() -> SingleChat? {
        let fetchRequest: NSFetchRequest<SingleChat> = SingleChat.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        fetchRequest.fetchLimit = 1

        do {
            return try CoreDataStack.shared.context.fetch(fetchRequest).first
        } catch {
            print("Failed to fetch last created SingleChat: \(error)")
            return nil
        }
    }

    public class var chatCount: Int {
        let fetchRequest: NSFetchRequest<SingleChat> = SingleChat.fetchRequest()
        return (try? CoreDataStack.shared.context.count(for: fetchRequest)) ?? 0
    }

    public class func createNewSingleChat(
        messages: [ChatMessage],
        model: String,
        chatConfiguration: ChatConfiguration?
    ) -> SingleChat {
        let context = CoreDataStack.shared.context
        let chatCount = chatCount

        // Create new SingleChat instance
        let newChat = SingleChat(context: context)
        newChat.id = UUID()
        newChat.name = "Chat \(chatCount + 1)"  // Automatically set name based on chat count
        newChat.model = model
        newChat.chatConfiguration = chatConfiguration
        newChat.createdAt = Date()
        newChat.messages = messages

        return newChat
    }

    public class func duplicate(_ chat: SingleChat) -> SingleChat {
        let context = CoreDataStack.shared.context
        let chatCount = chatCount

        // Create new SingleChat instance
        let newChat = SingleChat(context: context)
        newChat.id = UUID()
        newChat.name = "Name\(chatCount + 1)"  // Automatically set name based on chat count
        newChat.model = chat.model
        newChat.modelConfiguration = chat.modelConfiguration
        newChat.createdAt = Date()
        newChat.messages = chat.messages

        return newChat
    }
}
