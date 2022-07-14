//
//  DataAccessNoticeViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/13/22.
//

import Foundation
import UIKit

final class DataAccessNoticeViewController: UIViewController {

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapBackground))
        tapGestureRecognizer.delegate = self
        view.addGestureRecognizer(tapGestureRecognizer)
        
        let dataAccessNoticeView = DataAccessNoticeView()
        view.addSubview(dataAccessNoticeView)
        dataAccessNoticeView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dataAccessNoticeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dataAccessNoticeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dataAccessNoticeView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    @objc private func didTapBackground() {
        dismiss(animated: true)
    }
}

// MARK: - <UIGestureRecognizerDelegate>

extension DataAccessNoticeViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // only consider touches on the dark overlay area
        return touch.view === self.view
    }
}
