//
//  VerificationCardInputViewController.swift
//  CardImageVerification Example
//
//  Created by Jaime Park on 11/24/21.
//

import UIKit

class VerificationCardInputViewController: UIViewController {

    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var verifyResultLabel: UILabel!
    @IBOutlet weak var iinTextField: UITextField!
    @IBOutlet weak var lastFourTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is VerificationExplanationViewController {
            let vc = segue.destination as? VerificationExplanationViewController
            
            // Safely unwrap the text fields to prevent runtime crashes
            if let iin = iinTextField.text, let last4 = lastFourTextField.text, !iin.isEmpty, !last4.isEmpty {
                vc?.expectedCardViewModel = ExpectedCardViewModel(iin: iin, last4: last4)
            } else {
                print("Warning: IIN or Last Four fields are empty.")
                // Optionally, you could show an alert to the user here.
            }
        }
    }
}

// MARK: UI Views
private extension VerificationCardInputViewController {
    func setUpViews() {
        // Example of setting up views, like adding targets for button actions
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
    }

    @objc func continueButtonTapped() {
        // Handle the button tap, including potential form validation
        guard let iin = iinTextField.text, !iin.isEmpty else {
            showAlert(message: "Please enter the IIN.")
            return
        }
        
        guard let last4 = lastFourTextField.text, !last4.isEmpty else {
            showAlert(message: "Please enter the last four digits.")
            return
        }
        
        // Proceed with further logic
        print("Continue button tapped with IIN: \(iin) and Last Four: \(last4)")
    }

    func showAlert(message: String) {
        let alert = UIAlertController(title: "Input Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
