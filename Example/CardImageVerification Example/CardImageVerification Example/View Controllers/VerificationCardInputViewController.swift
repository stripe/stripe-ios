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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.destination is VerificationExplanationViewController {
            let vc = segue.destination as? VerificationExplanationViewController
            let iin = iinTextField.text!
            let last4 = lastFourTextField.text!
            vc?.expectedCardViewModel = ExpectedCardViewModel(iin: iin, last4: last4)
        }
    }
}

// MARK: UI Views
private extension VerificationCardInputViewController {
    func setUpViews() {
        continueButton.layer.cornerRadius = 10.0

        [iinTextField, lastFourTextField].forEach {
            $0.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        }
    }

    func updateButtonState(isLoading: Bool) {
        continueButton.updateButtonState(isLoading: isLoading)
    }
}

// MARK: UITextFieldDelegate
extension VerificationCardInputViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == iinTextField {
            return atTextLimit(iinTextField, newText: string, limit: 6)
        }

        if textField == lastFourTextField {
            return atTextLimit(lastFourTextField, newText: string, limit: 4)
        }

        return true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }

    @objc
    func textDidChange() {
        if iinTextField.text!.count == 6 && lastFourTextField.text!.count == 4 {
            continueButton.updateButtonState(isLoading: false)
            view.endEditing(true)
        } else {
            continueButton.updateButtonState(isLoading: true)
        }
    }

    func atTextLimit(_ textField: UITextField, newText: String, limit: Int) -> Bool {
        let shouldNotResign =  newText.isEmpty || textField.text!.count + newText.count <= limit

        if !shouldNotResign {
            textField.resignFirstResponder()
        }

        return shouldNotResign
    }
}

