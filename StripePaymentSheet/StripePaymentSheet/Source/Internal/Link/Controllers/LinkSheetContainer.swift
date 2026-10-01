//
//  LinkSheetContainer.swift
//  StripePaymentSheet
//
//  Created by George Birch on 9/30/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import UIKit

final class LinkBottomSheetViewController: BottomSheetViewController {

    override var navigationBarHeight: CGFloat {
        LinkUI.navigationBarHeight
    }

    override var sheetCornerRadius: CGFloat? {
        LinkUI.largeCornerRadius
    }
}

final class LinkNativeSheetContainerViewController: NativeSheetContainerViewController {

    override var sheetCornerRadius: CGFloat? {
        LinkUI.largeCornerRadius
    }
}

enum LinkSheetContainerFactory {

    static func make(
        contentViewController: BottomSheetContentViewController,
        usesNativeSheet: Bool = false,
        didCancelNative3DS2: @escaping () -> Void = {}
    ) -> any PaymentSheetContainer {
        #if os(visionOS)
        let shouldUseNativeSheet = false
        #else
        let shouldUseNativeSheet = NativeSheetPresentation.isRequiredForDevice || usesNativeSheet
        #endif

        if shouldUseNativeSheet {
            return LinkNativeSheetContainerViewController(
                contentViewController: contentViewController,
                appearance: LinkUI.appearance,
                isTestMode: false,
                didCancelNative3DS2: didCancelNative3DS2
            )
        }
        return LinkBottomSheetViewController(
            contentViewController: contentViewController,
            appearance: LinkUI.appearance,
            isTestMode: false,
            didCancelNative3DS2: didCancelNative3DS2
        )
    }
}
