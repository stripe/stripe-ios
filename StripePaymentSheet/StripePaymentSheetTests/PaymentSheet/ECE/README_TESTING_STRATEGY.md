# ECE (Express Checkout Element) Testing Strategy

## Overview

This document outlines the comprehensive testing strategy for the Express Checkout Element (ECE) integration classes in the Stripe iOS SDK.

## Classes Under Test

1. **ECEViewController** - Manages the WKWebView for displaying Express Checkout Element
2. **ShopPayECEPresenter** - Handles Shop Pay presentation through ECE WebView
3. **ECEIndexHtml** - Contains the HTML/JavaScript bridge code

## Test Files Created

### 1. Unit Tests

#### ECEViewControllerTests.swift
Tests for ECEViewController including:
- Initialization and setup
- WebView configuration
- Message handling (bridge communication)
- Navigation delegate methods
- UI delegate methods (popup handling)
- Error handling scenarios

#### ShopPayECEPresenterTests.swift
Tests for ShopPayECEPresenter including:
- Initialization
- Amount calculation logic
- Shipping address change handling
- Shipping rate change handling
- ECE click event handling
- Payment confirmation flow
- Helper method functionality

### 2. Snapshot Tests

#### ECEViewControllerSnapshotTests.swift
Visual regression tests for:
- Default appearance
- Dark mode
- Large content size (accessibility)
- Compact width layouts
- Popup overlay presentation
- Loading states

### 3. Integration Tests

#### ECEIntegrationTests.swift
End-to-end tests including:
- Complete Shop Pay flow
- Shipping address validation
- WebView message handling
- Amount calculations with various configurations
- Performance tests

### 4. Test Helpers

#### ECETestHelpers.swift
Shared utilities including:
- Test data factories
- Mock WebView components
- Custom assertions
- Async test helpers
- JavaScript injection utilities

## Test Coverage Areas

### 1. WebView Bridge Communication
- Message passing between native and JavaScript
- Error handling for malformed messages
- Timeout handling
- Concurrent message handling

### 2. Delegate Pattern Implementation
- ExpressCheckoutWebviewDelegate protocol adherence
- Async delegate method handling
- Error propagation through delegates

### 3. Data Transformation
- Conversion between web and native formats
- Validation of required fields
- Handling of optional data

### 4. UI/UX Testing
- WebView presentation and dismissal
- Popup handling
- Navigation bar configuration
- Loading states

### 5. Error Scenarios
- Missing delegate
- Invalid message formats
- Network failures
- JavaScript errors

## Mock Objects

### MockExpressCheckoutWebviewDelegate
- Configurable responses for all delegate methods
- Tracking of method calls and parameters
- Support for async operations

### MockWKScriptMessage
- Simulates WebKit script messages
- Configurable name and body

### MockWKWebView
- Tracks JavaScript evaluation calls
- Configurable URL responses

### MockPaymentSheetFlowController
- Simulates PaymentSheet.FlowController behavior
- Configurable intent and configuration

## Files to Add to Xcode Project

Please add the following files to the StripePaymentSheet test target:

1. `StripePaymentSheet/StripePaymentSheetTests/PaymentSheet/ECE/ECEViewControllerTests.swift`
2. `StripePaymentSheet/StripePaymentSheetTests/PaymentSheet/ECE/ShopPayECEPresenterTests.swift`
3. `StripePaymentSheet/StripePaymentSheetTests/PaymentSheet/ECE/ECEViewControllerSnapshotTests.swift`
4. `StripePaymentSheet/StripePaymentSheetTests/PaymentSheet/ECE/ECEIntegrationTests.swift`
5. `StripePaymentSheet/StripePaymentSheetTests/PaymentSheet/ECE/ECETestHelpers.swift`

## Running Tests

### Unit Tests
```bash
xcodebuild -workspace Stripe.xcworkspace -scheme "StripePaymentSheet" -destination "id=DEVICE_ID,arch=arm64" -only-testing:StripePaymentSheetTests/ECEViewControllerTests test
xcodebuild -workspace Stripe.xcworkspace -scheme "StripePaymentSheet" -destination "id=DEVICE_ID,arch=arm64" -only-testing:StripePaymentSheetTests/ShopPayECEPresenterTests test
```

### Snapshot Tests
```bash
# Record mode (to generate reference images)
xcodebuild -workspace Stripe.xcworkspace -scheme "AllStripeFrameworks-RecordMode" -destination "id=DEVICE_ID,arch=arm64" -only-testing:StripePaymentSheetTests/ECEViewControllerSnapshotTests test

# Verify mode
xcodebuild -workspace Stripe.xcworkspace -scheme "AllStripeFrameworks" -destination "id=DEVICE_ID,arch=arm64" -only-testing:StripePaymentSheetTests/ECEViewControllerSnapshotTests test
```

### Integration Tests
```bash
xcodebuild -workspace Stripe.xcworkspace -scheme "StripePaymentSheet" -destination "id=DEVICE_ID,arch=arm64" -only-testing:StripePaymentSheetTests/ECEIntegrationTests test
```

## Future Considerations

1. **Network Stubbing**: Consider adding network stubs for ECE HTML loading
2. **JavaScript Testing**: Add tests for the JavaScript bridge code
3. **Performance Metrics**: Add more comprehensive performance benchmarks
4. **Accessibility Testing**: Add specific accessibility tests for WebView content
5. **Memory Leak Detection**: Add tests to ensure proper cleanup of WebView resources

## Notes for Implementation

- The WebView's frame is currently 500x500 for debugging but should be 1x1 in production
- The WebView's alpha is currently 1.0 for debugging but should be 0.01 in production
- Navigation bar buttons (back/forward/refresh) are for debugging and should be removed before ship
- Consider adding timeout handling for JavaScript operations
- Ensure proper error handling for WebView loading failures 