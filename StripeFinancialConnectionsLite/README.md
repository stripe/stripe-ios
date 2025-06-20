```
  ______    _____   _       _  _          
 |  ____|  / ____| | |     (_)| |         
 | |__    | |      | |      _ | |_   ___  
 |  __|   | |      | |     | || __| / _ \ 
 | |      | |____  | |____ | || |_ |  __/ 
 |_|       \_____| |______||_| \__| \___| 
```

## FinancialConnectionsLite

FinancialConnectionsLite is a lightweight version of the `StripeFinancialConnections` SDK. It is a simple web wrapper that allows users to go through the Stripe pay-by-bank flow without requiring an additional dependency on the `StripeFinancialConnections` SDK. It is intended to be used in scenarios where the full SDK is not available.

When a `returnUrl` is provided, FinancialConnectionsLite supports app-to-app authentication with compatible banks (such as Chase) when their app is installed on the user's device. Otherwise, the bank's authentication flow will open in a secure browser window. [Learn more](https://docs.stripe.com/financial-connections/other-data-powered-products?platform=ios#ios-set-up-return-url) about setting up a return URL.