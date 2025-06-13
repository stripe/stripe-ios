//
//  ECEIndexHtml.swift
//  StripePaymentSheet
//

let ECEHTML = """
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
        };

      console.log("Initializing stripe elements with options", options);

      let stripe, elements, expressCheckoutElement;

      try {
        stripe = window.Stripe(getStripePublishableKey(), {});
        console.log("Created Stripe");
      } catch (error) {
        console.error("Error creating Stripe instance:", error);
        console.log(`❌ Failed to create Stripe instance: ${error.message}`);
        throw error;
      }

      try {
        elements = stripe.elements(options);
        console.log("Created Elements");
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
        console.log("Created ECE");
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
      console.log("expressCheckoutElement", expressCheckoutElement);
      //When expressCheckoutElement is mounted, ready event tries to show the available payment methods
      expressCheckoutElement.on("ready", ({ availablePaymentMethods }) => {
        console.log("ready event triggered1");
        const expressCheckoutDiv = document.getElementById(
          "express-checkout-element"
        );
        if (!availablePaymentMethods) {
          console.log("No Payment Options Available");
        } else {
          expressCheckoutDiv.style.visibility = "initial";
        }
      });

      expressCheckoutElement.on("click", async function (event) {
        console.log(`Click received with event:\n${hashToString(event)}`);

        try {
          console.log("Using Native ECE Click Handler...");

          // Extract only serializable data from the event
          // The event object contains functions (resolve, complete) that can't be cloned
          // for message passing, so we only send the data we need
          const eventData = {
            walletType: event.walletType,
            expressPaymentType: event.expressPaymentType
          };

          // Call native API to handle the click
          // The native handler will provide all configuration like:
          // - billingAddressRequired, emailRequired, phoneNumberRequired
          // - shippingAddressRequired, allowedShippingCountries
          // - business name, line items, etc.
          const resolvePayload = await window.NativeECE.handleClick(eventData);

          console.log(`Native ECE Response:\n${hashToString(resolvePayload)}`);

          // Resolve the event with the payload from native
          event.resolve(resolvePayload);
        } catch (error) {
          console.log(`Error handling ECE click: ${error.message}`);
          console.error("ECE click error:", error);

          // On error, throw to let Stripe handle it
          throw error;
        }
      });

      expressCheckoutElement.on("shippingaddresschange", async function (event) {
        console.log(
          `ShippingAddressChange: Name: ${event.name}\nAddress:\n${hashToString(
            event.address
          )}`
        );

        // Transform address to match native API format
        const shippingAddress = {
          address1: event.address.addressLine ? event.address.addressLine[0] : "",
          address2: event.address.addressLine && event.address.addressLine[1] ? event.address.addressLine[1] : "",
          city: event.address.city || "",
          companyName: event.address.organization || "",
          countryCode: event.address.country || "US",
          email: "", // Not provided by Stripe ECE
          firstName: event.name ? event.name.split(' ')[0] : "",
          lastName: event.name ? event.name.split(' ').slice(1).join(' ') : "",
          phone: event.address.phone || "",
          postalCode: event.address.postalCode || "",
          provinceCode: event.address.state || ""
        };

        try {
          // Check if native API is available
          if (window.NativeShipping && window.NativeShipping.calculateShipping) {
            console.log("Using Native Shipping API...");

            // Call native API
            const response = await window.NativeShipping.calculateShipping(shippingAddress);

            console.log(`Native API Response:\n${hashToString(response)}`);

            // Check if merchant rejected the address
            if (response.merchantDecision === "rejected") {
              console.log(`Shipping rejected: ${response.error}`);
              event.reject();
              return;
            }

            // Update the total amount from the response
            if (response.totalAmount) {
              elements.update({ amount: response.totalAmount });
            }

            event.resolve({
              shippingRates: response.shippingRates,
              lineItems: response.lineItems
            });

          } else {
            // Resolve with an error
            console.log("Native Shipping API not available");
            event.reject();
          }

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
          // Check if native API is available
          console.log("Checking for native rate API...");
          console.log("window.NativeShipping:", window.NativeShipping);
          console.log("calculateShippingRateChange function:", window.NativeShipping?.calculateShippingRateChange);

          if (window.NativeShipping && window.NativeShipping.calculateShippingRateChange) {
            console.log("Using Native Shipping Rate API...");

            const response = await window.NativeShipping.calculateShippingRateChange(event.shippingRate);

            console.log(`Native Rate API Response:\n${hashToString(response)}`);

            // Check if merchant rejected the rate
            if (response.merchantDecision === "rejected") {
              console.log(`Shipping rate rejected: ${response.error || "Invalid shipping rate"}`);
              event.reject();
              return;
            }

            event.resolve();

          }

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

        //var paymentMethod = await stripe.createPaymentMethod({ elements });

        try {
          // Check if native API is available
          if (window.NativePayment && window.NativePayment.confirmPayment) {
            console.log("Using Native Payment API...");

            // Prepare payment details for native processing
            const paymentDetails = {
              billingDetails: event.billingDetails,
              shippingAddress: event.shippingAddress,
              shippingRate: event.shippingRate,
              mode: mode,
              captureMethod: captureMethod,
              //paymentMethod: paymentMethod,
            };

            // Call native API to create and confirm payment
            const response = await window.NativePayment.confirmPayment(paymentDetails);

            console.log(`Native Payment API Response:\n${hashToString(response)}`);

            // Use the response from native API
            const { clientSecret, paymentIntentId } = response;

            if (mode === "payment") {
              const confirmedPI = await stripe.confirmPayment({
                elements,
                clientSecret,
                confirmParams: {
                  return_url: "https://amazon.com",
                  expand: ["payment_method"],
                },
                redirect: "always",
              });
              console.log(`confirmPayment result:\n${hashToString(confirmedPI)}`);
            } else if (mode === "setup") {
              await stripe.confirmSetup({
                elements,
                clientSecret,
                confirmParams: {
                  return_url: "https://amazon.com",
                  expand: ["payment_method"],
                },
                redirect: "if_required",
              });
            } else {
              console.log(`Invalid mode onConfirm ${mode}.`);
            }

          }

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
    console.log("In native app, waiting for Swift to call initializeApp()");
    </script>
  </body>
</html>
"""
