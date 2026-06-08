# **Server-driven Mobile Payment Element**

**BLUF:** To build for the future and make our SDKs behave consistently across platforms, we will begin to migrate PaymentSheet's business logic to the backend.

## **Background**

As a general principle, our mobile SDKs do not trust the server. When facing any choice of how to handle some bit of business logic, we will err on the side of encoding that logic on the client. Given a server-side flag, we will program defensively and ensure the flag's default value makes sense to a given client. We assume that the server will be difficult or impossible to change, and we avoid any situation where a user's app would be broken by a server-side failure.

This makes sense when dealing with a public API, or a reverse-engineered API provided by another company. It would make sense in a dysfunctional organization where the mobile team is unable to talk to a server-side team. It may even have made sense for a past version of Stripe\! But it has some clear downsides, and it doesn't scale well to the increasingly complex business logic of Mobile Payment Element.

As we evaluate building out a [mobile backend team](https://docs.google.com/document/d/1kbIq5uUpjxpMRx_cX93TXcKmVzrbWN77A6tv0f18MtI/edit?tab=t.0#heading=h.4mwvwnll0cwd), we should invert our current principles and begin relying on the server.

## **The plan**

We will take these first steps towards migrating our business logic away from the client:

1. Staff [full-time backend engineers on the mobile team](https://docs.google.com/document/d/1kbIq5uUpjxpMRx_cX93TXcKmVzrbWN77A6tv0f18MtI/edit?tab=t.0#heading=h.4mwvwnll0cwd).  
2. Send a [standardized SDK version header across iOS and Android](#2.-version-standardization), and create an easy helper to fork and test behavior across SDK versions.  
3. Create a [standardized serialization format](#3.-create-a-standardized-serialization-format-for-the-paymentelement-configuration-across-ios-and-android) for the PaymentSheet Configuration across iOS and Android  
4. Migrate [all flag parsing logic](#4.-migrate-all-flag-parsing-logic-to-the-server) to the server  
5. Migrate the [PaymentSheetAvailability logic to the server](#5.-migrate-the-paymentsheetavailability-logic-to-the-server)  
6. Migrate [image and string assets to the server](#6.-migrate-image-and-string-assets-to-the-server)  
7. Migrate [PaymentSheetFormFactory to the server](#7.-migrate-paymentsheetformfactory-to-the-server)

## **Implementation details**

### **2\. Version standardization** {#2.-version-standardization}

We will send a standardized header containing the SDK version in each request, and build an easy-to-use helper in pay-server to determine the current SDK version for a request.

As part of this, we'll build a harness for adding server-side tests to test certain assumptions about the output. (For example, if we discover a bug that only occurs in SDK `23.4.0`, we should make sure it's trivial to write a test case that runs an example request as `23.4.0` and asserts that it receives the correct response.)

### **3\. Create a standardized serialization format for the PaymentElement Configuration across iOS and Android** {#3.-create-a-standardized-serialization-format-for-the-paymentelement-configuration-across-ios-and-android}

We will send the full PaymentSheet Configuration to the server for every request, enabling us to change behavior based on it. This will *not* require that we standardize PaymentElement.Configuration across iOS and Android, but we will define and codegen a standard API to communicate it across the server that should be shared across both.

Each SDK will contain glue code to bind each value in the local PaymentSheet.Configuration to this shared API object, and the server-side fields must be populated when adding a new client-side field.

### **4\. Migrate all flag parsing logic to the server** {#4.-migrate-all-flag-parsing-logic-to-the-server}

To parse server-side flags, we currently piggy-back on the `elements/sessions` flag list, sometimes adding client-side hacks to transform or change the values to better fit the client-side SDK ([example 1](https://github.com/stripe/stripe-ios/blob/master/StripePaymentSheet/StripePaymentSheet/Source/Internal/API%20Bindings/v1-elements-sessions/STPElementsSession.swift#L333)) or invert the fallback behavior to protect against future server-side changes ([example 2](https://github.com/stripe/stripe-ios/blob/master/StripePaymentSheet/StripePaymentSheet/Source/Internal/API%20Bindings/v1-elements-sessions/STPElementsSession.swift#L376)).

We would replace this with a well-defined mobile-specific feature flag list on the server. Instead of parsing strings, we would codegen API bindings for this list on Android and iOS. These flags may still use the same underlying `go/flags` flags as web, but the code will be easier to reason about, and partner teams will be able to more easily understand which flags impact mobile.

### **5\. Migrate the PaymentSheetAvailability logic to the server** {#5.-migrate-the-paymentsheetavailability-logic-to-the-server}

The [PaymentSheetAvailability](https://github.com/stripe/stripe-ios/blob/master/StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/PaymentSheet%2BPaymentMethodAvailability.swift) checker determines which payment methods are available in PaymentSheet by combining client-side environment with server-side rules. For example, we detect whether Financial Connections or Apple Pay are available, or whether certain payment methods are supported for SetupIntents.

We'll move all this logic to the server. Instead of the client determining which payment methods to show, the server will incorporate the configuration, Apple Pay/FC availability, and the SDK version, and output a list of which payment methods to show. The client will trust this list directly, and trigger an incident if an incompatibility (such as an unsupported payment method) is detected.

### **6\. Migrate image and string assets to the server** {#6.-migrate-image-and-string-assets-to-the-server}

Most [image](https://github.com/stripe/stripe-ios/blob/a2999c5ca595fe5fd4a65febc058dde315153d8a/StripePaymentSheet/StripePaymentSheet/Source/Helpers/Images.swift#L14) and [string assets](https://github.com/stripe/stripe-ios/blob/master/StripePaymentSheet/StripePaymentSheet/Source/Categories/String%2BLocalized.swift) in PaymentSheet are not needed until PaymentSheet has loaded. We will move these images and strings to these backend endpoints, and only send them (for the correct localization) in situations where users will see them.

### **7\. Migrate PaymentSheetFormFactory to the server** {#7.-migrate-paymentsheetformfactory-to-the-server}

We currently build forms using [PaymentSheetFormFactory](https://github.com/stripe/stripe-ios/tree/master/StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/PaymentSheetFormFactory), which combines our 'PaymentMethodElements' to build forms for each payment method. It includes logic like how to show mandates, which billing fields to display, and other business choices.

Here's an example of a moderately complex form:

```swift
func makeBacsDebit() -> PaymentMethodElement {
    let contactSection: Element? = makeContactInformationSection(
        nameRequiredByPaymentMethod: true,
        emailRequiredByPaymentMethod: true,
        phoneRequiredByPaymentMethod: false
    )
    let addressSection: Element? = makeBillingAddressSectionIfNecessary(requiredByPaymentMethod: true)
    let sortCodeField = makeSortCode()
    let accountNumberField = makeBacsAccountNumber()
    let mandate = makeBacsMandate()
    let bacsAccountSection = SectionElement(
        title: String.Localized.bank_account_sentence_case,
        elements: [sortCodeField, accountNumberField],
        theme: theme
    )
    let elements: [Element?] = [contactSection, bacsAccountSection, addressSection, mandate]
    return FormElement(
        autoSectioningElements: elements.compactMap { $0 },
        theme: theme
    )
}
```

These construction functions could be cleanly moved to a server-defined spec, which could look something like this:

```json
{
  "payment_method_type": "bacs_debit",
  "fields": [
    {
      "type": "section",
      "title": "Contact information",
      "fields": [
        {"type": "name"},
        {"type": "email"}
      ]
    },
    {
      "type": "section",
      "title": "Bank account",
      "fields": [
        {"type": "sort_code"},
        {"type": "account_number"}
      ]
    },
    {
      "type": "billing_address",
      "collection_mode": "auto_completable",
      "countries": ["GB"],
      "fields": ["line1", "line2", "city", "postal_code", "country"],
      "show_billing_same_as_shipping": true
    },
    {"type": "mandate", "text": "I understand that Stripe will be collecting Direct Debits on behalf of Merchant..."}
  ]
}
```

Every payment method form, including cards, would be built in this way. There are some exceptions to this decomposition (it may be absurd to try to decompose `CardSectionElement`, for example), but we would follow the general principle of moving as much form-building to the backend as possible.

If an SDK does not support a specific Element type, the client should alert loudly at runtime, trigger an incident on our end, and the server should be patched to not send that Element to that SDK version. There are also potentially interesting nuances around differences in behavior across different Element types in different versions, which we'd want to think through in the proposal.

## **Future goals**

* Migrate some of STPPaymentHandler's next-action mapping logic to the server  
* Server-driven user-facing error messages  
* Server-driven saved payments UI  
* Server-driven validation rules (e.g. sending down regexes for validating specific types of account numbers)  
* An easy way to test an SDK against a devbox

## **Benefits**

* Normalizes business logic across iOS and Android  
* Makes mobile SDK behavior more legible to other teams by moving it into pay-server  
* Makes it easier to change behavior to resolve incidents, fix bugs, and add new features  
* Reduces SDK size (in theory)  
* Simplifies and increases the addressable market for certain types of A/B tests  
* Paves the way for [server-defined LPMs](https://docs.google.com/document/d/1ElhdAXU9wW2ruJlAmlMNnMkTZP62Wnw22LAoCjIcRPc/edit?tab=t.0#heading=h.eowq4rtevkva)

## **Principles**

* **Always prefer the backend for business logic.** Avoid the complexity of splitting decisions (such as which forms to render) across the client and server.  
* **Trust the server.** Don't add client-side hacks and fallbacks to protect against server failures. If the server behaves incorrectly from the SDK's perspective, that should trigger an incident and we should fix it with a server-side patch.  
  * **But assume the server may be slow or temporarily unavailable.** If we took this principle to the point of logical absurdity, we could depend on the server for every keystroke. I am not advocating for that — we should be wary of latency and availability, especially on mobile. Ideally we work with the server during load time and confirm time, and we gracefully handle degradation on operations in between.  
* **Use properly typed API bindings.** We should invest in codegen to share these internal APIs (such as PaymentSheet Configuration, flags, and form specs) across Android and iOS, rather than our current reliance on stringly-typed fields.  
* **Don't be afraid of working in backend code.** We will have dedicated backend engineers, but iOS and Android engineers should feel comfortable adding code to these endpoints.

**See also:**

* [Improving LPM support in the mobile SDKs](https://docs.google.com/document/d/1ElhdAXU9wW2ruJlAmlMNnMkTZP62Wnw22LAoCjIcRPc/edit?ouid=105092694345879732661&usp=docs_home&ths=true)  
* [Proposal: Mobile API Engineers](https://docs.google.com/document/d/1kbIq5uUpjxpMRx_cX93TXcKmVzrbWN77A6tv0f18MtI/edit?tab=t.0#heading=h.4mwvwnll0cwd)
