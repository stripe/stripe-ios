//
//  FruitModel.swift
//  FruitStore
//

import Foundation
import UIKit
import AuthenticationServices

class FruitModel: ObservableObject {
    /// The current customer's details
    @Published var customer: Customer? = .fetchFromUserDefaults()
    /// Whether a request is in progress
    @Published var loading = false
    
    /// The last time the cached Customer was updated.
    var lastUpdated: Date = .distantPast
    
    /// The last error communicating with the server, if any.
    @Published var lastError: ServerError?
    
    /// The FruitStore server
    let server: Server = MockServer()
    
    // MARK: Authentication
    
    /// Login using credentials from a Sign in with Apple button.
    func login(_ authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            server.fetchSessionToken(with: appleIDCredential) { result in
                switch result {
                case .success(_): break
                case .failure(let error):
                    self.lastError = error
                }
                self.updateFromServer(force: true)
            }
        } else {
            // Error
        }
    }
    
    /// Login with a temporary account.
    /// In a real app, you should not allow the user to make purchases unless you
    /// have some way of identifying the user after the app has been deleted. Otherwise,
    /// a user may not be able to restore their purchased content after deleting your app.
    func loginGuest() {
        server.fetchGuestSessionToken { result in
            switch result {
            case .success(_): break
            case .failure(let error):
                self.lastError = error
            }
            self.updateFromServer(force: true)
        }
    }
    
    /// Delete the user's stored cache and credentials.
    func logout() {
        customer?.clearUserDefaults()
        customer = nil
        server.logout()
    }
    
    // MARK: User inventory management
    
    /// Update the customer model from the server. This will only update
    /// a maximum of once every 60 seconds unless `force` is true.
    func updateFromServer(force: Bool) {
        if force ||
            (!loading && lastUpdated.addingTimeInterval(60) < Date()) {
            loading = true
            // Fetch latest customer info from server
            server.fetchCustomer { result in
                switch result {
                case .success(let customer):
                    self.customer = customer
                    customer.writeToUserDefaults()
                    self.lastUpdated = Date()
                    self.lastError = nil
                case .failure(let error):
                    // If we have a cached Customer, we can use those details until our next sync.
                    // This is convenient for productivity software or offline games, but it introduces
                    // a potential vulnerability: A user could modify their NSUserDefaults and block
                    // your server to unlock content.
                    // For certain types of content, you may want to always check the server before
                    // granting the user access.
                    self.lastError = error
                }
                self.loading = false
            }
        }
    }
    
    /// Attempt to buy a fruit.
    func buy(_ fruit: Fruit) {
        self.loading = true
        server.buy(fruit: fruit) { result in
            switch result {
            case .success(let customer):
                self.customer = customer
                customer.writeToUserDefaults()
                self.lastUpdated = Date()
                self.lastError = nil
            case .failure(let error):
                self.lastError = error
            }
            self.loading = false
        }
    }
    
    /// Open a Checkout page to refill the user's coin balance.
    func openRefillPage() {
        server.getRefillURL { result in
            switch result {
            case .success(let url):
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            case .failure(let error):
                self.lastError = error
            }
        }
        
        /// TODO: Remove me!
        /// If we're using the MockServer, we'll want to simulate a coin refill immediately.
        if let server = self.server as? MockServer {
            server.refillCoins()
        }
    }
    
    /// Called by the URL handler when we receive a deep link from Checkout
    /// back to our app.
    func didCompleteRefill(url: URL) {
        // After the customer pays, Checkout will send a `checkout.session.completed` to
        // your server's webhook. Checkout will wait up to 10 seconds for your backend to
        // acknowledge the event before redirecting the user to your `success_url`, which
        // should be a Universal Link to your app.
        //
        // In scenarios where your endpoint is down or the event isn’t acknowledged properly,
        // the customer could be redirected to the `success_url` before you have updated
        // your customer object with the new purchase. In this situation, you may want to
        // retry this update call until the customer object is up to date.
        //
        // See https://stripe.com/docs/payments/checkout/fulfill-orders#handle-the-event
        // for more details.
        
        updateFromServer(force: true)
    }
    
}

/// A purchasable fruit.
struct Fruit: Codable {
    var emoji: String
    
    var name: String {
        // TODO: Don't hardcode these.
        switch emoji {
        case "🍒":
            return "Cherries"
        case "🍊":
            return "Orange"
        case "🍉":
            return "Watermelon"
        default:
            return "Emoji"
        }
    }
}

/// Details about the customer's list of purchases.
struct Customer {
    /// The customer's name.
    var name: String
    /// The current balance in the customer's coin wallet.
    var wallet: Int
    /// The list of fruits owned by the customer.
    var purchased: [Fruit]
    /// Whether the customer has an active Pro subscription.
    var hasProSubscription: Bool
    
    init(name: String,
         wallet: Int,
         purchased: [Fruit],
         hasProSubscription: Bool) {
        self.name = name
        self.wallet = wallet
        self.purchased = purchased
        self.hasProSubscription = hasProSubscription
    }
    
    init?(_ params: [String: Any]) {
        guard let balance = params["balance"] as? Int,
        let fruit = params["fruits"] as? [String] else {
            return nil
        }
        self.name = params["name"] as? String ?? "Katie Bell"
        self.wallet = balance
        self.purchased = fruit.map({Fruit(emoji: $0)})
        // Always true until we add subscription support to the demo
        self.hasProSubscription = true
    }
    
    static let NameKey = "name"
    static let WalletKey = "wallet"
    static let PurchasedKey = "purchased"
    static let HasProSubscriptionKey = "hasProSubscription"
}

/// Customer cache
extension Customer {
    /// Saves a Customer in the UserDefaults cache.
    func writeToUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(name, forKey: Self.NameKey)
        defaults.set(wallet, forKey: Self.WalletKey)
        defaults.set(try? PropertyListEncoder().encode(purchased), forKey: Self.PurchasedKey)
        defaults.set(hasProSubscription, forKey: Self.HasProSubscriptionKey)
    }
    
    /// Clears the Customer from the UserDefaults cache.
    func clearUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(nil, forKey: Self.NameKey)
        defaults.set(nil, forKey: Self.WalletKey)
        defaults.set(nil, forKey: Self.PurchasedKey)
        defaults.set(nil, forKey: Self.HasProSubscriptionKey)
    }
    
    /// Initializes a Customer from the UserDefaults cache if available.
    static func fetchFromUserDefaults() -> Customer? {
        let defaults = UserDefaults.standard
        if let data = defaults.object(forKey: PurchasedKey) as? Data,
           let name = defaults.string(forKey: NameKey) {
            let wallet = defaults.integer(forKey: WalletKey)
            let hasProSubscription = defaults.bool(forKey: HasProSubscriptionKey)
            let purchased = (try? PropertyListDecoder().decode([Fruit].self, from: data)) ?? []
            return Customer(name: name, wallet: wallet, purchased: purchased, hasProSubscription: hasProSubscription)
        }
        return nil
    }
    
}
