# Checkout loading refactor

## Motivation

Checkout already owns the current Checkout Session, but applying it to PaymentElement runs the full PaymentSheet loading pipeline. That couples a session update to initialization work and behavior intended for standalone PaymentSheet integrations.

### The old code loads twice

PaymentElement wraps both FlowController and EmbeddedPaymentElement. Before this refactor, each independently called `PaymentSheetLoader.load`, both during initial creation and during updates:

```text
PaymentElement.init
  -> FlowController.create -> PaymentSheetLoader.load
  -> Embedded.create       -> PaymentSheetLoader.load

PaymentElement.update
  -> FlowController.update -> PaymentSheetLoader.load
  -> Embedded.update       -> PaymentSheetLoader.load
```

Both calls run the orchestration for resources, Link, payment-method filtering, promotions, layout, analytics, and confirmation challenges. This does not mean every operation makes two network requests: caches, feature gates, and Link account state can skip work. In Checkout mode, the loader uses the current session rather than fetching a new Elements Session.

Checkout now prepares shared session state once. FC and Embedded receive separate configurations and load results for their respective layouts, while sharing payment-method filtering and promotions fetching.

### Other reasons to separate Checkout loading

- The two loader calls also logged Link holdback exposures twice, once as FlowController and once as Embedded. Loading does not tell us which UI the merchant will use; they may use neither. Shared loading should log one exposure with the Checkout integration shape. UI-specific events retain FC/Embedded attribution when their UI is used.
- Generic session updates can enter Link lookup even when the email has not changed. Applying an already-fetched session should be synchronous. Email changes are the intended future lookup trigger; that behavior currently has a TODO.
- Checkout updates inherit PaymentSheet load/update analytics, including work to compute default selection solely for those events. Checkout should update analytics context for later interaction/confirmation events without emitting those load/update events.
- Resource initialization and telemetry initialization are mixed with applying updated session data. Initial loading and updates need different orchestration.
- Replace two confirmation challenges (one for FC, one for Embedded) with one per processed Checkout session. Each can initialize passive CAPTCHA preloading and attestation state, so this removes duplicated challenge state as well as duplicated loading orchestration. The challenge belongs to confirmation, not PE: ECE Link also needs it when PE is absent. Previously ECE Link constructed another challenge when building its confirmation flow.
- Standalone Embedded's already-confirmed guard does not describe Checkout's lifecycle. Checkout confirms through its own coordinator and uses session status; it never sets Embedded's `hasConfirmedIntent` flag.

## Responsibility of `handleSessionChange`

`CheckoutControllerLoader` owns loading and preparation. Its synchronous preparation work is shared between initial loading and updates, not repeated for FC and Embedded:

```text
initial load -> load session / resources / Link -> apply defaults -> handleSessionChange -> create PE
update       -> commit updated session                          -> handleSessionChange -> update PE
```

Preparation derives supported and saved payment methods, layout, promotions data helpers, and the confirmation challenge from the current session and configuration. Shared session settings run once per session change. Link/Financial Connections experiment exposures log during initial Link lookup, not on generic updates. FC and Embedded consume the resulting data. CheckoutController retains the confirmation challenge for its confirmation paths.

Promotions requests remain in the background. They depend on amount, currency, and available methods, so preserving refresh on updates does not require making session application async.

Checkout routes initial loading and updates through CheckoutControllerLoader. FC and Embedded share filtering and one promotions fetch, while retaining their own UI analytics context. Promotions analytics attribution is deferred (see below). Confirmation uses the challenge retained by CheckoutController, including ECE Link without PE.

`ConfirmationChallenge` supplies passive CAPTCHA and attestation tokens before confirmation; it does not present active CAPTCHA UI. Checkout's Apple Pay path currently tokenizes the Apple Pay payment and confirms without using this challenge or adding its Radar options. Active confirmation challenges returned as Intent next actions are handled separately by `STPPaymentHandler`. Moving ownership to Checkout does not mean adding challenges to Apple Pay or changing its presentation behavior.

## Unresolved behavior

Behavior when no supported payment methods remain is deferred with a TODO. Session application is nonthrowing and currently passes the empty list through; this does not define how PE, ECE, selection, or confirmation should behave in that scenario.

## Analytics ownership

Experiment exposures use a concrete `ExperimentAnalyticsHelper`; Checkout uses the `checkoutElements` case (serialized as `checkoutelements`). PaymentSheet keeps its existing integration shapes and PS load lifecycle events.

The promotions helper requires an experiment helper and optionally accepts a PSAHelper. Checkout shares one promotions helper without a PSAHelper, temporarily skipping promotions fetch-begin and display events. Its experiment exposure currently uses the sheet layout even if the merchant uses Embedded or neither UI. TODO: resolve exposure layout attribution and fetch/display event context separately; loading does not tell us which UI will be used. FC and Embedded receive separate load results with their respective orientations; both results reference the same promotions helper, with no per-UI promotions wrappers or duplicated fetches. Standalone PS promotions logging remains unchanged.

## Session updates and initialization

`commitSession` only stores the API response and local state; it is synchronous and nonthrowing. Normal updates go through `performQueuedUpdate` or, from an already-queued operation, `performUnqueuedUpdate`. After the request and session commit, `updateForSessionChange` refreshes the confirmation challenge and applies FC/Embedded parameters synchronously without throwing. Terminal sessions skip this work. Confirmation responses are only committed; they do not reload PaymentElement or refresh the challenge. Initial defaults make their required tax requests and store local state directly, before deriving payment state and creating PE. Row-selection configuration is validated once in PE initialization. FC presentation waits for pending Checkout updates and presents the updated view without starting another PaymentSheetLoader load.

## Testing

New coverage:

- A merchant server update refreshes amount, currency, and layout context in both payment UIs while preserving the customer's Embedded selection and omitting standalone PaymentSheet load events.
- A promotion-code update preserves the Link account without looking it up again.
- Updated promotions use the current amount and currency and are available to both payment UIs from one fetch.

Existing confirmation tests check that Link receives a confirmation challenge with either PE UI and when PE is absent. The existing holdback exposure test also covers Checkout's integration-shape value. Existing defaults, session-update, selection, and helper tests retain their responsibilities; fixture and API-signature changes are mechanical.
