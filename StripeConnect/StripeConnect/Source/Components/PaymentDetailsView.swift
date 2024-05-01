//
//  PaymentDetailsView.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 4/30/24.
//

import Combine
import UIKit

public class PaymentDetailsView: UIView {
//    let webView = ComponentWebView()

    private var cancellables: Set<AnyCancellable> = []

    init(connectInstance: StripeConnectInstance) {
        super.init(frame: .zero)

        connectInstance.$appearance.sink { _ in

        }.store(in: &cancellables)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
