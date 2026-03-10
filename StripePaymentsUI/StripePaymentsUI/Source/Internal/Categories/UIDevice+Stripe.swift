import UIKit

extension UIDevice {
    /// On iPad with iOS 26+, `.asciiCapableNumberPad` triggers a floating popover keyboard
    /// that is awkward for card entry. Use `.numbersAndPunctuation` instead, which presents
    /// a full keyboard with the numbers row visible.
    var shouldAvoidNumericKeyboard: Bool {
        if #available(iOS 26, *) {
            return userInterfaceIdiom == .pad
        }
        return false
    }
}
