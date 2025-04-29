//
//  ThinkBlockParser.swift
//  OllamaChat
//
//  Created by Roger on 2025/4/29.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import SwiftUI

class ThinkBlockParser {
    static func parse(markdownString: String) -> (thinkContent: String, remainingContent: String, isIncomplete: Bool) {
        // Look for opening tag
        let openingPattern = "<think>"
        let closingPattern = "</think>"
        
        guard markdownString.contains(openingPattern) else {
            return ("", markdownString, false)
        }
        
        // Check if the closing tag is missing (incomplete think block)
        let hasClosingTag = markdownString.contains(closingPattern)
        
        if hasClosingTag {
            // Complete think block - extract as before
            let thinkPattern = "<think>(.*?)</think>"
            
            guard
                let regex = try? NSRegularExpression(
                    pattern: thinkPattern,
                    options: [.dotMatchesLineSeparators]
                ),
                let match = regex.firstMatch(
                    in: markdownString,
                    range: NSRange(markdownString.startIndex..., in: markdownString)
                )
            else {
                return ("", markdownString, false)
            }
            
            let thinkRange = Range(match.range(at: 1), in: markdownString)!
            let thinkContent = String(markdownString[thinkRange]).trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            
            let remainingRange = markdownString.startIndex..<markdownString.endIndex
            var remainingContent = markdownString
            if let matchRange = Range(match.range, in: markdownString) {
                remainingContent = String(
                    markdownString[remainingRange].replacingCharacters(in: matchRange, with: "")
                )
            }
            
            return (thinkContent, remainingContent.trimmingCharacters(in: .whitespacesAndNewlines), false)
        } else {
            // Incomplete think block - extract what's available so far
            if let openingTagRange = markdownString.range(of: openingPattern) {
                let startIndex = markdownString.index(openingTagRange.upperBound, offsetBy: 0)
                let thinkContent = String(markdownString[startIndex...]).trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                
                // For incomplete think blocks, the remaining content is empty because 
                // we're still in the thinking phase
                return (thinkContent, "", true)
            }
            
            return ("", markdownString, false)
        }
    }
}
