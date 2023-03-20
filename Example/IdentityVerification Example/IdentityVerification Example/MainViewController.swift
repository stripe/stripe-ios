//
//  MainViewController.swift
//  IdentityVerification Example
//
//  Created by Mel Ludowise on 8/27/21.
//

import UIKit

class MainViewController: UIViewController {
    @IBOutlet weak var verificationSheetButton: UIButton!
    @IBOutlet weak var buildVersionLabel: UILabel!

    func setupBuildVersionLabel() {
        guard let infoDictionary = Bundle.main.infoDictionary,
              let version = infoDictionary["CFBundleShortVersionString"] as? String,
              let build = infoDictionary["CFBundleVersion"] as? String else {
            return
        }
        buildVersionLabel.text = "v\(version) build \(build)"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupBuildVersionLabel()

        // The IdentityVerificationSheet is only available on iOS 14.3 or higher
        if #available(iOS 14.3, *) {
            verificationSheetButton.isEnabled = true
        } else {
            verificationSheetButton.isEnabled = false
        }
    }
}
