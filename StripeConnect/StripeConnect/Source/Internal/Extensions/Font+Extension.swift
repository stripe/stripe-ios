//
//  Font+Extension.swift
//  StripeConnect
//
//  Created by Chris Mays on 9/16/24.
//

import UIKit

extension UIFont {
    var isItalic: Bool {
        fontDescriptor.symbolicTraits.contains(.traitItalic)
    }

    var weight: UIFont.Weight {
        if let traits = fontDescriptor.object(forKey: .traits) as? [UIFontDescriptor.TraitKey: Any],
           let rawWeight = traits[.weight] as? NSNumber {
            return UIFont.Weight(rawValue: CGFloat(rawWeight.floatValue))
        }

        // Fallback to checking weight on symbolic traits which is less precise.
        if fontDescriptor.symbolicTraits.contains(.traitBold) {
            return .bold
        }

        return .regular
    }

    var characterSet: CharacterSet? {
        fontDescriptor.fontAttributes[.characterSet] as? CharacterSet
        ?? CTFontCopyCharacterSet(self) as CharacterSet
    }
}
