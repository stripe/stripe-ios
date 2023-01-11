//
//  String+AutoComplete.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 6/13/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

extension String {
    func highlightSearchString(highlightRanges: [NSValue], textStyle: UIFont.TextStyle, appearance: PaymentSheet.Appearance, isSubtitle: Bool) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: self)

        attributedString.addAttribute(
            NSAttributedString.Key.font,
            value: appearance.scaledFont(for: appearance.font.base.regular, style: textStyle, maximumPointSize: 25),
            range: (self as NSString).range(of: self))

        attributedString.addAttribute(
            NSAttributedString.Key.foregroundColor,
            value: isSubtitle ? appearance.colors.textSecondary : appearance.colors.text,
            range: (self as NSString).range(of: self))

        for highlightRange in highlightRanges {
            attributedString.addAttribute(
                NSAttributedString.Key.font,
                value: appearance.scaledFont(for: appearance.font.base.bold, style: textStyle, maximumPointSize: 25),
                range: highlightRange.rangeValue)
        }

        return attributedString
    }
}

// https://gist.github.com/RuiCarneiro/82bf91214e3e09222233b1fc04139c86
extension String {
    subscript(index: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: index)]
    }
}

extension String {
    public func editDistance(to other: String) -> Int {
        let sCount = self.count
        let oCount = other.count

        guard sCount != 0 else {
            return oCount
        }

        guard oCount != 0 else {
            return sCount
        }

        let line: [Int]  = Array(repeating: 0, count: oCount + 1)
        var mat: [[Int]] = Array(repeating: line, count: sCount + 1)

        for i in 0...sCount {
            mat[i][0] = i
        }

        for j in 0...oCount {
            mat[0][j] = j
        }

        for j in 1...oCount {
            for i in 1...sCount {
                if self[i - 1] == other[j - 1] {
                    mat[i][j] = mat[i - 1][j - 1]       // no operation
                } else {
                    let del = mat[i - 1][j] + 1         // deletion
                    let ins = mat[i][j - 1] + 1         // insertion
                    let sub = mat[i - 1][j - 1] + 1     // substitution
                    mat[i][j] = min(min(del, ins), sub)
                }
            }
        }

        return mat[sCount][oCount]
    }
}
