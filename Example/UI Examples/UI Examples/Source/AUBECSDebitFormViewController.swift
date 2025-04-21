//
//  AUBECSDebitFormViewController.swift
//  UI Examples
//
//  Created by Cameron Sabol on 3/16/20.
//  Copyright © 2020 Stripe. All rights reserved.
//

import Stripe
import UIKit

class AUBECSDebitFormViewController: UIViewController {

    let becsFormView = STPAUBECSDebitFormView(companyName: "Great Company Inc.")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "BECS Debit Form"
        view.backgroundColor = UIColor.white
        view.addSubview(becsFormView)
        edgesForExtendedLayout = []
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: #selector(done))
        becsFormView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            becsFormView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            becsFormView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            becsFormView.topAnchor.constraint(equalTo: view.topAnchor, constant: 15),
        ])
    }

    @objc func done() {
        dismiss(animated: true, completion: nil)
    }
}
