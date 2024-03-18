//
//  String+Extensions.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/11/22.
//

import Foundation

// MARK: - Native Redirect Helpers

private let nativeRedirectPrefix = "stripe-auth://native-redirect/"

extension String {

    func dropPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }

    func droppingNativeRedirectPrefix() -> String {
        return dropPrefix(nativeRedirectPrefix)
    }

    var hasNativeRedirectPrefix: Bool {
        return self.hasPrefix(nativeRedirectPrefix)
    }
}

// MARK: - Markdown Links

extension String {

    struct Link: Equatable {
        let range: NSRange
        let urlString: String
    }

    /// Extracts markdown links from a string.
    ///
    /// For example, `You can [visit](https://stripe.com/) the website` returns
    /// "You can visit the website" with a `Link` of "https://stripe.com/".
    func extractLinks() -> (linklessString: String, links: [Link]) {

        let originalString = self
        guard
            // Matches markdown links. For example, the regex will find all
            // occurrances of tokens like: `[Stripe Link Here](https://stripe.com/)`
            let regularExpression = try? NSRegularExpression(
                pattern: #"\[[^\[]*]*\]\([^\)]*\)"#,
                options: NSRegularExpression.Options(rawValue: 0)
            )
        else {
            return (originalString, [])
        }

        var modifiedString = originalString
        var links: [Link] = []
        while let textCheckingResult = regularExpression.firstMatch(
            in: modifiedString,
            range: NSRange(location: 0, length: modifiedString.count)
        ) {
            let markdownLinkRange = textCheckingResult.range
            // Ex. [Terms](https://stripe.com/legal/end-users#linked-financial-account-terms)
            let markdownLinkString = (modifiedString as NSString).substring(with: markdownLinkRange)

            var replacementString = ""
            if
                let linkSubstring = markdownLinkString.extractStringInBrackets(),
                let urlString = markdownLinkString.extractStringInParentheses()
            {
                // `nonBreakingSpace` ensures links are always on the same line
                let nonBreakingSpace = "\u{00a0}"
                let linkSubstring = linkSubstring.replacingOccurrences(
                    of: " ",
                    with: nonBreakingSpace
                )
                replacementString = linkSubstring
                let linkRange = NSRange(
                    location: markdownLinkRange.location,
                    length: linkSubstring.count
                )
                let link = Link(range: linkRange, urlString: urlString)
                links.append(link)
            }

            modifiedString = (modifiedString as NSString).replacingCharacters(
                in: markdownLinkRange,
                with: replacementString
            )
        }

        return (modifiedString, links)
    }

    /// Extracts a substring out of the first bracket.
    ///
    /// For example,  `Terms` out of `[Terms]`.
    private func extractStringInBrackets() -> String? {
        guard
            let regularExpression = try? NSRegularExpression(
                pattern: #"(?<=\[)[^\[\n]*(?=\])"#,
                options: NSRegularExpression.Options(rawValue: 0)
            )
        else {
            return nil
        }
        guard let range = regularExpression.firstMatch(in: self, range: NSRange(location: 0, length: count))?.range
        else {
            return nil
        }
        return (self as NSString).substring(with: range)
    }

    /// Extracts a substring out of the first parantheses.
    ///
    /// For example, `https://stripe.com/` out of `(https://stripe.com/)`.
    private func extractStringInParentheses() -> String? {
        guard
            let regularExpression = try? NSRegularExpression(
                pattern: #"(?<=\()[^\)\(\n]*(?=\))"#,
                options: NSRegularExpression.Options(rawValue: 0)
            )
        else {
            return nil
        }
        guard let range = regularExpression.firstMatch(in: self, range: NSRange(location: 0, length: count))?.range
        else {
            return nil
        }
        return (self as NSString).substring(with: range)
    }
}
