//
//  STPBankSelectionViewController.swift
//  Stripe
//
//  Created by David Estes on 8/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import PassKit
import UIKit

/// The payment methods supported by STPBankSelectionViewController.
@objc public enum STPBankSelectionMethod: Int {
    /// FPX (Malaysia)
    case FPX
    /// An unknown payment method
    case unknown
}

/// This view controller displays a list of banks of the specified type, allowing the user to select one to pay from.
/// Once a bank is selected, it will return a PaymentMethodParams object, which you can use to confirm a PaymentIntent
/// or inspect to obtain details about the selected bank.
public class STPBankSelectionViewController: STPCoreTableViewController, UITableViewDataSource,
    UITableViewDelegate
{
    /// A convenience initializer; equivalent to calling `init( bankMethod:bankMethod configuration:STPPaymentConfiguration.shared theme:STPTheme.defaultTheme`.
    @objc
    public convenience init(bankMethod: STPBankSelectionMethod) {
        self.init(
            bankMethod: bankMethod, configuration: STPPaymentConfiguration.shared,
            theme: STPTheme.defaultTheme)
    }

    @objc public convenience required init(theme: STPTheme?) {
        self.init(
            bankMethod: .FPX, configuration: STPPaymentConfiguration.shared,
            theme: theme ?? .defaultTheme
        )
    }

    /// Initializes a new `STPBankSelectionViewController` with the provided configuration and theme. Don't forget to set the `delegate` property after initialization.
    /// - Parameters:
    ///   - bankMethod: The user will be presented with a list of banks for this payment method. STPBankSelectionMethodFPX is currently the only supported payment method.
    ///   - configuration: The configuration to use. This determines the Stripe publishable key to use when querying metadata about the banks. - seealso: STPPaymentConfiguration
    ///   - theme:         The theme to use to inform the view controller's visual appearance. - seealso: STPTheme
    @objc
    public init(
        bankMethod: STPBankSelectionMethod,
        configuration: STPPaymentConfiguration,
        theme: STPTheme
    ) {
        super.init(theme: theme)
        STPAnalyticsClient.sharedClient.addClass(
            toProductUsageIfNecessary: STPBankSelectionViewController.self)
        assert(bankMethod == .FPX, "STPBankSelectionViewController currently only supports FPX.")
        self.bankMethod = bankMethod
        self.configuration = configuration
        selectedBank = .unknown
        apiClient = STPAPIClient.shared
        if bankMethod == .FPX {
            _refreshFPXStatus()
            NotificationCenter.default.addObserver(
                self, selector: #selector(_refreshFPXStatus),
                name: UIApplication.didBecomeActiveNotification, object: nil)
        }
        title = STPLocalizationUtils.localizedBankAccountString()
    }

    /// The view controller's delegate. This must be set before showing the view controller in order for it to work properly. - seealso: STPBankSelectionViewControllerDelegate
    @objc public weak var delegate: STPBankSelectionViewControllerDelegate?
    /// The API Client to use to make requests.
    /// Defaults to `STPAPIClient.shared`
    @objc public var apiClient: STPAPIClient = .shared
    private var bankMethod: STPBankSelectionMethod = .unknown
    private var selectedBank: STPFPXBankBrand = .unknown
    private var configuration: STPPaymentConfiguration?
    private weak var imageView: UIImageView?
    private var headerView: STPSectionHeaderView?
    private var loading = false
    private var bankStatus: STPFPXBankStatusResponse?

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func _refreshFPXStatus() {
        apiClient.retrieveFPXBankStatus(withCompletion: { bankStatusResponse, error in
            if error == nil && bankStatusResponse != nil {
                if let bankStatusResponse = bankStatusResponse {
                    self._update(withBankStatus: bankStatusResponse)
                }
            }
        })
    }

    @objc override func createAndSetupViews() {
        super.createAndSetupViews()

        tableView?.register(
            STPBankSelectionTableViewCell.self,
            forCellReuseIdentifier: STPBankSelectionCellReuseIdentifier)

        tableView?.dataSource = self
        tableView?.delegate = self
        tableView?.reloadData()
    }

    @objc override func updateAppearance() {
        super.updateAppearance()

        tableView?.reloadData()
    }

    @objc override func useSystemBackButton() -> Bool {
        return true
    }

    func _update(withBankStatus bankStatusResponse: STPFPXBankStatusResponse) {
        bankStatus = bankStatusResponse

        tableView?.beginUpdates()
        if let indexPathsForVisibleRows = tableView?.indexPathsForVisibleRows {
            tableView?.reloadRows(at: indexPathsForVisibleRows, with: .none)
        }
        tableView?.endUpdates()
    }

    // MARK: - UITableView

    /// :nodoc:
    @objc
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    /// :nodoc:
    @objc
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return STPFPXBankBrand.unknown.rawValue
    }

    /// :nodoc:
    @objc
    public func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell =
            tableView.dequeueReusableCell(
                withIdentifier: STPBankSelectionCellReuseIdentifier, for: indexPath)
            as? STPBankSelectionTableViewCell
        let bankBrand = STPFPXBankBrand(rawValue: indexPath.row)
        let selected = selectedBank == bankBrand
        var offline: Bool?
        if let bankBrand = bankBrand {
            offline = bankStatus != nil && !(bankStatus?.bankBrandIsOnline(bankBrand) ?? false)
        }
        if let bankBrand = bankBrand {
            cell?.configure(
                withBank: bankBrand, theme: theme, selected: selected, offline: offline ?? false,
                enabled: !loading)
        }
        return cell!
    }

    /// :nodoc:
    @objc
    public func tableView(
        _ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath
    ) {
        let topRow = indexPath.row == 0
        let bottomRow =
            self.tableView(tableView, numberOfRowsInSection: indexPath.section) - 1 == indexPath.row
        cell.stp_setBorderColor(theme.tertiaryBackgroundColor)
        cell.stp_setTopBorderHidden(!topRow)
        cell.stp_setBottomBorderHidden(!bottomRow)
        cell.stp_setFakeSeparatorColor(theme.quaternaryBackgroundColor)
        cell.stp_setFakeSeparatorLeftInset(15.0)
    }

    /// :nodoc:
    @objc
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int)
        -> CGFloat
    {
        return 27.0
    }

    /// :nodoc:
    @objc
    public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath)
        -> Bool
    {
        return !loading
    }

    /// :nodoc:
    @objc
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if loading {
            return  // Don't allow user interaction if we're currently setting up a payment method
        }
        loading = true
        tableView.deselectRow(at: indexPath, animated: true)
        let bankIndex = indexPath.row
        selectedBank = STPFPXBankBrand(rawValue: bankIndex) ?? .unknown
        tableView.reloadSections(
            NSIndexSet(index: indexPath.section) as IndexSet,
            with: .none)

        let fpx = STPPaymentMethodFPXParams()
        fpx.bank = STPFPXBankBrand(rawValue: bankIndex) ?? .unknown
        // Create and return a Payment Method Params object
        let paymentMethodParams = STPPaymentMethodParams(
            fpx: fpx,
            billingDetails: nil,
            metadata: nil)
        if delegate?.responds(
            to: #selector(
                STPBankSelectionViewControllerDelegate.bankSelectionViewController(
                    _:didCreatePaymentMethodParams:))) ?? false
        {
            delegate?.bankSelectionViewController(
                self, didCreatePaymentMethodParams: paymentMethodParams)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    required init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("init(nibName:bundle:) has not been implemented")
    }
}

/// An `STPBankSelectionViewControllerDelegate` is notified when a user selects a bank.
@objc public protocol STPBankSelectionViewControllerDelegate: NSObjectProtocol {
    /// This is called when the user selects a bank.
    /// You can use the returned PaymentMethodParams to confirm a PaymentIntent, or inspect
    /// it to obtain details about the selected bank.
    /// Once you're done, you'll want to dismiss (or pop) the view controller.
    /// - Parameters:
    ///   - bankViewController:          the view controller that created the PaymentMethodParams
    ///   - paymentMethodParams:         the PaymentMethodParams that was created. - seealso: STPPaymentMethodParams
    @objc(bankSelectionViewController:didCreatePaymentMethodParams:)
    func bankSelectionViewController(
        _ bankViewController: STPBankSelectionViewController,
        didCreatePaymentMethodParams paymentMethodParams: STPPaymentMethodParams
    )
}

private let STPBankSelectionCellReuseIdentifier = "STPBankSelectionCellReuseIdentifier"

extension STPBankSelectionViewController: STPAnalyticsProtocol {
    static var stp_analyticsIdentifier = "STPBankSelectionViewController"
}
