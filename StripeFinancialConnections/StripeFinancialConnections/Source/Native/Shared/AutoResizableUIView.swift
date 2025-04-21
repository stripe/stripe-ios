//
//  AutoResizableUIView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/11/24.
//

import Foundation
import SwiftUI
import UIKit

//
// These are only used for SwiftUI previews so no need to expose outside of DEBUG.
//
#if DEBUG

/// This helps to auto-resize UIView's placed in SwiftUI. Otherwise,
/// the UIView's tend to stretch the full height of the screen.
///
/// If wrapping the `UIView` with `AutoResizableUIView` doesn't help,
/// also call `applyAutoResizableUIViewModifier` to your SwiftUI view.
class AutoResizableUIView<ContentView: UIView>: UIView {
    var contentView: ContentView

    init(contentView: ContentView) {
        self.contentView = contentView
        super.init(frame: .zero)
        backgroundColor = .clear
        addSubview(contentView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var height: CGFloat = .zero {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        CGSize(
            width: UIView.noIntrinsicMetric,
            height: height
        )
    }

    override var frame: CGRect {
        didSet {
            guard frame != oldValue else {
                return
            }
            contentView.frame = bounds
            contentView.layoutIfNeeded()

            let targetFrameSize = CGSize(
                width: frame.width,
                height: UIView.layoutFittingCompressedSize.height
            )
            height = contentView.systemLayoutSizeFitting(
                targetFrameSize,
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            ).height
        }
    }
}

extension View {
    /// Helper for use with `AutoResizableUIView`. Apply it to the SwitUI view that's
    /// being created via `UIViewRepresentable`.
    func applyAutoResizableUIViewModifier() -> some View {
        fixedSize(
            horizontal: false,
            vertical: true
        )
    }
}

#endif
