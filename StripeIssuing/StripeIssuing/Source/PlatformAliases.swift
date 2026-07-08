#if canImport(AppKit) && !canImport(UIKit)
import Foundation
import PassKit
@_spi(STP) import StripeUICore

public class PKAddPaymentPassRequestConfiguration: NSObject {
    public enum EncryptionScheme {
        case ECC_V2
    }

    public enum Style {
        case payment
    }

    public var cardholderName: String?
    public var localizedDescription: String?
    public var paymentNetwork: PKPaymentNetwork?
    public var primaryAccountIdentifier: String?
    public var primaryAccountSuffix: String?
    public var style = Style.payment

    public override init() {
        super.init()
    }

    public init?(encryptionScheme: EncryptionScheme) {
        super.init()
    }
}

public class PKAddPaymentPassRequest: NSObject {
    public var activationData: Data?
    public var encryptedPassData: Data?
    public var ephemeralPublicKey: Data?
}

public class PKPaymentPass: NSObject {
}

public class PKAddPaymentPassViewController: StripeUICore.UIViewController {
}

@objc public protocol PKAddPaymentPassViewControllerDelegate: AnyObject {
    func addPaymentPassViewController(
        _ controller: PKAddPaymentPassViewController,
        generateRequestWithCertificateChain certificates: [Data],
        nonce: Data,
        nonceSignature: Data,
        completionHandler handler: @escaping (PKAddPaymentPassRequest) -> Void
    )

    func addPaymentPassViewController(
        _ controller: PKAddPaymentPassViewController,
        didFinishAdding pass: PKPaymentPass?,
        error: Error?
    )
}

public let PKPassKitErrorDomain = "PKPassKitErrorDomain"

public enum PKAddPaymentPassError: Int {
    case userCancelled = 1
}
#endif
