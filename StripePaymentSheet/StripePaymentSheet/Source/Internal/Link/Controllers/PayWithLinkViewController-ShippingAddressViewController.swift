//
//  PayWithLinkViewController-ShippingAddressViewController.swift
//  StripePaymentSheet
//

import UIKit

@_spi(STP) import StripeUICore

extension PayWithLinkViewController {

    /// Displays the list of saved shipping addresses and an option to add a new one.
    final class ShippingAddressViewController: BaseViewController {

        private let viewModel: WalletViewModel
        private let linkAccount: PaymentSheetLinkAccount
        private let onAddressSelected: (ShippingAddressesResponse.ShippingAddress) -> Void

        private lazy var addAddressButton: UIControl = {
            let control = UIControl()
            control.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)

            let label = UILabel()
            label.text = STPLocalizedString(
                "Add address",
                "Button to add a new shipping address in the Link wallet."
            )
            label.font = LinkUI.font(forTextStyle: .bodyEmphasized)
            label.textColor = .linkTextBrand
            label.adjustsFontForContentSizeCategory = true
            label.isUserInteractionEnabled = false
            label.translatesAutoresizingMaskIntoConstraints = false
            control.addSubview(label)
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: control.layoutMarginsGuide.topAnchor),
                label.bottomAnchor.constraint(equalTo: control.layoutMarginsGuide.bottomAnchor),
                label.leadingAnchor.constraint(equalTo: control.layoutMarginsGuide.leadingAnchor),
                label.trailingAnchor.constraint(lessThanOrEqualTo: control.layoutMarginsGuide.trailingAnchor),
            ])
            control.addTarget(self, action: #selector(addAddressTapped), for: .touchUpInside)
            return control
        }()

        private lazy var addressListStackView: UIStackView = {
            let stack = UIStackView()
            stack.axis = .vertical
            stack.spacing = 0
            return stack
        }()

        private lazy var listStackView: UIStackView = {
            let stack = UIStackView(arrangedSubviews: [addressListStackView, addAddressButton])
            stack.axis = .vertical
            stack.spacing = 0
            return stack
        }()

        private lazy var listContainerView: UIView = {
            let view = UIView()
            view.backgroundColor = .linkSurfaceSecondary
            view.clipsToBounds = true
            if let cornerRadius = LinkUI.appearance.cornerRadius {
                view.layer.cornerRadius = cornerRadius
            } else {
                view.ios26_applyDefaultCornerConfiguration()
            }
            view.layer.borderColor = UIColor.linkBorderDefault.cgColor
            view.tintColor = .linkIconBrand
            return view
        }()

        init(
            linkAccount: PaymentSheetLinkAccount,
            viewModel: WalletViewModel,
            onAddressSelected: @escaping (ShippingAddressesResponse.ShippingAddress) -> Void
        ) {
            self.linkAccount = linkAccount
            self.viewModel = viewModel
            self.onAddressSelected = onAddressSelected
            super.init(
                context: viewModel.context,
                navigationTitle: STPLocalizedString(
                    "Shipping address",
                    "Navigation title for the shipping address selection screen."
                )
            )
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            setupUI()
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            reloadAddressList()
        }

        private func setupUI() {
            listContainerView.addAndPinSubview(listStackView)

            let outerStackView = UIStackView(arrangedSubviews: [listContainerView])
            outerStackView.axis = .vertical
            outerStackView.isLayoutMarginsRelativeArrangement = true
            outerStackView.directionalLayoutMargins = preferredContentMargins
            contentView.addAndPinSubview(outerStackView, insets: .insets(bottom: LinkUI.bottomInset))
        }

        private func reloadAddressList() {
            addressListStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

            let addresses = viewModel.filteredShippingAddresses
            let selectedID = viewModel.selectedShippingAddressID

            for (index, address) in addresses.enumerated() {
                let cell = LinkShippingAddressCell()
                cell.isSelected = (address.id == selectedID)
                cell.showsSeparator = true
                cell.configure(with: address)
                cell.tag = index
                cell.addTarget(self, action: #selector(cellTapped(_:)), for: .touchUpInside)
                addressListStackView.addArrangedSubview(cell)
            }
        }

        @objc private func cellTapped(_ sender: LinkShippingAddressCell) {
            let addresses = viewModel.filteredShippingAddresses
            guard addresses.indices.contains(sender.tag) else { return }
            let selected = addresses[sender.tag]
            onAddressSelected(selected)
            _ = bottomSheetController?.popContentViewController()
        }

        @objc private func addAddressTapped() {
            let addVC = AddShippingAddressViewController(
                linkAccount: linkAccount,
                viewModel: viewModel,
                onAddressCreated: { [weak self] address in
                    self?.viewModel.addShippingAddress(address)
                    self?.onAddressSelected(address)
                    _ = self?.bottomSheetController?.popContentViewController()
                    _ = self?.bottomSheetController?.popContentViewController()
                }
            )
            bottomSheetController?.pushContentViewController(addVC)
        }
    }
}
