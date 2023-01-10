//
//  TextFieldFormatter.swift
//  StripeUICore
//
//  Created by Mel Ludowise on 9/28/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

struct TextFieldFormatter {

    // NOTE(mludowise): If we ever have a case where we need to display `#` or `*`
    // inside a formatted string, we should probably change `format` to something
    // more structured other than a `String`.

    static let redactedNumberCharacter: Character = "•"
    static let digitPatternCharacter: Character = "#"
    static let letterPatternCharacter: Character = "*"

    private let format: String

    /**
     - Parameters:
       - format: Consists of a string using pound signs `#`for numeric placeholders, and asterisks `*` for letters.

     - Note: Returns nil if the given format is invalid and doesn't contain any `#` or `*` characters.
     */
    init?(format: String) {
        guard format.contains(TextFieldFormatter.letterPatternCharacter) ||
                format.contains(TextFieldFormatter.digitPatternCharacter) else {
            return nil
        }
        self.format = format
    }

    /**
     Applies a format to `input`.

     - Note:
     If `input` doesn't contain enough characters to fill-in the placeholders, a partially formatted string
     will be returned. In the case of `input` containing more characters than expected, it will be truncated
     to the max length allowed by the format.

     - Parameters:
       - input: Content to be formatted.
       - appendRemaining: Set to true if any remaining characters in input after filling the pattern should be added as a suffix

     - Returns: The resulting formatted string.
     */
    func applyFormat(to input: String, shouldAppendRemaining: Bool = false) -> String {
        var result: [Character] = []

        var cursor = input.startIndex

        /*
         Buffer of characters that will get appended to the result only if there
         are more consumable characters (`*` or `#`). This prevents adding
         formatted characters to the end of the string, which can break the
         TextFieldView's backspace behavior when updating cursor position after
         formatted characters.
         */
        var resultBuffer: [Character] = []

        for token in format {
            guard cursor < input.endIndex else {
                break
            }

            repeat {
                var consumeInput = false
                if token == TextFieldFormatter.digitPatternCharacter,
                    (input[cursor].isNumber || input[cursor] == TextFieldFormatter.redactedNumberCharacter) {
                    consumeInput = true
                    resultBuffer.append(input[cursor])
                } else if token == TextFieldFormatter.letterPatternCharacter,
                            input[cursor].isLetter {
                    consumeInput = true
                    resultBuffer.append(input[cursor])
                }

                if consumeInput {
                    // Consume a character from the input
                    result += resultBuffer
                    resultBuffer = []
                    cursor = input.index(after: cursor)
                    break
                }

                if token == TextFieldFormatter.digitPatternCharacter ||
                        token == TextFieldFormatter.letterPatternCharacter {
                    // Discard unmatched token
                    cursor = input.index(after: cursor)
                } else {
                    resultBuffer.append(token)
                    break
                }
            } while cursor < input.endIndex
        }

        if shouldAppendRemaining,
           cursor < input.endIndex {
            result += " " + String(input[cursor...])
        }

        return String(result)
    }
}
