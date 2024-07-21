//
//  SingleChat.swift
//  OllamaChat
//
//  Created by Roger on 2024/7/21.
//  Copyright © 2024 IdeasForm. All rights reserved.
//

import Foundation
import CoreData

@objc(SingleChat)
class SingleChat: NSManagedObject, Identifiable {
    @NSManaged public var history: String
    @NSManaged public var id: UUID
    @NSManaged public var model: String
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
                history = String(data: data, encoding: .utf8) ?? "[]"
            } catch {
                print("Failed to encode messages: \(error)")
            }
        }
    }
}

extension SingleChat {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SingleChat> {
        return NSFetchRequest<SingleChat>(entityName: "SingleChat")
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
    
    public class func createNewSingleChat(messages: [ChatMessage], model: String) -> SingleChat {
        let context = CoreDataStack.shared.context
        let fetchRequest: NSFetchRequest<SingleChat> = SingleChat.fetchRequest()
        
        var chatCount = 0
        do {
            chatCount = try context.count(for: fetchRequest)
        } catch {
            print("Failed to fetch chat count: \(error)")
        }
        
        // Create new SingleChat instance
        let newChat = SingleChat(context: context)
        newChat.id = UUID()
        newChat.name = "Name\(chatCount + 1)" // Automatically set name based on chat count
        newChat.model = model
        newChat.createdAt = Date()
        newChat.messages = messages
        
        return newChat
    }
}
