//
//  PaymentMethodFormViewController.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 5/16/24.
//

@_spi(STP) import StripeUICore
import UIKit

class PaymentMethodFormViewController: UIViewController {
    let form: PaymentMethodElement

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(form: PaymentMethodElement) {
        self.form = form
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view = form.view
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            _ = self.form.beginEditing()
        }
    }

    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        // viewWillAppear is called too late (when the dismissal animation is done), so we override this method instead
        if parent == nil {
            view.endEditing(true)
        }
    }
}
