//
//  PanModalAnimator.swift
//  PanModal
//
//  Copyright © 2019 Tiny Speck, Inc. All rights reserved.
//

#if os(iOS)
    import UIKit

    /// Helper animation function to keep animations consistent.
    @available(iOSApplicationExtension, unavailable)
    @available(macCatalystApplicationExtension, unavailable)
    struct PanModalAnimator {

        /**
     Constant Animation Properties
     */
        struct Constants {
            static let defaultTransitionDuration: TimeInterval = 0.5
        }

        // TODO: We don't use config, refactor
        static func animate(
            _ animations: @escaping PanModalPresentable.AnimationBlockType,
            config: PanModalPresentable?,
            _ completion: PanModalPresentable.AnimationCompletionType? = nil
        ) {

            let params = UISpringTimingParameters()
            let animator = UIViewPropertyAnimator(duration: 0, timingParameters: params)

            animator.addAnimations(animations)
            if let completion = completion {
                animator.addCompletion { (_) in
                    completion(true)
                }
            }
            animator.startAnimation()
        }
    }
#endif
