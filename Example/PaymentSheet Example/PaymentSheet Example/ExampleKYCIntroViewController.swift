//
//  ExampleKYCIntroViewController.swift
//  PaymentSheet Example
//
//  Created by Mat Schmid on 6/22/25.
//

import UIKit

class ExampleKYCIntroViewController: UIViewController {

    // MARK: - UI Elements

    private lazy var heroImageView: UIView = {
        let placeholderView = UIView()
        placeholderView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        placeholderView.layer.cornerRadius = 12
        placeholderView.translatesAutoresizingMaskIntoConstraints = false

        // Add placeholder label
        let label = UILabel()
        label.text = "Hero Image"
        label.textColor = UIColor.white.withAlphaComponent(0.5)
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        placeholderView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: placeholderView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: placeholderView.centerYAnchor),
        ])

        return placeholderView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Let's verify your identity"
        label.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "This process is performed by Link by Stripe, who will collect and review your information. This can take 5-10 minutes. You'll need to provide:"
        label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        label.textColor = UIColor.white.withAlphaComponent(0.7)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var requirementsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Continue", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.setTitleColor(UIColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1.0), for: .normal)
        button.backgroundColor = UIColor(red: 152/255, green: 134/255, blue: 229/255, alpha: 1.0) // #9886E5
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var whyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Why do I need to do this?", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        button.setTitleColor(UIColor(red: 152/255, green: 134/255, blue: 229/255, alpha: 1.0), for: .normal)
        button.backgroundColor = UIColor(red: 42/255, green: 42/255, blue: 42/255, alpha: 1.0)
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        button.addTarget(self, action: #selector(whyButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Properties

    private var continueButtonBottomConstraint: NSLayoutConstraint!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupRequirements()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBarAppearance()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0)

        // Add scroll view and content view
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // Add UI elements to content view
        contentView.addSubview(heroImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(requirementsStackView)
        contentView.addSubview(whyButton)

        // Add continue button directly to main view (not scroll view)
        view.addSubview(continueButton)

        setupConstraints()
    }

    private func setupConstraints() {
        let safeArea = view.safeAreaLayoutGuide

        // Continue button bottom constraint
        continueButtonBottomConstraint = continueButton.bottomAnchor.constraint(
            equalTo: safeArea.bottomAnchor,
            constant: 0
        )

        NSLayoutConstraint.activate([
            // Scroll view constraints
            scrollView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -20),

            // Content view constraints
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Hero image constraints
            heroImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            heroImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            heroImageView.widthAnchor.constraint(equalToConstant: 120),
            heroImageView.heightAnchor.constraint(equalToConstant: 120),

            // Title label constraints
            titleLabel.topAnchor.constraint(equalTo: heroImageView.bottomAnchor, constant: 32),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Subtitle label constraints
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Requirements stack view constraints
            requirementsStackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            requirementsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            requirementsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Why button constraints
            whyButton.topAnchor.constraint(equalTo: requirementsStackView.bottomAnchor, constant: 32),
            whyButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            whyButton.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20),

            // Continue button constraints
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            continueButton.heightAnchor.constraint(equalToConstant: 50),
            continueButtonBottomConstraint,
        ])
    }

    private func setupRequirements() {
        // Create requirement items
        let requirements = [
            ("person.fill", "Your address, name, and date of birth.\nYou must be 18 or older."),
            ("creditcard.fill", "A driver's license, passport, or state ID."),
            ("building.columns.fill", "A state-issued id number (SSN or NIN)."),
        ]

        for (iconName, text) in requirements {
            let requirementView = createRequirementView(iconName: iconName, text: text)
            requirementsStackView.addArrangedSubview(requirementView)
        }
    }

    private func createRequirementView(iconName: String, text: String) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        // Icon
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: iconName)
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        // Text label
        let textLabel = UILabel()
        textLabel.text = text
        textLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        textLabel.textColor = .white
        textLabel.numberOfLines = 0
        textLabel.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(iconImageView)
        containerView.addSubview(textLabel)

        NSLayoutConstraint.activate([
            // Icon constraints
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),

            // Text label constraints
            textLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            textLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            textLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            textLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])

        return containerView
    }

    private func setupNavigationBar() {
        // Set navigation bar to be transparent with white elements
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.backgroundColor = .clear
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true

        // Hide the default back button
        navigationItem.hidesBackButton = true

        // Create custom back button with proper alignment
        setupCustomBackButton()
    }

    private func setupCustomBackButton() {
        // Create a custom back button
        let backButton = UIButton(type: .system)

        // Create a bolder chevron using font configuration
        let chevronConfig = UIImage.SymbolConfiguration(weight: .semibold)
        let chevronImage = UIImage(systemName: "chevron.left", withConfiguration: chevronConfig)

        backButton.setImage(chevronImage, for: .normal)
        backButton.tintColor = .white
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)

        // Set the button size
        backButton.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        backButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -24, bottom: 0, right: 0)

        // Create bar button item with the custom button
        let customBackButton = UIBarButtonItem(customView: backButton)

        // Add negative spacer to align with title (20pt from edge)
        let negativeSpacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        negativeSpacer.width = -4 // Adjust this value to fine-tune alignment

        navigationItem.leftBarButtonItems = [negativeSpacer, customBackButton]
    }

    private func setupNavigationBarAppearance() {
        // Configure navigation bar appearance for iOS 13+
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .clear
            appearance.shadowColor = .clear

            // Set back button appearance
            appearance.setBackIndicatorImage(UIImage(systemName: "chevron.left"), transitionMaskImage: UIImage(systemName: "chevron.left"))

            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
            navigationController?.navigationBar.compactAppearance = appearance
        }

        // Ensure tint color is white
        navigationController?.navigationBar.tintColor = .white
    }

    // MARK: - Actions

    @objc private func continueButtonTapped() {
        // Handle continue action - navigate to next screen
        print("Continue tapped - proceed to KYC flow")
    }

    @objc private func whyButtonTapped() {
        // Handle why button tap - show explanation
        print("Why button tapped - show explanation")
    }

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
}
