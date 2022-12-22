//
//  ModalPresentationWrapperViewController.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 12/22/22.
//

import UIKit

class ModalPresentationWrapperViewController: UIViewController {

    weak var vc: UIViewController?
    var observation: NSKeyValueObservation?

    // MARK: - Init

    init(vc: UIViewController) {
        self.vc = vc
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        // Make wrapper to pass touches through
        view.isUserInteractionEnabled = false
        view.alpha = 0
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let vc = vc, presentedViewController == nil {
            self.present(vc, animated: true)
        }
    }
}
