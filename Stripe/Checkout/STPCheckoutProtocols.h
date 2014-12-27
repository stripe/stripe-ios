//
//  STPCheckoutProtocols.h
//  Stripe
//
//  Created by Jack Flintermann on 11/26/14.
//

/**
 *  Use these options to inform Stripe Checkout of the success or failure of your backend charge.
 */
typedef NS_ENUM(NSInteger, STPBackendChargeResult) {
    STPBackendChargeResultSuccess, // Passing this value will display a "success" animation in the payment button.
    STPBackendChargeResultFailure, // Passing this value will display an "error" animation in the payment button.
};

typedef void (^STPTokenSubmissionHandler)(STPBackendChargeResult status, NSError *error);
