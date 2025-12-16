//
//  PMMEPlaygroundUIViewController.swift
//  PaymentSheet Example
//
//  Created by George Birch on 10/27/25.
//

@_spi(PaymentMethodMessagingElementPreview) import StripePaymentSheet
import UIKit

class PMMEPlaygroundUIViewController: UIViewController {

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let productImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        imageView.layer.cornerRadius = 12
        return imageView
    }()

    private lazy var productPriceLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 24, weight: .semibold)
        label.textColor = .systemBlue
        label.text = "$\(config.amount / 100)"
        return label
    }()

    private let pmmeContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let productDescriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.text = "Experience superior sound quality with our premium wireless headphones. Featuring active noise cancellation, 30-hour battery life, and comfortable over-ear design."
        return label
    }()

    private let config: PaymentMethodMessagingElement.Configuration

    init(config: PaymentMethodMessagingElement.Configuration) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }

    // MARK: - Setup Methods

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(productImageView)
        contentView.addSubview(productPriceLabel)
        contentView.addSubview(pmmeContainerView)
        contentView.addSubview(productDescriptionLabel)

        productImageView.image = UIImage(systemName: "headphones")
        productImageView.tintColor = .systemGray3

        Task { @MainActor in
            let elementResult = await PaymentMethodMessagingElement.create(configuration: config)
            if case .success(let paymentMethodMessagingElement) = elementResult {
                let view = paymentMethodMessagingElement.view
                view.translatesAutoresizingMaskIntoConstraints = false
                pmmeContainerView.addSubview(view)
                NSLayoutConstraint.activate([
                    view.leadingAnchor.constraint(equalTo: pmmeContainerView.leadingAnchor),
                    view.trailingAnchor.constraint(equalTo: pmmeContainerView.trailingAnchor),
                    view.bottomAnchor.constraint(equalTo: pmmeContainerView.bottomAnchor),
                    view.topAnchor.constraint(equalTo: pmmeContainerView.topAnchor),
                ])
            }
        }
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView constraints
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // ContentView constraints
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Product Image constraints
            productImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            productImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            productImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            productImageView.heightAnchor.constraint(equalToConstant: 300),

            // Product Price constraints
            productPriceLabel.topAnchor.constraint(equalTo: productImageView.bottomAnchor, constant: 20),
            productPriceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            productPriceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // PMME
            pmmeContainerView.topAnchor.constraint(equalTo: productPriceLabel.bottomAnchor, constant: 20),
            pmmeContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            pmmeContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Product Description constraints
            productDescriptionLabel.topAnchor.constraint(equalTo: pmmeContainerView.bottomAnchor, constant: 16),
            productDescriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            productDescriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            productDescriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),
        ])
    }
}
