//
//  LinkPaymentMethodListView+Header.swift
//  StripePaymentSheet
//
//  Created by Chris Mays on 6/25/25.
//

extension LinkShippingAddressListView {
    class Header: LinkCollapsingListView.Header {

        override init(frame: CGRect) {
            super.init(frame: frame)
            collapsedLabel.text = "Shipping"
            headingLabel.text = STPLocalizedString(
                "Shipping address",
                "Title for a section listing one or more payment methods."
            )
            collapsedStackView.addArrangedSubview(collapsedContent)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        let collapsedContent = CellContentView()

        /// The selected payment method.
        private(set) var selectedShippingAddress: ShippingAddressesResponse.ShippingAddress? {
            didSet {
                updateChevron()
                collapsedContent.shippingAddress = selectedShippingAddress
                updateAccessibilityContent()
            }
        }

        func setSelectedShippingAddress(_ selectedShippingAddress: ShippingAddressesResponse.ShippingAddress?) {
            self.selectedShippingAddress = selectedShippingAddress
        }

        override func updateAccessibilityContent() {
            super.updateAccessibilityContent()
            if isExpanded {
                accessibilityLabel = collapsedLabel.text
            } else {
//                accessibilityLabel = selectedPaymentMethod?.accessibilityDescription
            }
        }

    }
}
