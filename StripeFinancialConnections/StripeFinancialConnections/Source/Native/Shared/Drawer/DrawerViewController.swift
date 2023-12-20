//
//  DrawerViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 12/18/23.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class DrawerView {

    private let view: DrawerLayoutStackView
    weak var scrollView: UIScrollView? {
        return view.scrollView
    }

    init(contentView: UIView, footerView: UIView?) {
        self.view = DrawerLayoutStackView(
            scrollViewContentView: contentView,
            footerView: footerView
        )
    }

    func addTo(view passedInView: UIView) {
        // this function encapsulates an error-prone sequence where we
        // must add `paneLayoutView` (and all it's subviews) to the `view`
        // BEFORE we can add a constraint for `UIScrollView` content
        passedInView.addAndPinSubviewToSafeArea(view)
        view.scrollViewContentView?
            .widthAnchor
            .constraint(
                equalTo: view.safeAreaLayoutGuide.widthAnchor
            )
            .isActive = true
    }
}

private final class DrawerLayoutStackView: HitTestStackView {
    
    private(set) weak var scrollView: UIScrollView?
    private(set) weak var scrollViewContentView: UIView?
    
    init(
        scrollViewContentView: UIView,
        footerView: UIView?
    ) {
        let scrollView = UIScrollView()
        scrollView.addAndPinSubview(scrollViewContentView)
        self.scrollView = scrollView
        self.scrollViewContentView = scrollViewContentView
        super.init(frame: .zero)
        spacing = 0
        axis = .vertical
        addArrangedSubview(scrollView)
        if let footerView = footerView {
            addArrangedSubview(footerView)
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // initialy, we start with a frame of `.zero` in init
        let viewWasResized = frame.width > 0 && frame.height > 0
        if viewWasResized, let scrollView = scrollView {
            if
                // ensure scroll view was laid out
                scrollView.bounds.width > 0,
                scrollView.bounds.height > 0
            {
                
            }
        }
    }
}

final class DrawerViewController: UIViewController, UIGestureRecognizerDelegate {
    
//    private lazy var verticalStackView: UIStackView = {
//        let verticalStackView = UIStackView(
//            arrangedSubviews: []
//        )
//        return verticalStackView
//    }()
//    private lazy var scrollView: UIScrollView = {
//        return UIScrollView()
//    }()
//    private weak var scrollViewContentView: UIView?
//    private let paneLayoutView: UIView
    
//    let backgroundView: UIView
    
    let transparentDrawerContentView = UIView(frame: UIScreen.main.bounds)
    private lazy var drawerKnobView: UIView = {
//        let drawerKnobView = UIView()
//        drawerKnobView.backgroundColor = .customBackgroundColor
//        return drawerKnobView
        let handleView = CreateHandleView()
        handleView.backgroundColor = .customBackgroundColor
        return handleView
    }()
    
    private lazy var contentStackView: UIStackView = {
       let contentStackView = UIStackView()
        contentStackView.axis = .vertical
        contentStackView.spacing = 0
        
        contentStackView.addArrangedSubview(drawerKnobView)
        
        
        
        let view = UIView()
        view.backgroundColor = .customBackgroundColor
        let pane = PaneWithHeaderLayoutView(title: "Meow\nWoof\nWoof\nWoof\nWoof\nWoof\nWoof\nWoof\nWoof\nWoof\nWoof\nWoof\nWoof\nWoof\nWoof\nWoof\nWoof\nWoof\nWoof\nWoof\nWoof\nWoof\nWoof\nWoof\nWoof\nWoof\nWoof\nWoof", contentView: UIView(), footerView: nil)
        pane.addTo(view: view)
        contentStackView.addArrangedSubview(view)
        
        return contentStackView
    }()
    private var originalY: CGFloat = 0
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.addSubview(transparentDrawerContentView)
        
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        transparentDrawerContentView.addSubview(contentStackView)
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(
                greaterThanOrEqualTo: transparentDrawerContentView.topAnchor,
                constant: 0
            ),
            contentStackView.leadingAnchor.constraint(equalTo: transparentDrawerContentView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: transparentDrawerContentView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: transparentDrawerContentView.bottomAnchor),
        ])
        
        // Create the pan gesture recognizer
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
//        panGesture.delegate = self
        
        // Add the gesture recognizer to your view
        self.view.addGestureRecognizer(panGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // TODO(kgaidis): fix this
        if isBeingPresented {
            var topPadding = view.window?.safeAreaInsets.top ?? 0
            topPadding += 10 // estimated iOS value of how far drawer stretches
            topPadding += UINavigationController().navigationBar.bounds.height
            topPadding += 24 // typical FInancial COnnecitons padding
            self.originalY = topPadding
            
            
//            let navigationBar = UINavigationBar()
            
            
//            topPadding += 20
            
            transparentDrawerContentView.backgroundColor = .clear
//            transparentDrawerContentView.backgroundColor = .red.withAlphaComponent(0.3)
            
            
            var bounds = view.bounds
            bounds.size.height -= topPadding
            bounds.origin.y = view.bounds.height - bounds.height
            transparentDrawerContentView.frame = bounds
            
            var initialBounds = bounds
            initialBounds.origin.y += bounds.height
            let finalBounds = bounds
            
            transparentDrawerContentView.frame = initialBounds
            UIView.animate(withDuration: 2) {
                self.transparentDrawerContentView.frame = finalBounds
            }
        }
        
        let cornerRadius: CGFloat = 18
        let path = UIBezierPath(
            roundedRect: drawerKnobView.bounds,
            byRoundingCorners: [.topRight, .topLeft],
            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
        )
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        drawerKnobView.layer.mask = maskLayer
    }
    
//    func addTo(view: UIView) {
//        // this function encapsulates an error-prone sequence where we
//        // must add `paneLayoutView` (and all it's subviews) to the `view`
//        // BEFORE we can add a constraint for `UIScrollView` content
//        view.addAndPinSubviewToSafeArea(paneLayoutView)
//        scrollViewContentView?.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor).isActive = true
//    }
    
    
    
    @objc func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self.view)

        if recognizer.state == .began {
            // This is where the gesture began
        } else if recognizer.state == .changed {
            // The user's finger has moved; translation.y is the vertical movement
            print("Vertical movement from start point: \(translation.y)")
            
            transparentDrawerContentView.frame = CGRect(
                x: 0,
                y: {
                    let realYValue = self.originalY + translation.y
                    if self.originalY > realYValue {
                        let yValue = self.originalY - dampenValue(self.originalY - realYValue)
                        return yValue
                    } else {
                        return realYValue
                    }
                }(),
                width: transparentDrawerContentView.bounds.width,
                height: transparentDrawerContentView.bounds.height
            )
            
        } else if recognizer.state == .ended {
            
            // scrolled over top
            if transparentDrawerContentView.frame.minY < self.originalY {
                UIView.animate(
                    withDuration: 0.3,
                    delay: 0,
                    options: .curveEaseOut
//                    delay: 0,
//                    usingSpringWithDamping: 0.05,
//                    initialSpringVelocity: 0.5
                ) {
                    self.transparentDrawerContentView.frame = CGRect(
                        x: 0,
                        y: self.originalY,
                        width: self.transparentDrawerContentView.bounds.width,
                        height: self.transparentDrawerContentView.bounds.height
                    )
                }
            } else {
                // figure out whether to auto-dismiss (velocity etc.) Or to go back to original position
                
//                UIView.animate(withDuration: <#T##TimeInterval#>, delay: <#T##TimeInterval#>, animations: <#T##() -> Void#>)
                
                UIView.animate(
                    withDuration: 0.3,
                    delay: 0,
                    options: .curveEaseOut
//                    delay: 0,
//                    usingSpringWithDamping: 0.05,
//                    initialSpringVelocity: 0.5
                ) {
                    self.transparentDrawerContentView.frame = CGRect(
                        x: 0,
                        y: self.originalY,
                        width: self.transparentDrawerContentView.bounds.width,
                        height: self.transparentDrawerContentView.bounds.height
                    )
                }
            }
            
            
            // The gesture has ended
        }
    }
    
    func dampenValue(_ value: CGFloat, dampingFactor: CGFloat = 0.05) -> CGFloat {
        guard dampingFactor > 0, value >= 0 else { return 0 }
        // Apply an exponential dampening formula
        // The '1 - exp(-dampingFactor * value)' provides a curve that slows down as 'value' increases
        let dampenedValue = (1 - exp(-dampingFactor * value)) / dampingFactor
        return dampenedValue
    }
    
//    func gestureRecognizer(
//        _ gestureRecognizer: UIGestureRecognizer,
//        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
//    ) -> Bool {
//        // Allow simultaneous recognition
//        return true
//    }
    
    
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
//                           shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        if gestureRecognizer == customPanGesture && otherGestureRecognizer == scrollView.panGestureRecognizer {
//            let isScrollingDown = scrollView.contentOffset.y <= 0 && scrollView.panGestureRecognizer.translation(in: scrollView).y > 0
//            return isScrollingDown
//        }
//        return false
//    }
    
    // MARK: - Presenting
    
    fileprivate let transitionDelegate = TransitioningDelegate()
    func present(on viewController: UIViewController) {
        modalPresentationStyle = .custom
        transitioningDelegate = transitionDelegate
        viewController.present(self, animated: true)
    }
}

private func CreateHandleView() -> UIView {
    let topPadding: CGFloat = 12
    let bottomPadding: CGFloat = 8
    let handleHeight: CGFloat = 4

    let containerView = UIView()
    containerView.backgroundColor = .clear
    containerView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        containerView.heightAnchor.constraint(equalToConstant: topPadding + handleHeight + bottomPadding),
    ])

    let handleView = UIView()
    handleView.backgroundColor = UIColor.textDisabled // TODO(kgaidis): fix color
    handleView.layer.cornerRadius = 4
    containerView.addSubview(handleView)
    handleView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        handleView.widthAnchor.constraint(equalToConstant: 32),
        handleView.heightAnchor.constraint(equalToConstant: handleHeight),
        handleView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
        handleView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: topPadding),
        handleView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -bottomPadding),
    ])
    return containerView
}


fileprivate class TransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    func animationController(
        forPresented presented: UIViewController, 
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        return AnimatedTransitioning()
    }

    func animationController(
        forDismissed dismissed: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        return AnimatedTransitioning()
    }
}

fileprivate class AnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
    
    private let backgroundDimmingView = UIView()
    
    override init() {
        super.init()
        backgroundDimmingView.backgroundColor = .black.withAlphaComponent(0.5)
    }
    
    func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?
    ) -> TimeInterval {
        return 2 // Duration of the animation
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let toViewController = transitionContext.viewController(forKey: .to) as? DrawerViewController
//              let fromViewController = transitionContext.viewController(forKey: .from)
        else {
            transitionContext.completeTransition(false)
            return
        }
        
        let fromViewController = transitionContext.viewController(forKey: .from)
        let isPresenting = toViewController.presentingViewController === fromViewController

        // Add the toViewController's view to the container view
        let containerView = transitionContext.containerView
        
        
        if isPresenting {
            containerView.addAndPinSubview(backgroundDimmingView)
            containerView.addSubview(toViewController.view)
            
            backgroundDimmingView.alpha = 0.0
            UIView.animate(
                withDuration: transitionDuration(using: transitionContext),
                animations: {
                    self.backgroundDimmingView.alpha = 1.0
                },
                completion: { _ in
                    transitionContext.completeTransition(true)
                }
            )
        } else {
            // dimming view is already there
            containerView.addSubview(toViewController.view)
            
            backgroundDimmingView.alpha = 1.0
            UIView.animate(
                withDuration: transitionDuration(using: transitionContext),
                animations: {
                    self.backgroundDimmingView.alpha = 0.0
                },
                completion: { _ in
                    transitionContext.completeTransition(true)
                }
            )
        }
    }
}
