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
      <!-- Express Checkout Element will be inserted here -->
    </div>

    <script>


    function getStripePublishableKey() {
      return "pk_test_51RUTiSAs6uch2mqQune4yYMgnaPTI8z7AuCS9CPb5zaDQuUsje3qsRZKwgjDND3DTwvKVz6aSWYFy36FVA7iyn7h00QbaV5A9S";
    }

    function hashToString(hash) {
      return JSON.stringify(hash, 0, 2);
    }

    var QUERY_PARAMS = new URLSearchParams(window.location.search);
    var ELEMENTS_OPTIONS = JSON.parse("{}");
    var LINE_ITEMS = [];
    var AMOUNT_TOTAL = 0;
    var SHIPPING_RATES = [];
    function getNamespacedQueryParams(ns) {
      const namespacedParams = {};
      QUERY_PARAMS.forEach((value, key) => {
        console.log(key);
        const indexOfNs = key.indexOf(ns);
        if (indexOfNs === 0) {
          const paramKey = key.substring(ns.length + 1); // omit "elements."
          namespacedParams[paramKey] = value;
        }
      });
      return namespacedParams;
    }
    async function getItems() {
      // Check if native has injected the items
      if (window.NATIVE_LINE_ITEMS && window.NATIVE_AMOUNT_TOTAL !== undefined) {
        logECEEvent("Using line items from native bridge");
        LINE_ITEMS = window.NATIVE_LINE_ITEMS.map((item) => {
          return {
            name: item.name,
            amount: item.amount,
          };
        });
        AMOUNT_TOTAL = window.NATIVE_AMOUNT_TOTAL;
        ELEMENTS_OPTIONS = {
          ...ELEMENTS_OPTIONS,
          mode: "payment",
          amount: AMOUNT_TOTAL,
          //paymentMethodCreation: "manual",
          currency: "usd",
          payment_method_types: ["card", "link", "shop_pay"],
          ...getNamespacedQueryParams("elements"),
        };
        return Promise.resolve();
      } else {
        logECEEvent("Native items not found");
      }
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

    var shippingCountry = "US";
    var shippingState = "WA";

    function initializeStripeElements() {

      console.log("Initializing stripe elements with options", ELEMENTS_OPTIONS);

      let stripe, elements, expressCheckoutElement;

      try {
        stripe = window.Stripe(getStripePublishableKey(), {});
        console.log("Created Stripe");
      } catch (error) {
        console.error("Error creating Stripe instance:", error);
        logECEEvent(`❌ Failed to create Stripe instance: ${error.message}`);
        throw error;
      }

      try {
        elements = stripe.elements(ELEMENTS_OPTIONS);
        console.log("Created Elements");
      } catch (error) {
        console.error("Error creating Elements with options:", ELEMENTS_OPTIONS, error);
        logECEEvent(`❌ Failed to create Elements: ${error.message}`);
        logECEEvent(`Elements options were: ${JSON.stringify(ELEMENTS_OPTIONS)}`);
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
        logECEEvent(`❌ Failed to create Express Checkout Element: ${error.message}`);
        logECEEvent(`ECE options were: ${JSON.stringify(ECE_OPTIONS)}`);
        throw error;
      }
      var mode = ELEMENTS_OPTIONS["mode"];
      var captureMethod = ELEMENTS_OPTIONS["captureMethod"]
        ? ELEMENTS_OPTIONS["captureMethod"]
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
        logECEEvent(`Click received with event:\n${hashToString(event)}`);

        try {
          logECEEvent("Using Native ECE Click Handler...");

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

          logECEEvent(`Native ECE Response:\n${hashToString(resolvePayload)}`);

          // Resolve the event with the payload from native
          event.resolve(resolvePayload);

          // Handle overlay removal if requested by native
          if (resolvePayload.disableOverlay) {
            // Remove the overlay applied by ECE
            document.querySelectorAll('div[style*="z-index: 9999999"]')[0]?.remove();
            document.body.style.overflow = "auto";
          }

        } catch (error) {
          logECEEvent(`Error handling ECE click: ${error.message}`);
          console.error("ECE click error:", error);

          // On error, throw to let Stripe handle it
          throw error;
        }
      });

      expressCheckoutElement.on("shippingaddresschange", async function (event) {
        logECEEvent(
          `ShippingAddressChange: Name: ${event.name}\nAddress:\n${hashToString(
            event.address
          )}`
        );
        shippingCountry = event.address.country;
        shippingState = event.address.state;

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
            logECEEvent("Using Native Shipping API...");

            // Call native API
            const response = await window.NativeShipping.calculateShipping(shippingAddress);

            logECEEvent(`Native API Response:\n${hashToString(response)}`);

            // Check if merchant rejected the address
            if (response.merchantDecision === "rejected") {
              logECEEvent(`Shipping rejected: ${response.error || "Address not serviceable"}`);
              event.reject();
              return;
            }

            // Use the response from native API
            SHIPPING_RATES = response.shippingRates || [];

            // Update line items if provided
            if (response.lineItems) {
              LINE_ITEMS = response.lineItems;
            }

            // Update the total amount from the response
            if (response.totalAmount) {
              AMOUNT_TOTAL = response.totalAmount;
              elements.update({ amount: AMOUNT_TOTAL });
            }

            event.resolve({
              shippingRates: SHIPPING_RATES,
              lineItems: LINE_ITEMS
            });

          } else {
            // Resolve with an error
            logECEEvent("Native Shipping API not available");
            event.reject();
          }

        } catch (error) {
          logECEEvent(`Error calculating shipping: ${error.message}`);
          console.error("Shipping calculation error:", error);

          // On error, reject the shipping address
          event.reject();
        }
      });

      expressCheckoutElement.on("shippingratechange", async function (event) {
        logECEEvent(`Selected Shipping Rate:\n${hashToString(event.shippingRate)}`);
        console.log("Shipping rate change event:", event);
        console.log("Current AMOUNT_TOTAL:", AMOUNT_TOTAL);
        console.log("Current SHIPPING_RATES:", SHIPPING_RATES);

        try {
          // Check if native API is available
          console.log("Checking for native rate API...");
          console.log("window.NativeShipping:", window.NativeShipping);
          console.log("calculateShippingRateChange function:", window.NativeShipping?.calculateShippingRateChange);

          if (window.NativeShipping && window.NativeShipping.calculateShippingRateChange) {
            logECEEvent("Using Native Shipping Rate API...");

            // Call native API to validate and calculate new amount
            const response = await window.NativeShipping.calculateShippingRateChange(event.shippingRate, AMOUNT_TOTAL);

            logECEEvent(`Native Rate API Response:\n${hashToString(response)}`);

            // Check if merchant rejected the rate
            if (response.merchantDecision === "rejected") {
              logECEEvent(`Shipping rate rejected: ${response.error || "Invalid shipping rate"}`);
              event.reject();
              return;
            }

            // Update the amount with the value from native
            if (response.updatedAmount) {
              console.log(`updating amount to ${response.updatedAmount}`);
              elements.update({ amount: response.updatedAmount });
            }

            event.resolve();

          }

        } catch (error) {
          logECEEvent(`Error validating shipping rate: ${error.message}`);
          console.error("Shipping rate validation error:", error);

          // On error, reject the shipping rate
          event.reject();
        }
      });

      expressCheckoutElement.on("cancel", function () {
        logECEEvent("cancel");
      });

      //Observes confirm action & responds with return_url, elements & clientSecret for completing transaction
      expressCheckoutElement.on("confirm", async (event) => {
        logECEEvent(
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
            logECEEvent("Using Native Payment API...");

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

            logECEEvent(`Native Payment API Response:\n${hashToString(response)}`);

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
              logECEEvent(`confirmPayment result:\n${hashToString(confirmedPI)}`);
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
          logECEEvent(`Error confirming payment: ${error.message}`);
          console.error("Payment confirmation error:", error);
          event.paymentFailed({ reason: error.message });
        }
      });
    }

    function logECEEvent(msg) {
      // Also log to browser console
      console.log("[ECE Event]", msg);
    }

    // Function to initialize everything - called from Swift or automatically
    function initializeApp() {
      getItems()
        .then(() => {
          console.log("getItems");
          try {
            initializeStripeElements();
          } catch (error) {
            console.error("Error initializing Stripe Elements:", error);
            logECEEvent(`❌ Failed to initialize Stripe Elements: ${error.message}`);
            // Re-throw to maintain error propagation if needed
            throw error;
          }
        })
        .catch((error) => {
          console.error("Error in initializeApp:", error);
          logECEEvent(`❌ Failed to initialize app: ${error.message}`);
        });
    }
    console.log("In native app, waiting for Swift to call initializeApp()");
    </script>
  </body>
</html>
"""
