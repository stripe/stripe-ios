//
//  ExampleListViewController.swift
//  FinancialConnections Example
//
//  Created by Vardges Avetisyan on 4/13/22.
//

import Foundation
import UIKit

struct Example {
    let title: String
    let viewControllerIdentifier: String
}

class ExampleListViewController: UITableViewController {

    // MARK: - Properties

    private let examples: [Example] = [
        Example(title: "Connect Account", viewControllerIdentifier: "ConnectAccountViewController"),
        Example(title: "Collect Bank Account Token", viewControllerIdentifier: "CollectBankAccountTokenViewController"),
    ]

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Constants.cellIdentifier)
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return examples.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath)

        if #available(iOS 14.0, *) {
            var configuration = cell.defaultContentConfiguration()
            configuration.text = examples[indexPath.row].title
            cell.contentConfiguration = configuration
        } else {
            cell.textLabel?.text = examples[indexPath.row].title
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return getBuildInfo()
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let example = examples[indexPath.row]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: example.viewControllerIdentifier)
        navigationController?.pushViewController(viewController, animated: true)
    }


}

// MARK: - Constants

extension ExampleListViewController {
    struct Constants {
        static let cellIdentifier = "cellIdentifier"
    }
}


// MARK: - Version Info

extension ExampleListViewController {
    private func getBuildInfo() -> String {
        guard let infoDictionary = Bundle.main.infoDictionary,
              let version = infoDictionary["CFBundleShortVersionString"] as? String,
              let build = infoDictionary["CFBundleVersion"] as? String else {
            return ""
        }
        return "v\(version) build \(build)"
    }
}
