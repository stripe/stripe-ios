//
//  ViewController.swift
//  CardImageVerification Example
//
//  Created by Jaime Park on 11/17/21.
//

import UIKit
import StripeCardScan

class ViewController: UIViewController {
    func displayAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default, handler:  { _ in
            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
            }
        })
        alertController.addAction(OKAction)
        present(alertController, animated: true, completion: nil)
    }

    @IBAction func cardScanSheetExample() {
        let cardScanSheet = CardScanSheet()

        cardScanSheet.present(from: self) { [weak self] result in
            var title = ""
            var message = ""

            switch result {
            case .completed(let card):
                title = "Scan Completed"
                message = card.pan
            case .canceled:
                title = "Scan Canceled"
                message = "Canceled the scan"
            case .failed(let error):
                title = "Scan Failed"
                message = "Failed with error: \(error.localizedDescription)"
            }

            self?.displayAlert(title: title, message: message)
        }
    }
}

