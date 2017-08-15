/*:
 # UI Examples Playground
 
 Switch Xcode to show the assistant editor (cmd-opt-return), and make sure it's showing the timeline, so you
 can see a live view of the text field as you make changes to its properties.
 ## Import the Stripe Framework
 
 If this fails, you'll need to build the `UI Examples` application for simulator once.
 */
import Stripe

/*:
 ## Create STPPaymentCardTextField
 
 
 */
// We'll use Auto-layout to size and position the view in the superview, so frame doesn't matter.
let textField = STPPaymentCardTextField(frame: CGRect.zero)
textField.translatesAutoresizingMaskIntoConstraints = false

/*:
 ## Customize STPPaymentCardTextField
 
 You can change the font & colors used
 */
// The font used in each child field. Default is [UIFont systemFontOfSize:18].
textField.font = .systemFont(ofSize: 18.0)

// The text color to be used when entering valid text. Default is [UIColor blackColor].
textField.textColor = .black

// The text color to be used when the user has entered invalid information, such as an
// invalid card number.
textField.textErrorColor = .red

// The text placeholder color used in each child field.
// This will also set the color of the card placeholder icon.
textField.placeholderColor = .lightGray

// The cursor color for the field.
// This is a proxy for the view's tintColor property, exposed for clarity only
// (in other words, calling setCursorColor is identical to calling setTintColor).
textField.cursorColor = nil

/*:
 You can adjust the border.
 
 Note: STPPaymentCardTextField integrates with the UIAppearance protocol for many appearance
 properties, so you can customize *all* instances in one place. The font/color customization could
 have also been done via the proxy.
 */
let proxy = STPPaymentCardTextField.appearance()
proxy.borderColor = .lightGray
proxy.borderWidth = 1.0
proxy.cornerRadius = 5.0

/*:
 You can control the placeholder text.
 */
textField.numberPlaceholder = "4242424242424242"
textField.expirationPlaceholder = "MM/YY"
textField.cvcPlaceholder = "CVC"
textField.postalCodePlaceholder = "Postal"

/*:
 You can turn on Postal Code entry, and optionally specify the country.
 
 It's off by default.
 */
textField.postalCodeEntryEnabled = false
textField.countryCode = NSLocale.current.regionCode

/*:
 There are other customization options available, please see STPPaymentCardTextField.h

 ## Set up STPPaymentCardTextFieldDelegate
 
 There are 5 pairs of `...DidBeginEditing...` and `...DidEndEditing...` methods, one for the whole text
 field, and one for each of the 4 embedded text fields (card number, expiration, CVC, and postal code).
 
 There is also a single `paymentCardTextFieldDidChange` method for changes in any of the text
 fields.
 */
// This delegate class just logs when the methods are called.
class MySTPPaymentCardTextFieldDelegate: NSObject, STPPaymentCardTextFieldDelegate {
    func paymentCardTextFieldDidChange(_ textField: STPPaymentCardTextField) {
        // You might enable/disable your 'Submit' based on isValid
        if textField.isValid {
            print("Valid payment card information entered",
                  textField.cardNumber!,
                  textField.expirationMonth, textField.expirationYear,
                  textField.cvc!,
                  textField.postalCode)
        }
    }
    
    func paymentCardTextFieldDidBeginEditing(_ textField: STPPaymentCardTextField) {
        print(textField, "paymentCardTextFieldDidBeginEditing")
    }
    
    // Implement any other delegate methods you're interested in.
}
let myDelegate = MySTPPaymentCardTextFieldDelegate()
textField.delegate = myDelegate

/*:
 ## Display STPPaymentCardTextField in the Playground
 
 This is just for demo purposes.
 */
let container = ContainerView(textField)
import PlaygroundSupport
PlaygroundPage.current.liveView = container
textField.becomeFirstResponder() // Activate the text field

//: [Next Page: STPAddCardViewController](@next)
