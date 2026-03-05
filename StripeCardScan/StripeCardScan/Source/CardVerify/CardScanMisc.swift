import Foundation

class CreditCard: NSObject {
    var number: String
    var expiryMonth: String?
    var expiryYear: String?
    var name: String?

    init(
        number: String
    ) {
        self.number = number
    }
}
