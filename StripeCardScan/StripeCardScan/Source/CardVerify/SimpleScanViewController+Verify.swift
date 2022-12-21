import UIKit

extension SimpleScanViewController {
    func showFullScreenActivityIndicator() {
        let container = UIView()
        self.view.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.setAnchorsEqual(to: self.view)
        container.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.7462275257)

        let activityIndicator = UIActivityIndicatorView()

        if #available(iOS 13.0, *) {
            activityIndicator.style = .large
            activityIndicator.color = .white
        } else {
            activityIndicator.style = .whiteLarge
        }

        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        container.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        activityIndicator.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: container.centerYAnchor).isActive = true
    }
}
