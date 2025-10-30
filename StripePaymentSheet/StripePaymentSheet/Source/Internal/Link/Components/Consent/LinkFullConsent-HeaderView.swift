//
//  LinkFullConsent-HeaderView.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 8/24/25.
//

@_spi(STP) import StripeUICore
import UIKit

final class LinkFullConsentHeaderView: UIView {
    private static let merchantLogoImageSize: CGFloat = 64

    private let merchantLogoURL: URL?
    private let titleText: String

    private lazy var merchantLogoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = LinkUI.cornerRadius
        imageView.clipsToBounds = true
        imageView.image = Image.business_placeholder.makeImage()
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = titleText
        // Custom extra large bold font for this label.
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textColor = .linkTextPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var containerStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            merchantLogoImageView,
            titleLabel,
        ])
        stackView.axis = .vertical
        stackView.spacing = LinkUI.largeContentSpacing
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    init(merchantLogoURL: URL?, title: String) {
        self.merchantLogoURL = merchantLogoURL
        self.titleText = title
        super.init(frame: .zero)
        setupUI()
        loadMerchantLogo()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addAndPinSubview(containerStackView)

        NSLayoutConstraint.activate([
            merchantLogoImageView.widthAnchor.constraint(equalToConstant: Self.merchantLogoImageSize),
            merchantLogoImageView.heightAnchor.constraint(equalToConstant: Self.merchantLogoImageSize),
        ])
    }

    private func loadMerchantLogo() {
        guard let merchantLogoURL else { return }
        merchantLogoImageView.setImage(from: merchantLogoURL)
    }
}

// MARK: - UIImageView Extension

private extension UIImageView {
    func setImage(from url: URL) {
        Task {
            guard let image = try? await DownloadManager.sharedManager.downloadImage(url: url) else {
                return
            }

            await MainActor.run {
                self.image = image
            }
        }
    }
}
