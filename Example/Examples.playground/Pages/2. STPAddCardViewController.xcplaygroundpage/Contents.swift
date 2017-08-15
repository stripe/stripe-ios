/*:
 [Previous Page: STPPaymentCardTextField](@previous)

 ## Import the Stripe library
 */
import Stripe

/*:
 ## Set up the STPPaymentConfiguration

 As an alternative to configuring the `sharedConfiguration`, you could create one
 and pass it into the `STPAddCardViewController` initializer.

 This configuration, particularly the `publishableKey`, would make sense to do on
 application launch.
 */
let config = STPPaymentConfiguration.shared()

// Set publishable key
config.publishableKey = "pk_test_6pRNASCoBOKtIshFeQd4XMUh"

// Request the full billing address
config.requiredBillingAddressFields = .full

/*:
 ## Set up the STPTheme.

 As an alternative to configuring the `default` theme, you could create one
 and pass it into the `STPAddCardViewController` initializer.

 By setting up the default theme at launch time, you ensure all STP view controllers
 will share the same styling.
 */

let theme = STPTheme.default()

// Customize the theme a little.
// These are not recommended choices, and you can find more properties in the documentation.
theme.accentColor = UIColor.orange
theme.emphasisFont = UIFont(name: "Copperplate-Bold", size: 24.0)
theme.font = UIFont(name: "Copperplate", size: 24.0)

/*:
 ## Implement STPAddCardViewControllerDelegate methods

 This is an example delegate object that just logs when the methods are called.
 Yours will integrate with your view controller hierarchy and navigation scheme.
 */
class MyAddCardVCDelegate: NSObject, STPAddCardViewControllerDelegate {
    func addCardViewControllerDidCancel(_ vc: STPAddCardViewController) {
        print(vc, "addCardViewControllerDidCancel:")
        // VC needs to be dismissed
    }

    func addCardViewController(_ vc: STPAddCardViewController, didCreateToken token: STPToken, completion: @escaping STPErrorBlock) {
        print(vc, "addCardViewController:didCreateToken:completion:")
        print(token)

        // Token needs to be sent to the backend, the completion block called,
        // and the VC dismissed. This example just waits ~5 seconds.
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(5)) {
            completion(nil)
        }
    }
}
let myDelegate = MyAddCardVCDelegate()


/*:
 ## Create a STPAddCardViewController to display
 */
let addCardVC = STPAddCardViewController()

addCardVC.delegate = myDelegate

//: Pre-fill the billing address with information our fake app already knew.
let billingAddress = STPAddress()
billingAddress.line1 = "1234 Main Street"
billingAddress.city = "San Francisco"
billingAddress.state = "CA"
billingAddress.postalCode = "94107"
billingAddress.country = "US"

let prefilledInfo = STPUserInformation()
prefilledInfo.billingAddress = billingAddress
addCardVC.prefilledInformation = prefilledInfo


/*:
 ## Display STPAddCardViewController in UINavigationController

 The STPAddCardViewController would be shown as part of your app flow.
 */
let navVC = UINavigationController(rootViewController: addCardVC)
navVC.navigationBar.stp_theme = theme


// This shows it as the only view of the playground, for demo purposes
import PlaygroundSupport
PlaygroundPage.current.liveView = navVC.view

