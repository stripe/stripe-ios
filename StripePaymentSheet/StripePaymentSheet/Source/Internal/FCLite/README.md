```
  ______    _____   _       _  _          
 |  ____|  / ____| | |     (_)| |         
 | |__    | |      | |      _ | |_   ___  
 |  __|   | |      | |     | || __| / _ \ 
 | |      | |____  | |____ | || |_ |  __/ 
 |_|       \_____| |______||_| \__| \___| 
```

## FinancialConnectionsLite

FinancialConnectionsLite is a lightweight version of the `StripeFinancialConnections` SDK. It is a simple web wrapper that allows users to through the Stripe pay-by-bank flows without requiring an additional dependency on the `StripeFinancialConnections` SDK. It is intended to be used in scenarios where the full SDK is not available.

FCLite requires a `returnUrl` to redirect back to the host app after completing authentication in another app (such as a bank app or Safari).
