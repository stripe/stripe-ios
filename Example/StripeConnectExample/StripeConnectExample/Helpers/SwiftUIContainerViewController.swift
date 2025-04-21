//
//  SwiftUIContainerViewController.swift
//  StripeConnect Example
//
//  Created by Chris Mays on 8/26/24.
//

import SwiftUI
import UIKit

/// Helper SwiftUI Container VC that enables SwiftUI to present view controllers
class SwiftUIContainerViewController<Content: View>: UIViewController {
    let content: Content

    init(content: Content) {
        self.content = content
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let hostingController = UIHostingController(rootView: content.environment(\.viewControllerPresenter, .init(presentViewController: { [weak self] vc in
            DispatchQueue.main.async {
                self?.present(vc, animated: true)
            }
        }, pushViewController: { [weak self] vc in
            DispatchQueue.main.async {
                self?.navigationController?.pushViewController(vc, animated: true)
            }
        }, setRootViewController: { [weak self] vc in
            DispatchQueue.main.async {
                self?.dismiss(animated: true)
                self?.view.window?.rootViewController = vc
            }
        })))

        self.view.addSubview(hostingController.view)
        self.addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
        ])
    }
}

struct ViewControllerPresenter {
    let presentViewController: (UIViewController) -> Void
    let pushViewController: (UIViewController) -> Void
    let setRootViewController: (UIViewController) -> Void
}

private struct ViewControllerPresenterKey: EnvironmentKey {
    static let defaultValue: ViewControllerPresenter? = nil
}

extension EnvironmentValues {
  var viewControllerPresenter: ViewControllerPresenter? {
    get { self[ViewControllerPresenterKey.self] }
    set { self[ViewControllerPresenterKey.self] = newValue }
  }
}

extension View {
    var containerViewController: SwiftUIContainerViewController<Self> {
        .init(content: self)
    }
}
