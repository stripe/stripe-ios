//
//  ExampleVerificationViewControllerNativeUI.swift
//  IdentityVerification Example
//
//  Created by Mel Ludowise on 3/3/21.
//

import UIKit
import StripeIdentity

/**
 Example view controller that presents an IdentityVerificationSheet using native
 iOS components.

 - Note: The native component variation of the IdentityVerificationSheet is
 available on an invite only basis. Please contact support+identity@stripe.com
 to learn more.
 */
class ExampleVerificationViewControllerNativeUI: UIViewController {

    // Constants
    let baseURL = "https://stripe-mobile-identity-verification-example-nativeui.glitch.me"
    let verifyEndpoint = "/create-verification-session"

    // Outlets
    @IBOutlet weak var verifyButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var verificationSheet: IdentityVerificationSheet?

    override func viewDidLoad() {
        super.viewDidLoad()

        activityIndicator.hidesWhenStopped = true
        verifyButton.addTarget(self, action: #selector(didTapVerifyButton), for: .touchUpInside)

        mockDocumentCameraForSimulator()
    }

    @objc
    func didTapVerifyButton() {
        requestVerificationSession()
    }

    func requestVerificationSession() {
        // Disable the button while we make the request
        updateButtonState(isLoading: true)

        // Make request to our verification endpoint
        let session = URLSession.shared
        let url = URL(string: baseURL + verifyEndpoint)!

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-type")

        let task = session.dataTask(with: urlRequest) { [weak self] data, response, error in
            DispatchQueue.main.async { [weak self] in
                // Re-enable button
                self?.updateButtonState(isLoading: false)

                guard
                    error == nil,
                    let data = data,
                    let responseJson = try? JSONDecoder().decode([String: String].self, from: data)
                else {
                    print(error as Any)
                    return
                }

                self?.startVerificationFlow(responseJson: responseJson)
             }
        }
        task.resume()
    }

    func startVerificationFlow(responseJson: [String: String]) {
        guard let verificationSessionId = responseJson["id"] else {
            assertionFailure("Did not receive a valid id.")
            return
        }
        guard let ephemeralKeySecret = responseJson["ephemeral_key_secret"] else {
            assertionFailure("Did not receive a valid ephemeral key secret.")
            return
        }
        self.verificationSheet = IdentityVerificationSheet(
            verificationSessionId: verificationSessionId,
            ephemeralKeySecret: ephemeralKeySecret,
            configuration: IdentityVerificationSheet.Configuration(
                brandLogo: UIImage(named: "BrandLogo")!
            )
        )
        self.verificationSheet?.present(
            from: self,
            completion: { [weak self] result in
                switch result {
                case .flowCompleted:
                    self?.displayAlert("Completed!")
                case .flowCanceled:
                    self?.displayAlert("Canceled!")
                case .flowFailed(let error):
                    self?.displayAlert("Failed!")
                    print(error)
                }
            })
    }

    func updateButtonState(isLoading: Bool) {
        // Re-enable button
        verifyButton.isEnabled = !isLoading
        if isLoading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }

    func displayAlert(_ message: String) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
            alertController.dismiss(animated: true) {
                self.dismiss(animated: true, completion: nil)
            }
        }
        alertController.addAction(OKAction)
        present(alertController, animated: true, completion: nil)
    }


    // MARK: - Customize fonts and colors

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        setNeedsStatusBarAppearanceUpdate()

        // Add an image to the navbar for this view controller
        let image = UIImage(named: "logo_image")
        let imageView = UIImageView(image: image)
        imageView.frame.size = image?.size ?? .zero
        imageView.contentMode = .scaleAspectFit
        navigationItem.titleView = imageView

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(named: "BrandColor")
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]

        // Update the appearance of the current navigation controller
        if let navigationController = self.navigationController {
            navigationController.navigationBar.standardAppearance = appearance
            navigationController.navigationBar.scrollEdgeAppearance = appearance

            navigationController.navigationBar.barStyle = .black
            navigationController.navigationBar.tintColor = .white
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Brand color can either be set using the window's tintColor
        // or by configuring AccentColor in the app's Assets file
        view.window?.tintColor = UIColor(named: "BrandColor")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Reset custom UI appearance when the view controller is popped
        guard isMovingFromParent else {
            return
        }

        // Reset appearance
        let defaultAppearance = UINavigationBarAppearance()
        if let navigationController = self.navigationController {
            navigationController.navigationBar.standardAppearance = defaultAppearance
            navigationController.navigationBar.scrollEdgeAppearance = defaultAppearance
            navigationController.navigationBar.barStyle = .default
            navigationController.navigationBar.tintColor = nil
        }

        view.window?.tintColor = nil
    }

    // MARK: - Simulator Mocking

    func mockDocumentCameraForSimulator() {
        // Mocks the camera input when running on the simulator
        #if targetEnvironment(simulator)
        if let frontImage = UIImage(named: "front_drivers_license.jpg"),
           let backImage = UIImage(named: "back_drivers_license.jpg") {
            IdentityVerificationSheet.simulatorDocumentCameraImages = [frontImage, backImage]
        }
        #endif
    }
}
