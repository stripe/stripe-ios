//
//  PanContainerView.swift
//  PanModal
//
//  Copyright © 2018 Tiny Speck, Inc. All rights reserved.
//

#if os(iOS)
    import UIKit

    /// A view wrapper around the presented view in a PanModal transition.
    ///
    /// This allows us to make modifications to the presented view without
    /// having to do those changes directly on the view
    @objc(STPPanContainerView)
    class PanContainerView: UIView {

        init(presentedView: UIView, frame: CGRect) {
            super.init(frame: frame)
            presentedView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(presentedView)
            NSLayoutConstraint.activate([
                presentedView.topAnchor.constraint(equalTo: topAnchor),
                presentedView.bottomAnchor.constraint(equalTo: bottomAnchor),
                presentedView.leadingAnchor.constraint(equalTo: leadingAnchor),
                presentedView.trailingAnchor.constraint(equalTo: trailingAnchor),
            ])
        }

        @available(*, unavailable)
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

    }

    extension UIView {

        /**
     Convenience property for retrieving a PanContainerView instance
     from the view hierachy
     */
        var panContainerView: PanContainerView? {
            return subviews.first(where: { view -> Bool in
                view is PanContainerView
            }) as? PanContainerView
        }

    }
#endif
