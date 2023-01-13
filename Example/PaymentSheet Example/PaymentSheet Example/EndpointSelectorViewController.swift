//
//  EndpointSelector.swift
//  PaymentSheet Example
//

import Foundation
import UIKit

protocol EndpointSelectorViewControllerDelegate: AnyObject {
    func selected(endpoint: String)
    func cancelTapped()
}

class EndpointSelectorViewController: UITableViewController {
    let reuseIdentifierEndpointCell = "endpointCell"
    let endpointSelectorEndpoint: String
    var currentCheckoutEndpoint: String

    weak var selectorDelegate: EndpointSelectorViewControllerDelegate?
    var endpointSpecs: EndpointSpec?
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(delegate: EndpointSelectorViewControllerDelegate,
         endpointSelectorEndpoint: String,
         currentCheckoutEndpoint: String) {
        self.selectorDelegate = delegate
        self.endpointSelectorEndpoint = endpointSelectorEndpoint
        self.currentCheckoutEndpoint = currentCheckoutEndpoint
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifierEndpointCell)
        loadEndpointSelector(endpoint: endpointSelectorEndpoint)
        setBarButtonItems()
    }

    func setBarButtonItems() {
        let barButtonItem = UIBarButtonItem(title: "Set Manually", style: .plain, target: self, action: #selector(didTapSetManually))
        navigationItem.rightBarButtonItems = [barButtonItem]
        let cancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(didTapCancel))
        navigationItem.leftBarButtonItems = [cancel]
    }

    @objc func didTapCancel() {
        self.selectorDelegate?.cancelTapped()
    }

    @objc func didTapSetManually() {
        let alertController = UIAlertController(title: "Set Endpoint Manually", message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.text = self.currentCheckoutEndpoint
        }

        let submitAction = UIAlertAction(title: "Submit", style: .default) { [unowned alertController] _ in
            guard let textFields = alertController.textFields,
                  let input = textFields[0].text else {
                return
            }
            self.selectorDelegate?.selected(endpoint: input)
            self.navigationController?.popViewController(animated: true)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(submitAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
}

// MARK: - TableViewController
extension EndpointSelectorViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        guard let specs = endpointSpecs else {
            return 2
        }
        return specs.endpointMap.count + 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection sectionNumber: Int) -> Int {
        if sectionNumber == 0 {
            return 1
        }
        let sectionNumberIndex = sectionNumber - 1
        guard let specs = endpointSpecs,
              let sortedSection = sortedSections() else {
            return 0
        }
        let sectionKey = sortedSection[sectionNumberIndex].key
        return specs.endpointMap[sectionKey]?.count ?? 0
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection sectionNumber: Int) -> String? {
        if sectionNumber == 0 {
            return "Current Endpoint"
        }

        let sectionNumberIndex = sectionNumber - 1
        guard let sortedSection = sortedSections() else {
            return "Loading..."
        }
        return sortedSection[sectionNumberIndex].key
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifierEndpointCell, for: indexPath)
        guard let endpoint = endpoint(for: indexPath) else {
            return cell
        }
        cell.textLabel?.text = endpoint
        cell.textLabel?.font = .preferredFont(forTextStyle: .caption1)
        cell.textLabel?.numberOfLines = 0
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let endpoint = endpoint(for: indexPath) else {
            return
        }
        self.selectorDelegate?.selected(endpoint: endpoint)
        self.navigationController?.popViewController(animated: true)
    }
}
// MARK: Cheap Data provider
extension EndpointSelectorViewController {
    func loadEndpointSelector(endpoint: String) {
        let request = URLRequest(url: URL(string: endpoint)!)
        let session = URLSession.shared.dataTask(with: request) { data, _, error in
            guard error == nil,
                  let data = data,
                  let specs = self.deserializeResponse(data: data) else {
                fatalError("FAILED on endpoint selector url request")
            }
            self.endpointSpecs = specs
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        session.resume()
    }
    func deserializeResponse(data: Data) -> EndpointSpec? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(EndpointSpec.self, from: data)
        } catch {
            return nil
        }
    }
}

// MARK: - Helpers
extension EndpointSelectorViewController {
    func endpoint(for indexPath: IndexPath) -> String? {
        guard indexPath.section != 0 else {
            return currentCheckoutEndpoint
        }
        guard let specs = endpointSpecs,
              let sortedSection = sortedSections() else {
            return nil
        }
        let sectionKey = sortedSection[indexPath.section-1].key
        guard let endpointsInSection = specs.endpointMap[sectionKey] else {
            return nil
        }
        return endpointsInSection[indexPath.row]
    }

    func sortedSections() -> [Dictionary<String, [String]>.Element]? {
        guard let specs = endpointSpecs else {
            return nil
        }
        return specs.endpointMap.sorted { $0.key < $1.key }
    }
}

struct EndpointSpec: Codable {
    let endpointMap: [String: [String]]

    private enum CodingKeys: String, CodingKey {
        case endpointMap
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.endpointMap = try container.decode([String: [String]].self, forKey: .endpointMap)
    }
}
