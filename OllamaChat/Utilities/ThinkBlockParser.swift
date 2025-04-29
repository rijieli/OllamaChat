//
//  ThinkBlockParser.swift
//  OllamaChat
//
//  Created by Roger on 2025/4/29.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import SwiftUI

private let openThinkTagRegex: NSRegularExpression? = try? NSRegularExpression(
    pattern: "<think>",
    options: []
)

class ThinkBlockParser {
    private static let openTag = "<think>"
    private static let closeTag = "</think>"
    
    static func parse(markdownString: String) -> (thinkContent: String, remainingContent: String, isIncomplete: Bool) {
        // Fast path: Check if both tags exist using string operations
        guard let openRange = markdownString.range(of: openTag) else {
            return ("", markdownString, false)
        }
        
        if let closeRange = markdownString.range(of: closeTag) {
            // We have both tags - use string operations
            let startIndex = markdownString.index(openRange.upperBound, offsetBy: 0)
            let endIndex = closeRange.lowerBound
            
            let thinkContent = String(markdownString[startIndex..<endIndex])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Get remaining content by removing the whole think block
            let fullRange = openRange.lowerBound..<markdownString.index(closeRange.upperBound, offsetBy: 0)
            var remainingContent = markdownString
            remainingContent.removeSubrange(fullRange)
            
            return (thinkContent, remainingContent.trimmingCharacters(in: .whitespacesAndNewlines), false)
        }
        
        // Slow path: Incomplete block - use regex as fallback
        guard let openingMatch = openThinkTagRegex?.firstMatch(
            in: markdownString,
            range: NSRange(markdownString.startIndex..., in: markdownString)
        ) else {
            return ("", markdownString, false)
        }
        
        // Handle incomplete think block
        let openingTagRange = Range(openingMatch.range, in: markdownString)!
        let startIndex = markdownString.index(openingTagRange.upperBound, offsetBy: 0)
        let thinkContent = String(markdownString[startIndex...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return (thinkContent, "", true)
    }
}
