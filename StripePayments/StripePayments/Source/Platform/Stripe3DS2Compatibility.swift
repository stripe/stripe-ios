#if !canImport(Stripe3DS2)
#if canImport(AppKit)
import AppKit
#endif
import Foundation
@_spi(STP) import StripeCore

@objc public enum STDSButtonTitleStyle: Int {
    case `default`
    case uppercase
    case lowercase
    case sentenceCapitalized
}

@objc public enum STDSUICustomizationButtonType: Int {
    case submit
    case `continue`
    case next
    case cancel
    case resend
}

@objcMembers public class STDSButtonCustomization: NSObject {
    public var backgroundColor: UIColor
    public var cornerRadius: CGFloat
    public var titleStyle: STDSButtonTitleStyle = .default
    public var font: UIFont?
    public var textColor: UIColor?

    public init(backgroundColor: UIColor = .blue, cornerRadius: CGFloat = 8) {
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
    }

    public static func defaultSettings(
        for type: STDSUICustomizationButtonType
    ) -> STDSButtonCustomization {
        switch type {
        case .cancel, .resend:
            return STDSButtonCustomization(backgroundColor: .clear, cornerRadius: 8)
        case .submit, .continue, .next:
            return STDSButtonCustomization(backgroundColor: .blue, cornerRadius: 8)
        }
    }
}

@objcMembers public class STDSNavigationBarCustomization: NSObject {
    public var barTintColor: UIColor?
    public var barStyle: UIBarStyle = .default
    public var translucent = false
    public var headerText: String = ""
    public var buttonText: String = ""
    public var font: UIFont?
    public var textColor: UIColor?

    public static func defaultSettings() -> STDSNavigationBarCustomization {
        STDSNavigationBarCustomization()
    }
}

@objcMembers public class STDSLabelCustomization: NSObject {
    public var headingFont: UIFont = .systemFont(ofSize: 17)
    public var headingTextColor: UIColor = .black
    public var font: UIFont?
    public var textColor: UIColor?

    public static func defaultSettings() -> STDSLabelCustomization {
        STDSLabelCustomization()
    }
}

@objcMembers public class STDSTextFieldCustomization: NSObject {
    public var borderWidth: CGFloat = 2
    public var borderColor: UIColor = .clear
    public var cornerRadius: CGFloat = 8
    public var keyboardAppearance: UIKeyboardAppearance = .default
    public var placeholderTextColor: UIColor = .lightGray
    public var font: UIFont?
    public var textColor: UIColor?

    public static func defaultSettings() -> STDSTextFieldCustomization {
        STDSTextFieldCustomization()
    }
}

@objcMembers public class STDSFooterCustomization: NSObject {
    public var backgroundColor: UIColor = .white
    public var chevronColor: UIColor = .black
    public var headingTextColor: UIColor = .black
    public var headingFont: UIFont = .systemFont(ofSize: 17)
    public var font: UIFont?
    public var textColor: UIColor?

    public static func defaultSettings() -> STDSFooterCustomization {
        STDSFooterCustomization()
    }
}

@objcMembers public class STDSSelectionCustomization: NSObject {
    public var primarySelectedColor: UIColor = .blue
    public var secondarySelectedColor: UIColor = .white
    public var unselectedBackgroundColor: UIColor = .clear
    public var unselectedBorderColor: UIColor = .gray

    public static func defaultSettings() -> STDSSelectionCustomization {
        STDSSelectionCustomization()
    }
}

@objcMembers public class STDSUICustomization: NSObject {
    public var navigationBarCustomization = STDSNavigationBarCustomization.defaultSettings()
    public var labelCustomization = STDSLabelCustomization.defaultSettings()
    public var textFieldCustomization = STDSTextFieldCustomization.defaultSettings()
    public var footerCustomization = STDSFooterCustomization.defaultSettings()
    public var selectionCustomization = STDSSelectionCustomization.defaultSettings()
    public var backgroundColor: UIColor = .white
    public var activityIndicatorViewStyle: UIActivityIndicatorView.Style = .medium
    public var blurStyle: UIBlurEffect.Style = .light
    private var buttons: [STDSUICustomizationButtonType: STDSButtonCustomization] = [:]

    public static func defaultSettings() -> STDSUICustomization {
        STDSUICustomization()
    }

    public func setButton(
        _ buttonCustomization: STDSButtonCustomization,
        for type: STDSUICustomizationButtonType
    ) {
        buttons[type] = buttonCustomization
    }
}

@objcMembers public class STDSConfigParameters: NSObject {
    private var parameters: [String: String] = [:]

    public func addParameterNamed(_ name: String, withValue value: String) {
        parameters[name] = value
    }
}

@objcMembers public class STDSAuthenticationRequestParameters: NSObject { }

@objcMembers public class STDSAuthenticationResponse: NSObject {
    public var isChallengeRequired = false
}

public func STDSAuthenticationResponseFromJSON(
    _ json: [AnyHashable: Any]
) -> STDSAuthenticationResponse? {
    STDSAuthenticationResponse()
}

@objcMembers public class STDSChallengeParameters: NSObject {
    public init(authenticationResponse: STDSAuthenticationResponse) { }
}

@objcMembers public class STDSCompletionEvent: NSObject {
    public var transactionStatus: String

    public init(transactionStatus: String = "N") {
        self.transactionStatus = transactionStatus
    }
}

@objcMembers public class STDSProtocolErrorMessage: NSObject {
    public func nsErrorValue() -> NSError {
        NSError.stp_genericErrorOccurredError()
    }
}

@objcMembers public class STDSProtocolErrorEvent: NSObject {
    public var errorMessage = STDSProtocolErrorMessage()
}

@objcMembers public class STDSRuntimeErrorEvent: NSObject {
    public func nsErrorValue() -> NSError {
        NSError.stp_genericErrorOccurredError()
    }
}

@objcMembers public class STDSTransaction: NSObject {
    public var presentedChallengeUIType: String = "none"

    public func createAuthenticationRequestParameters() -> STDSAuthenticationRequestParameters {
        STDSAuthenticationRequestParameters()
    }

    public func doChallenge(
        with challengeParameters: STDSChallengeParameters,
        challengeStatusReceiver: AnyObject,
        timeout: TimeInterval,
        presentationHandler: (UIViewController, @escaping () -> Void) -> Void
    ) {
    }

    public func doChallenge(
        with presentingViewController: UIViewController,
        challengeParameters: STDSChallengeParameters,
        challengeStatusReceiver: AnyObject,
        timeout: TimeInterval
    ) {
    }

    public func close() {
    }

    public func cancelChallengeFlow() {
    }
}

@objcMembers public class STDSThreeDS2Service: NSObject {
    public func initialize(
        withConfig config: STDSConfigParameters,
        locale: Locale,
        uiSettings: STDSUICustomization
    ) {
    }

    public func createTransaction(
        forDirectoryServer directoryServerID: String,
        serverKeyID: String?,
        certificateString: String,
        rootCertificateStrings: [String],
        withProtocolVersion protocolVersion: String
    ) -> STDSTransaction {
        STDSTransaction()
    }
}

public enum STDSSwiftTryCatch {
    public static func `try`(
        _ tryBlock: () -> Void,
        catch catchBlock: (NSException) -> Void,
        finallyBlock: () -> Void
    ) {
        tryBlock()
        finallyBlock()
    }
}

public enum STDSJSONEncoder {
    public static func dictionary(
        forObject object: STDSAuthenticationRequestParameters
    ) -> [String: Any] {
        [:]
    }
}
#endif
