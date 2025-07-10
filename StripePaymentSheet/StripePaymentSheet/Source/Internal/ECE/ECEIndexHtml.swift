//
//  ECEIndexHtml.swift
//  StripePaymentSheet
//

struct ECEIndexHTML {
    let shopId: String
    let customerSessionClientSecret: String
    var shopPayHTMLString: String {
        return !shopId.isEmpty ?
"""
          paymentMethodOptions: {
            shop_pay: {
              shop_id: "\(shopId)",
            },
          },
"""
        : ""
    }
    var ECEHTML: String {
"""
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <script src="https://js.stripe.com/v3/"></script>
    <title>Stripe Mobile SDK ECE Bridge</title>
  </head>
  <body>
    <div id="express-checkout-element">
    </div>

    <script>
    function hashToString(hash) {
      return JSON.stringify(hash, 0, 2);
    }

    var ECE_OPTIONS = JSON.parse(`
      {
        "layout": {
          "maxColumns": 1,
          "maxRows": 0,
          "overflow": "never"
        }
      }
    `);

    function initializeStripeElements() {
        var options = {
          mode: "payment",
          amount: window.NATIVE_AMOUNT_TOTAL,
          currency: "usd",
          payment_method_types: ["card", "link", "shop_pay"],
          customerSessionClientSecret: "\(customerSessionClientSecret)",
          __elementsInitSource: 'native_sdk',
          \(shopPayHTMLString)
        };

      console.log("Initializing stripe elements with options", options);

      let stripe, elements, expressCheckoutElement;

      try {
        stripe = window.Stripe(getStripePublishableKey(), {});
      } catch (error) {
        console.error("Error creating Stripe instance:", error);
        console.log(`❌ Failed to create Stripe instance: ${error.message}`);
        throw error;
      }

      try {
        elements = stripe.elements(options);
      } catch (error) {
        console.error("Error creating Elements with options:", options, error);
        console.log(`❌ Failed to create Elements: ${error.message}`);
        throw error;
      }

      try {
        expressCheckoutElement = elements.create(
          "expressCheckout",
          ECE_OPTIONS
        );
      } catch (error) {
        console.error("Error creating Express Checkout Element:", error);
        console.log(`❌ Failed to create Express Checkout Element: ${error.message}`);
        throw error;
      }
      var mode = options["mode"];
      var captureMethod = options["captureMethod"]
        ? options["captureMethod"]
        : "automatic";
        console.log("Ready to mount");

      expressCheckoutElement.mount("#express-checkout-element");

      //When expressCheckoutElement is mounted, ready event tries to show the available payment methods
      expressCheckoutElement.on("ready", ({ availablePaymentMethods }) => {
        const expressCheckoutDiv = document.getElementById(
          "express-checkout-element"
        );
        if (!availablePaymentMethods) {
          console.log("No Payment Options Available");
        } else {
          expressCheckoutDiv.style.visibility = "initial";
        }

        setTimeout(() => {
            expressCheckoutElement._sendNativeSdkClick({paymentMethodType: 'shop_pay'})
        }, 0)
      });

      expressCheckoutElement.on("click", async function (event) {
        console.log(`Click received with event:\n${hashToString(event)}`);
        try {
          // Extract only serializable data from the event
          // The event object contains functions (resolve, complete) that can't be cloned
          // for message passing, so we only send the data we need
          const eventData = {
            walletType: event.walletType,
            expressPaymentType: event.expressPaymentType
          };

          const resolvePayload = await window.NativeStripeECE.handleClick(eventData);

          console.log(`Bridge response:\n${hashToString(resolvePayload)}`);

          event.resolve(resolvePayload);
        } catch (error) {
          console.error("ECE click error:", error);

          // On error, reject the click
          event.reject();
        }
      });

      expressCheckoutElement.on("shippingaddresschange", async function (event) {
        console.log(
          `ShippingAddressChange: Name: ${event.name}\nAddress:\n${hashToString(
            event.address
          )}`
        );

        try {
            const response = await window.NativeStripeECE.calculateShipping({
              name: event.name,
              address: event.address
            });

            console.log(`Bridge Response:\n${hashToString(response)}`);

            // Check if merchant rejected the address
            if (response.error) {
              console.log(`Shipping rejected: ${response.error}`);
              event.reject();
              return;
            }

            // Update the total amount from the response if provided
            if (response.totalAmount) {
              elements.update({ amount: response.totalAmount });
            }

            event.resolve({
              shippingRates: response.shippingRates,
              lineItems: response.lineItems,
              applePay: response.applePay
            });
        } catch (error) {
          console.log(`Error calculating shipping: ${error.message}`);
          console.error("Shipping calculation error:", error);

          // On error, reject the shipping address
          event.reject();
        }
      });

      expressCheckoutElement.on("shippingratechange", async function (event) {
        console.log(`Selected Shipping Rate:\n${hashToString(event.shippingRate)}`);
        console.log("Shipping rate change event:", event);

        try {
            const response = await window.NativeStripeECE.calculateShippingRateChange(event.shippingRate);

            console.log(`Bridge response:\n${hashToString(response)}`);

            // Check if merchant rejected the rate
            if (response.error) {
              console.log(`Shipping rate rejected: ${response.error}`);
              event.reject();
              return;
            }

            // Update the total amount from the response if provided
            if (response.totalAmount) {
              elements.update({ amount: response.totalAmount });
            }

            event.resolve({
              lineItems: response.lineItems,
              shippingRates: response.shippingRates,
              applePay: response.applePay
            });
        } catch (error) {
          console.log(`Error validating shipping rate: ${error.message}`);
          console.error("Shipping rate validation error:", error);

          // On error, reject the shipping rate
          event.reject();
        }
      });

      expressCheckoutElement.on("cancel", function () {
        console.log("cancel");
      });

      //Observes confirm action & responds with return_url, elements & clientSecret for completing transaction
      expressCheckoutElement.on("confirm", async (event) => {
        console.log(
          `Confirm: BillingDetails:\n${hashToString(
            event.billingDetails
          )}\nShippingAddress:\n${hashToString(
            event.shippingAddress
          )}\nShippingRate:\n${hashToString(event.shippingRate)}}}`
        );
        console.log("confirm payment event triggered", event);

        const { error: submitError } = await elements.submit();
        if (submitError) {
          console.log("submit error");
          return;
        }

        try {
            // Prepare payment details for native processing
            const paymentDetails = {
              billingDetails: event.billingDetails,
              shippingAddress: event.shippingAddress,
              shippingRate: event.shippingRate,
              mode: mode,
              captureMethod: captureMethod,
              paymentMethodOptions: event._paymentMethodOptions,
            };

            const response = await window.NativeStripeECE.confirmPayment(paymentDetails);

            console.log(`Native Payment API Response:\n${hashToString(response)}`);
        } catch (error) {
          console.log(`Error confirming payment: ${error.message}`);
          console.error("Payment confirmation error:", error);
          event.paymentFailed({ reason: error.message });
        }
      });
    }

    // Function to initialize everything - called from Swift
    function initializeApp() {
      try {
        initializeStripeElements();
      } catch (error) {
        console.error("Error initializing Stripe Elements:", error);
        console.log(`❌ Failed to initialize Stripe Elements: ${error.message}`);
        // Re-throw to maintain error propagation if needed
        throw error;
      }
    }
    console.log("Waiting for bridge to call initializeApp()");
    </script>
  </body>
</html>
"""
    }
}
