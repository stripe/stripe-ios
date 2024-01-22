//
//  SpinnerView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/9/24.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class SpinnerView: UIView {

    init() {
        super.init(frame: .zero)
        let activityIndicator = ActivityIndicator(size: .large)
        activityIndicator.color = .iconActionPrimary
        activityIndicator.backgroundColor = .customBackgroundColor
        activityIndicator.startAnimating()
        addSubview(activityIndicator)

        // `ActivityIndicator` is hard-coded to have specific sizes, so here we scale it to our needs
        let largeIconDiameter: CGFloat = 37
        let desiredIconDiameter: CGFloat = 44
        let transform = CGAffineTransform(
            scaleX: desiredIconDiameter / largeIconDiameter,
            y: desiredIconDiameter / largeIconDiameter
        )
        activityIndicator.transform = transform
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.widthAnchor.constraint(equalToConstant: desiredIconDiameter),
            activityIndicator.heightAnchor.constraint(equalToConstant: desiredIconDiameter),
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#if DEBUG

import SwiftUI

private struct SpinnerViewUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> SpinnerView {
        SpinnerView()
    }

    func updateUIView(_ uiView: SpinnerView, context: Context) {}
}

struct SpinnerView_Previews: PreviewProvider {
    static var previews: some View {
        SpinnerViewUIViewRepresentable()
    }
}

#endif
