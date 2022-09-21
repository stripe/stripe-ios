//
//  String+Extensions.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/11/22.
//

import Foundation


// MARK: - Markdown Bold

extension String {
    
    /// Extracts markdown "bold" from a string. Where "bold" is indicated by asterisks: `*bold string here*`.
    func extractMarkdownBold() -> (boldlessString: String, boldRanges: [NSRange]) {
        let originalString = self
        guard
            // Matches markdown "bold" asterisks. For example, the regex will find all
            // occurrances of tokens like: `*bold string here*`
            let regularExpression = try? NSRegularExpression(pattern: #"\*[^\*\n]*\*"#, options: NSRegularExpression.Options(rawValue: 0))
        else {
            return (originalString, [])
        }
        
        var modifiedString = originalString
        var ranges: [NSRange] = []
        while
            let textCheckingResult = regularExpression.firstMatch(
                in: modifiedString,
                range: NSRange(location: 0, length: modifiedString.count)
            )
        {
            let markdownBoldRange = textCheckingResult.range
            // Ex. `*bold string here*`
            let markdownBoldString = (modifiedString as NSString).substring(with: markdownBoldRange)
            
            var replacementString = ""
            if let substring = markdownBoldString.extractStringInAsterisks() {
                replacementString = substring
                ranges.append(NSRange(location: markdownBoldRange.location, length: substring.count))
            }
            
            modifiedString = (modifiedString as NSString).replacingCharacters(in: markdownBoldRange, with: replacementString)
        }
        
        return (modifiedString, ranges)
    }
    
    /// Extracts a substring out of the first asterisks.
    ///
    /// For example,  `bold string here` out of `*bold string here*`.
    private func extractStringInAsterisks() -> String? {
        guard
            let regularExpression = try? NSRegularExpression(pattern: #"(?<=\*)[^\*\n]*(?=\*)"#, options: NSRegularExpression.Options(rawValue: 0))
        else {
            return nil
        }
        guard let range = regularExpression.firstMatch(in: self, range: NSRange(location: 0, length: count))?.range else {
            return nil
        }
        return (self as NSString).substring(with: range)
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
            let regularExpression = try? NSRegularExpression(pattern: #"\[[^\[]*]*\]\([^\)]*\)"#, options: NSRegularExpression.Options(rawValue: 0))
        else {
            return (originalString, [])
        }
        
        var modifiedString = originalString
        var links: [Link] = []
        while
            let textCheckingResult = regularExpression.firstMatch(
                in: modifiedString,
                range: NSRange(location: 0, length: modifiedString.count)
            )
        {
            let markdownLinkRange = textCheckingResult.range
            // Ex. [Terms](https://stripe.com/legal/end-users#linked-financial-account-terms)
            let markdownLinkString = (modifiedString as NSString).substring(with: markdownLinkRange)
            
            var replacementString = ""
            if let substring = markdownLinkString.extractStringInBrackets(), let urlString = markdownLinkString.extractStringInParentheses() {
                replacementString = substring
                let linkRange = NSRange(location: markdownLinkRange.location, length: substring.count)
                let link = Link(range: linkRange, urlString: urlString)
                links.append(link)
            }
            
            modifiedString = (modifiedString as NSString).replacingCharacters(in: markdownLinkRange, with: replacementString)
        }
        
        return (modifiedString, links)
    }
    
    /// Extracts a substring out of the first bracket.
    ///
    /// For example,  `Terms` out of `[Terms]`.
    private func extractStringInBrackets() -> String? {
        guard
            let regularExpression = try? NSRegularExpression(pattern: #"(?<=\[)[^\[\n]*(?=\])"#, options: NSRegularExpression.Options(rawValue: 0))
        else {
            return nil
        }
        guard let range = regularExpression.firstMatch(in: self, range: NSRange(location: 0, length: count))?.range else {
            return nil
        }
        return (self as NSString).substring(with: range)
    }
    
    /// Extracts a substring out of the first parantheses.
    ///
    /// For example, `https://stripe.com/` out of `(https://stripe.com/)`.
    private func extractStringInParentheses() -> String? {
        guard
            let regularExpression = try? NSRegularExpression(pattern: #"(?<=\()[^\)\(\n]*(?=\))"#, options: NSRegularExpression.Options(rawValue: 0))
        else {
            return nil
        }
        guard let range = regularExpression.firstMatch(in: self, range: NSRange(location: 0, length: count))?.range else {
            return nil
        }
        return (self as NSString).substring(with: range)
    }
}
