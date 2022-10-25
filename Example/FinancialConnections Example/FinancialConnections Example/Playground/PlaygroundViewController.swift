//
//  PlaygroundViewController.swift
//  FinancialConnections Example
//
//  Created by Krisjanis Gaidis on 10/25/22.
//

import Foundation
import UIKit

final class PlaygroundViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backgroundView = UIView()
        backgroundView.backgroundColor = .red
        backgroundView.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        view.addSubview(backgroundView)
    }
}
