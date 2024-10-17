//
//  BrowseViewController.swift
//  UI Examples
//
//  Created by Ben Guo on 7/18/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

import PassKit
import SwiftUI
import UIKit

@testable import Stripe
@_spi(STP) import StripePaymentsUI

class BrowseViewController: UITableViewController
{

    enum Demo: Int {
        static var count: Int = 8

        case STPPaymentCardTextField
        case STPPaymentCardTextFieldWithCBC
        case STPAUBECSFormViewController
        case STPCardFormViewController
        case STPCardFormViewControllerCBC
        case SwiftUICardFormViewController
        case PaymentMethodMessagingView

        var title: String {
            switch self {
            case .STPPaymentCardTextField: return "Card Field"
            case .STPPaymentCardTextFieldWithCBC: return "Card Field (CBC)"
            case .STPAUBECSFormViewController: return "AU BECS Form"
            case .STPCardFormViewController: return "Card Form"
            case .STPCardFormViewControllerCBC: return "Card Form (CBC)"
            case .SwiftUICardFormViewController: return "Card Form (SwiftUI)"
            case .PaymentMethodMessagingView: return "Payment Method Messaging View"
            }
        }

        var detail: String {
            switch self {
            case .STPPaymentCardTextField: return "STPPaymentCardTextField"
            case .STPPaymentCardTextFieldWithCBC: return "STPPaymentCardTextField"
            case .STPAUBECSFormViewController: return "STPAUBECSFormViewController"
            case .STPCardFormViewController: return "STPCardFormViewController"
            case .STPCardFormViewControllerCBC: return "STPCardFormViewController (CBC)"
            case .SwiftUICardFormViewController: return "STPCardFormView.Representable"
            case .PaymentMethodMessagingView: return "PaymentMethodMessagingView"
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Stripe UI Examples"
        tableView.tableFooterView = UIView()
        tableView.rowHeight = 60
        switch traitCollection.userInterfaceStyle {
        case .light, .unspecified:
            UINavigationBar.appearance().backgroundColor = .white
        case .dark:
            UINavigationBar.appearance().backgroundColor = .black
        @unknown default:
            fatalError()
        }
    }

    // MARK: UITableViewDelegate

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Demo.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell
    {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        if let example = Demo(rawValue: indexPath.row) {
            cell.textLabel?.text = example.title
            cell.detailTextLabel?.text = example.detail
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let example = Demo(rawValue: indexPath.row) else { return }
        switch example {
        case .STPPaymentCardTextField:
            let viewController = CardFieldViewController()
            let navigationController = UINavigationController(rootViewController: viewController)
            present(navigationController, animated: true, completion: nil)
        case .STPPaymentCardTextFieldWithCBC:
            let viewController = CardFieldViewController()
            viewController.alwaysEnableCBC = true
            let navigationController = UINavigationController(rootViewController: viewController)
            present(navigationController, animated: true, completion: nil)
        case .STPAUBECSFormViewController:
            let viewController = AUBECSDebitFormViewController()
            let navigationController = UINavigationController(rootViewController: viewController)
            present(navigationController, animated: true, completion: nil)
        case .STPCardFormViewController:
            let viewController = CardFormViewController()
            let navigationController = UINavigationController(rootViewController: viewController)
            present(navigationController, animated: true, completion: nil)
        case .STPCardFormViewControllerCBC:
            let viewController = CardFormViewController()
            viewController.alwaysEnableCBC = true
            let navigationController = UINavigationController(rootViewController: viewController)
            present(navigationController, animated: true, completion: nil)
        case .SwiftUICardFormViewController:
            let controller = UIHostingController(rootView: SwiftUICardFormView())
            present(controller, animated: true, completion: nil)
        case .PaymentMethodMessagingView:
            let vc = PaymentMethodMessagingViewController()
            let navigationController = UINavigationController(rootViewController: vc)
            present(navigationController, animated: true, completion: nil)
        }
    }

}
