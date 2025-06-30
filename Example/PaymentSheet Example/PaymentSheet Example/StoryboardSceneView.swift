//
//  StoryboardSceneView.swift
//  PaymentSheet Example
//

import SwiftUI
import UIKit

struct StoryboardSceneView<T: UIViewController>: UIViewControllerRepresentable {
    var sceneIdentifier: String
    var configureViewController: ((T) -> Void)?

    func makeUIViewController(context: Context) -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: sceneIdentifier) as! T

        configureViewController?(viewController)

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Update if needed
        if let typedViewController = uiViewController as? T {
            configureViewController?(typedViewController)
        }
    }
}
