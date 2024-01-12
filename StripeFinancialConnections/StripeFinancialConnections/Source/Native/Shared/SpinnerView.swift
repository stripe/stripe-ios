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
        addAndPinSubviewToSafeArea(activityIndicator)
        activityIndicator.startAnimating()
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
