//
//  TextFieldFormatter.swift
//  StripeUICore
//
//  Created by Mel Ludowise on 9/28/21.
//

import Foundation

struct TextFieldFormatter {
    
    // NOTE(mludowise): If we ever have a case where we need to display `#` or `*`
    // inside a formatted string, we should probably change `format` to something
    // more structured other than a `String`.

    private let format: String

    /**
     - Parameters:
       - format: Consists of a string using pound signs `#`for numeric placeholders, and asterisks `*` for letters.

     - Note: Returns nil if the given format is invalid and doesn't contain any `#` or `*` characters.
     */
    init?(format: String) {
        guard format.contains("*") || format.contains("#") else {
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

     - Returns: The resulting formatted string.
     */
    func applyFormat(to input: String) -> String {
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
                if token == "#" && input[cursor].isNumber {
                    consumeInput = true
                    resultBuffer.append(input[cursor])
                } else if token == "*" && input[cursor].isLetter {
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

                if (token == "#" || token == "*") {
                    // Discard unmatched token
                    cursor = input.index(after: cursor)
                } else {
                    resultBuffer.append(token)
                    break
                }
            } while cursor < input.endIndex;
        }

        return String(result)
    }
}
