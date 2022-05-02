<img src="../readme-images/FinancialConnections-light-80x80.png" width="40" /> Stripe Financial Connections iOS SDK (Beta)
======

Stripe Financial Connections iOS SDK lets your users securely share their financial data by linking their external financial accounts to your business in your iOS app.

# Table of contents

<!--ts-->
* [Features](#features)
* [Requirements](#requirements)
* [Getting started](#getting-started)
   * [Integration](#integration)
   * [Example](#example)
* [Manual linking](#manual-linking)

<!--te-->

## Features

**Prebuilt UI**: We provide [`FinancialConnectionsSheet`](https://stripe.dev/stripe-ios/stripe-financialconnections/Classes/FinancialConnectionsSheet.html), a prebuilt UI that combines all the steps required for your users to linking their external financial accounts to your business.

Data retrieved through Financial Connections can help you unlock a variety of use cases, including:

- Tokenized account and routing numbers let you instantly verify bank accounts for ACH Direct Debit payments.
- Real-time balance data helps you avoid fees from insufficient funds failures before initiating a bank-based payment or wallet transfer.
- Account ownership information, such as the name and address of the bank accountholder, helps you mitigate fraud when onboarding a customer or merchant.
- Transactions data that you can use to help users track expenses, handle bills, manage their finances, and take control of their financial well-being.
- Transactions and balance data helps you speed up underwriting and improve access to credit and other financial services.



## Requirements

The Stripe Financial Connections iOS SDK is compatible with apps targeting iOS 12.0 or above.

## Getting started

### Integration

Get started with Stripe Financial Connections [📚 iOS integration guide](https://stripe.com/docs/financial-connections/other-data-powered-products?platform=ios) and [example project](../Example/FinancialConnections%20Example), or [📘 browse the SDK reference](https://stripe.dev/stripe-ios/stripe-financialconnections/index.html) for fine-grained documentation of all the classes and methods in the SDK.

### Example

[Financial Connections Example](../Example/FinancialConnections%20Example) – This example demonstrates how to let your user link their external financial accounts.

## Manual linking

If you link the Stripe Financial Connections library manually, use a version from our [releases](https://github.com/stripe/stripe-ios/releases) page and make sure to embed <ins>all</ins> of the following frameworks:
- `StripeFinancialConnections.xcframework`
- `StripeCore.xcframework`
- `StripeUICore.xcframework`