//
//  NonNameWords.swift
//  ocr-playground-ios
//
//  Created by Sam King on 3/23/20.
//  Copyright © 2020 Sam King. All rights reserved.
//

import Foundation

struct NameWords {
    static let blacklist: Set = [
        "customer", "debit", "visa", "mastercard", "navy", "american", "express", "thru", "good",
        "authorized", "signature", "wells", "navy", "credit", "federal",
        "union", "bank", "valid", "validfrom", "validthru", "llc", "business", "netspend",
        "goodthru", "chase", "fargo", "hsbc", "usaa", "chaseo", "commerce",
        "last", "of", "lastdayof", "check", "card", "inc", "first", "member", "since",
        "american", "express", "republic", "bmo", "capital", "one", "capitalone", "platinum",
        "expiry", "date", "expiration", "cash", "back", "td", "access", "international", "interac",
        "nterac", "entreprise", "business", "md", "enterprise", "fifth", "third", "fifththird",
        "world", "rewards", "citi", "member", "cardmember", "cardholder", "valued", "since",
        "membersince", "cardmembersince", "cardholdersince", "freedom", "quicksilver", "penfed",
        "use", "this", "card", "is", "subject", "to", "the", "inc", "not", "transferable", "gto",
        "mgy", "sign",
    ]

    static func nonNameWordMatch(_ text: String) -> Bool {
        let lowerCase = text.lowercased()
        return blacklist.contains(lowerCase)
    }

    static func onlyLettersAndSpaces(_ text: String) -> Bool {
        let lettersAndSpace = text.reduce(true) { acc, value in
            let capitalLetter = value >= "A" && value <= "Z"
            // for now we're only going to accept upper case names
            // let lowerCaseLetter = value >= "a" && value <= "z"
            let space = value == " "
            return acc && (capitalLetter || space)
        }

        return lettersAndSpace
    }
}
