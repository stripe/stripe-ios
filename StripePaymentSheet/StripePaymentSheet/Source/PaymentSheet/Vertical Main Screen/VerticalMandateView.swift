//
//  VerticalMandateView.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 6/11/24.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

/// - Note: This really has nothing to do with mandates.  It's more like a generic ContentView with a particular way of animating its contents; it fades old content in OR new content out, but if it's swapping between contents it doesn't fade them.
final class VerticalMandateView: UIView {
    private var content: UIView?
    
    override var intrinsicContentSize: CGSize {
        if content == nil {
            // Without this, the view has ambiguous height when there is no content
            return .zero
        }
        return super.intrinsicContentSize
    }
    
    required init() {
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    typealias Animator = (_ animations : @escaping () -> Void, _ completion: @escaping (Bool) -> Void) -> Void
    func setContent(_ newContent: UIView?, animator: Animator?) {
        // Take a snapshot of the old content and add it to our container - we'll fade it out
        let oldViewImage = content?.snapshotView(afterScreenUpdates: true)
        if let oldViewImage {
            // Add new view
            oldViewImage.translatesAutoresizingMaskIntoConstraints = false
            addSubview(oldViewImage)
            NSLayoutConstraint.activate([
                oldViewImage.heightAnchor.constraint(equalToConstant: oldViewImage.frame.height),
                oldViewImage.bottomAnchor.constraint(equalTo: bottomAnchor),
                oldViewImage.trailingAnchor.constraint(equalTo: trailingAnchor),
                oldViewImage.leadingAnchor.constraint(equalTo: leadingAnchor),
            ])
        }
        // Remove the old content
        content?.removeFromSuperview()
        self.content = newContent
        if let newContent {
            // Add new content
            newContent.alpha = 0
            addAndPinSubview(newContent)
            layoutIfNeeded()
        }
        
        // Okay, now we're ready to animate things in
        // If there's new and old content, don't animate b/c it looks weird
        if let animator, oldViewImage == nil || newContent == nil {
            animator {
                // Animate old content out
                oldViewImage?.alpha = 0
                // Animate new content in
                newContent?.alpha = 1
            } _: { _ in
                // Remove old content snapshot
                oldViewImage?.removeFromSuperview()
            }
        } else {
            newContent?.alpha = 1
            oldViewImage?.removeFromSuperview()
        }
    }
}
