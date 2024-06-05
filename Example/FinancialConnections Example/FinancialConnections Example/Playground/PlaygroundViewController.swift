//
//  PlaygroundViewController.swift
//  FinancialConnections Example
//
//  Created by Krisjanis Gaidis on 10/25/22.
//

import Foundation
import SwiftUI
import UIKit

@available(iOS 14.0, *)
final class PlaygroundViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // create
        let hostingController = UIHostingController(rootView: PlaygroundView())

        // add to subview
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        // layout
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
}
