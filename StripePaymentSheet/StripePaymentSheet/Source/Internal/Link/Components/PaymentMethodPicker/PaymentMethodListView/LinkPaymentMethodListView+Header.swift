//
//  LinkPaymentMethodListView+Header.swift
//  StripePaymentSheet
//
//  Created by Chris Mays on 6/25/25.
//

extension LinkPaymentMethodListView {
    class PaymentListHeader: LinkCollapsingListView.Header {

        override init(frame: CGRect) {
            super.init(frame: frame)
            collapsedLabel.text = Strings.payment
            headingLabel.text = STPLocalizedString(
                "Payment methods",
                "Title for a section listing one or more payment methods."
            )
            collapsedStackView.addArrangedSubview(collapsedContent)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        let collapsedContent = CellContentView()

        /// The selected payment method.
        private(set) var selectedPaymentMethod: ConsumerPaymentDetails? {
            didSet {
                updateChevron()
                collapsedContent.paymentMethod = selectedPaymentMethod
                updateAccessibilityContent()
            }
        }

        func setSelectedPaymentMethod(selectedPaymentMethod: ConsumerPaymentDetails?, supported: Bool) {
            self.collapsable = supported
            self.selectedPaymentMethod = selectedPaymentMethod
        }

        override func updateAccessibilityContent() {
            super.updateAccessibilityContent()
            if isExpanded {
                accessibilityLabel = collapsedLabel.text
            } else {
                accessibilityLabel = selectedPaymentMethod?.accessibilityDescription
            }
        }

    }
}
