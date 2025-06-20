//
//  FCLiteModalPresentationWrapper.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-03-19.
//

import UIKit

class FCLiteModalPresentationWrapper: UIViewController {

    private var vc: UIViewController?

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

        guard let vc, presentedViewController == nil else { return }
        self.present(vc, animated: true)
    }

    @objc
    private func didTap() {
        dismiss(animated: false)
    }
}
