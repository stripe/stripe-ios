//
//  OneTimeCodeTextField-TextStorage.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 3/29/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

extension OneTimeCodeTextField {
    final class TextStorage {
        var value: String = ""

        let capacity: Int

        var start: TextPosition {
            return TextPosition(0)
        }

        var end: TextPosition {
            return TextPosition(value.count)
        }

        /// Returns a range for placing the caret at the end of the content.
        ///
        /// A zero-length range is `UITextInput`'s way of representing the caret position. This property will
        /// always return a zero-length range at the end of the content.
        var endCaretRange: TextRange {
            return TextRange(start: end, end: end)
        }

        /// A range that covers from the beginning to the end of the content.
        var extent: TextRange {
            return TextRange(start: start, end: end)
        }

        var isFull: Bool {
            return value.count >= capacity
        }

        private let allowedCharacters: CharacterSet = .init(charactersIn: "0123456789")

        init(capacity: Int) {
            assert(capacity >= 0, "Cannot have a negative capacity")
            self.capacity = max(capacity, 0)
        }

        func insert(_ text: String, at range: TextRange) -> TextRange {
            let sanitizedText = text.filter({
                $0.unicodeScalars.allSatisfy(allowedCharacters.contains(_:))
            })

            value.replaceSubrange(range.stringRange(for: value), with: sanitizedText)

            if value.count > capacity {
                // Truncate to capacity
                value = String(value.prefix(capacity))
            }

            let newInsertionPoint = TextPosition(range._start.index + sanitizedText.count)
            return TextRange(start: newInsertionPoint, end: newInsertionPoint)
        }

        func delete(range: TextRange) -> TextRange {
            value.removeSubrange(range.stringRange(for: value))
            return TextRange(start: range._start, end: range._start)
        }

        func text(in range: TextRange) -> String? {
            guard !range.isEmpty else {
                return nil
            }

            let stringRange = range.stringRange(for: value)
            return String(value[stringRange])
        }

        /// Utility method for creating a text range.
        ///
        /// Returns `nil` if any of the given positions is out of bounds.
        ///
        /// - Parameters:
        ///   - start: Start position of the range.
        ///   - end: End position of the range.
        /// - Returns: Text position.
        func makeRange(from start: TextPosition, to end: TextPosition) -> TextRange? {
            guard
                extent.contains(start.index),
                extent.contains(end.index)
            else {
                return nil
            }

            return TextRange(start: start, end: end)
        }
    }
}

// MARK: - UITextPosition

extension OneTimeCodeTextField {
    /// Represents a position within our text storage.
    ///
    /// For internal SDK use only
    @objc(STP_Internal_OneTimeCodeTextField_TextPosition)
    final class TextPosition: UITextPosition {
        let index: Int

        init(_ index: Int) {
            self.index = index
        }

        override var description: String {
            let props: [String] = [
                String(format: "%@: %p", NSStringFromClass(type(of: self)), self),
                "index = \(String(describing: index))",
            ]
            return "<\(props.joined(separator: "; "))>"
        }

        override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? TextPosition else {
                return false
            }

            return self.index == other.index
        }

        func compare(_ otherPosition: TextPosition) -> ComparisonResult {
            if index < otherPosition.index {
                return .orderedAscending
            }

            if index > otherPosition.index {
                return .orderedDescending
            }

            return .orderedSame
        }
    }

}

// MARK: - TextRange

extension OneTimeCodeTextField {
    /// A range within our text storage.
    ///
    /// For internal SDK use only.
    @objc(STP_Internal_OneTimeCodeTextField_TextRange)
    final class TextRange: UITextRange {
        let _start: TextPosition
        let _end: TextPosition

        override var isEmpty: Bool {
            return _start.index == _end.index
        }

        override var start: UITextPosition {
            return _start
        }

        override var end: UITextPosition {
            return _end
        }

        convenience init?(start: UITextPosition, end: UITextPosition) {
            guard
                let start = start as? TextPosition,
                let end = end as? TextPosition
            else {
                return nil
            }

            self.init(start: start, end: end)
        }

        init(start: TextPosition, end: TextPosition) {
            self._start = start
            self._end = end
        }

        override var description: String {
            let props: [String] = [
                String(format: "%@: %p", NSStringFromClass(type(of: self)), self),
                "start = \(String(describing: start))",
                "end = \(String(describing: end))",
            ]
            return "<\(props.joined(separator: "; "))>"
        }

        override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? TextRange else {
                return false
            }

            return self.start == other.start && self.end == other.end
        }

        func contains(_ index: Int) -> Bool {
            let lowerBound = min(_start.index, _end.index)
            let upperBound = max(_start.index, _end.index)
            return index >= lowerBound && index <= upperBound
        }

        func stringRange(for string: String) -> Range<String.Index> {
            let lowerBound = min(_start.index, _end.index)
            let upperBound = max(_start.index, _end.index)

            let beginIndex = string.index(string.startIndex, offsetBy: min(lowerBound, string.count))
            let endIndex = string.index(string.startIndex, offsetBy: min(upperBound, string.count))

            return beginIndex..<endIndex
        }
    }
}
