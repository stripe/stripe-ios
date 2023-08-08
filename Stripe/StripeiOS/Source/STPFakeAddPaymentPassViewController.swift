//
//  STPFakeAddPaymentPassViewController.swift
//  StripeiOS
//
//  Created by Jack Flintermann on 9/28/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import PassKit
@_spi(STP) import StripeCore
import UIKit

/// This class is a piece of fake UI that is intended to mimic `PKAddPaymentPassViewController`. That class is restricted to apps with a special entitlement from Apple, and as such can be difficult to build and test against. This class implements the same public API as `PKAddPaymentPassViewController`, and can be used to develop against the Stripe API in *testmode only*. (Obviously it will not actually place cards into the user's Apple Pay wallet either.) When it's time to go to production, you may simply replace all references to `STPFakeAddPaymentPassViewController` in your app with `PKAddPaymentPassViewController` and it will continue to function. For more information on developing against this API, please see https://stripe.com/docs/issuing/cards/digital-wallets .
public class STPFakeAddPaymentPassViewController: UIViewController {
    /// @see PKAddPaymentPassViewController
    @objc
    public class func canAddPaymentPass() -> Bool {
        return true
    }

    /// @see PKAddPaymentPassViewController
    @objc(initWithRequestConfiguration:delegate:)
    public required init?(
        requestConfiguration configuration: PKAddPaymentPassRequestConfiguration,
        delegate: PKAddPaymentPassViewControllerDelegate?
    ) {
        super.init(nibName: nil, bundle: nil)
        assert(delegate != nil, "Invalid parameter not satisfying: delegate != nil")
        state = .initial
        self.delegate = delegate
        self.configuration = configuration
        if configuration.primaryAccountSuffix == nil && configuration.cardholderName == nil {
            assert(
                false,
                "Your PKAddPaymentPassRequestConfiguration must provide either a cardholderName or a primaryAccountSuffix."
            )
        }
    }

    /// @see PKAddPaymentPassViewController
    @objc public weak var delegate: PKAddPaymentPassViewControllerDelegate?
    private var configuration: PKAddPaymentPassRequestConfiguration?

    private var _state: STPFakeAddPaymentPassViewControllerState = .initial
    private var state: STPFakeAddPaymentPassViewControllerState {
        get {
            _state
        }
        set(state) {
            _state = state
            let cancelItem = UIBarButtonItem(
                barButtonSystemItem: .cancel,
                target: self,
                action: #selector(cancel(_:))
            )
            let nextButton = UIButton(type: .system)
            nextButton.addTarget(self, action: #selector(next(_:)), for: .touchUpInside)
            let indicatorView = UIActivityIndicatorView(style: .medium)
            indicatorView.startAnimating()
            let loadingItem = UIBarButtonItem(customView: indicatorView)
            nextButton.setTitle(STPNonLocalizedString("Next"), for: .normal)
            let nextItem = UIBarButtonItem(customView: nextButton)
            let doneItem = UIBarButtonItem(
                barButtonSystemItem: .done,
                target: self,
                action: #selector(done(_:))
            )

            switch state {
            case .initial:
                contentLabel?.text = STPNonLocalizedString(
                    "This class simulates the delegate methods that PKAddPaymentPassViewController will call in your app. Press next to continue."
                )
                navigationItem.leftBarButtonItem = cancelItem
                navigationItem.rightBarButtonItem = nextItem
            case .loading:
                contentLabel?.text = STPNonLocalizedString("Fetching encrypted card details...")
                cancelItem.isEnabled = false
                navigationItem.leftBarButtonItem = cancelItem
                navigationItem.rightBarButtonItem = loadingItem
            case .error:
                contentLabel?.text = STPNonLocalizedString("Error: " + (errorText ?? ""))
                doneItem.isEnabled = false
                navigationItem.leftBarButtonItem = cancelItem
                navigationItem.rightBarButtonItem = doneItem
            case .success:
                contentLabel?.text = STPNonLocalizedString(
                    "Success! In production, your card would now have been added to your Apple Pay wallet. Your app's success callback will be triggered when the user presses 'Done'."
                )
                cancelItem.isEnabled = false
                navigationItem.leftBarButtonItem = cancelItem
                navigationItem.rightBarButtonItem = doneItem
            }
        }
    }
    private var contentLabel: UILabel?
    private var errorText: String?

    /// :nodoc:
    @objc public convenience override init(
        nibName nibNameOrNil: String?,
        bundle nibBundleOrNil: Bundle?
    ) {
        self.init(requestConfiguration: PKAddPaymentPassRequestConfiguration(), delegate: nil)!
    }

    /// :nodoc:
    @objc public required convenience init?(
        coder aDecoder: NSCoder
    ) {
        self.init(requestConfiguration: PKAddPaymentPassRequestConfiguration(), delegate: nil)
    }

    /// :nodoc:
    @objc
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white

        let navBar = UINavigationBar()
        view.addSubview(navBar)
        navBar.isTranslucent = false
        navBar.backgroundColor = UIColor.white
        navBar.items = [navigationItem]
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        navBar.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true

        let contentLabel = UILabel(frame: CGRect.zero)
        self.contentLabel = contentLabel
        contentLabel.textAlignment = .center
        contentLabel.textColor = UIColor.black
        contentLabel.numberOfLines = 0
        contentLabel.font = UIFont.systemFont(ofSize: 18)
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentLabel)
        contentLabel.topAnchor.constraint(equalTo: navBar.bottomAnchor).isActive = true
        contentLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 10.0).isActive = true
        contentLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -10.0).isActive =
            true
        contentLabel.heightAnchor.constraint(equalToConstant: 150).isActive = true

        var pairs: [AnyHashable] = []
        if configuration?.cardholderName != nil {
            pairs.append(["Name", configuration?.cardholderName])
        }
        if configuration?.primaryAccountSuffix != nil {
            pairs.append([
                "Card Number",
                "···· \(configuration?.primaryAccountSuffix ?? "")",
            ])
        }
        var rows: [AnyHashable] = []
        for pair in pairs {
            guard let pair = pair as? [AnyHashable] else {
                continue
            }
            let left = UILabel()
            left.text = pair[0] as? String
            left.textAlignment = .left
            left.font = UIFont.boldSystemFont(ofSize: 16)
            let right = UILabel()
            right.text = pair[1] as? String
            right.textAlignment = .left
            right.textColor = UIColor.lightGray
            let row = UIStackView(arrangedSubviews: [left, right])
            row.axis = .horizontal
            row.distribution = .fillEqually
            row.alignment = .fill
            row.translatesAutoresizingMaskIntoConstraints = false
            rows.append(row)
        }
        var pairsTable: UIStackView?
        if let rows = rows as? [UIView] {
            pairsTable = UIStackView(arrangedSubviews: rows)
        }
        pairsTable?.isLayoutMarginsRelativeArrangement = true
        pairsTable?.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        pairsTable?.axis = .vertical
        pairsTable?.translatesAutoresizingMaskIntoConstraints = false
        if let pairsTable = pairsTable {
            view.addSubview(pairsTable)
        }

        pairsTable?.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        pairsTable?.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        pairsTable?.topAnchor.constraint(equalTo: contentLabel.bottomAnchor).isActive = true
        pairsTable?.heightAnchor.constraint(equalToConstant: CGFloat((rows.count * 50))).isActive =
            true
        state = .initial
    }

    @objc func cancel(_ sender: Any?) {
        let castedVC = unsafeBitCast(self, to: PKAddPaymentPassViewController.self)
        delegate?.addPaymentPassViewController(
            castedVC,
            didFinishAdding: nil,
            error: NSError(
                domain: PKPassKitErrorDomain,
                code: PKAddPaymentPassError.userCancelled.rawValue,
                userInfo: nil
            )
        )
    }

    @objc func next(_ sender: Any?) {
        state = .loading
        let certificates = [
            "cert1".data(using: .utf8),
            "cert2".data(using: .utf8),
        ]
        let nonce = "nonce".data(using: .utf8)
        let nonceSignature = "nonceSignature".data(using: .utf8)

        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(10 * Double(NSEC_PER_SEC)))
                / Double(NSEC_PER_SEC),
            execute: {
                if self.state == .loading {
                    self.errorText =
                        "You exceeded the timeout of 10 seconds to call the request completion handler. Please check your PKAddPaymentPassViewControllerDelegate implementation, and make sure you are calling the `completionHandler` in `addPaymentPassViewController:generateRequestWithCertificateChain:nonce:nonceSignature:completionHandler`."
                    self.state = .error
                }
            }
        )
        if let nonce = nonce, let nonceSignature = nonceSignature {
            let castedVC = unsafeBitCast(self, to: PKAddPaymentPassViewController.self)
            delegate?.addPaymentPassViewController(
                castedVC,
                generateRequestWithCertificateChain: certificates.compactMap { $0 },
                nonce: nonce,
                nonceSignature: nonceSignature,
                completionHandler: { request in
                    if self.state == .loading {
                        var contents: String?
                        if request.encryptedPassData != nil {
                            if let encryptedPassData1 = request.encryptedPassData {
                                contents = String(data: encryptedPassData1, encoding: .utf8)
                            }
                        }
                        if request.stp_error != nil {
                            var error =
                                (request.stp_error as NSError?)?.userInfo[STPError.errorMessageKey]
                                as? String
                            if error == nil {
                                error =
                                    (request.stp_error as NSError?)?.userInfo[
                                        NSLocalizedDescriptionKey
                                    ] as? String
                            }
                            self.errorText = error
                            self.state = .error
                        } else if contents == "TESTMODE_CONTENTS" {
                            self.state = .success
                        } else {
                            self.errorText =
                                "Your server response contained the wrong encrypted card details. Please ensure that you are not modifying the response from the Stripe API in any way, and that your request is in testmode."
                            self.state = .error
                        }
                    }
                }
            )
        }
    }

    @objc func done(_ sender: Any?) {
        let pass = PKPaymentPass()
        let castedVC = unsafeBitCast(self, to: PKAddPaymentPassViewController.self)
        delegate?.addPaymentPassViewController(castedVC, didFinishAdding: pass, error: nil)
    }
}

enum STPFakeAddPaymentPassViewControllerState: Int {
    case initial
    case loading
    case error
    case success
}
