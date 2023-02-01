//
//  ModalPresentationWrapperViewController.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 12/22/22.
//

import UIKit

class ModalPresentationWrapperViewController: UIViewController {

    private weak var vc: UIViewController?

    // MARK: - Init

    init(vc: UIViewController) {
        self.vc = vc
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        view.alpha = 0.3
        view.backgroundColor = .black
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let vc = vc, presentedViewController == nil {
            self.present(vc, animated: true)
        }
    }

    // MARK: - Touch Handler

    @objc
    private func didTap() {
        dismiss(animated: false)
    }
}
