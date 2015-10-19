//
//  STPAPIClient+ApplePay.h
//  Stripe
//
//  Created by Jack Flintermann on 12/19/14.
//

#import <Foundation/Foundation.h>
#import <PassKit/PassKit.h>

#import "STPAPIClient.h"


@interface STPAPIClient (ApplePay)

/**
 *  Converts a PKPayment object into a Stripe token using the Stripe API.
 *
 *  @param payment     The user's encrypted payment information as returned from a PKPaymentAuthorizationViewController. Cannot be nil.
 *  @param completion  The callback to run with the returned Stripe token (and any errors that may have occurred).
 */
- (void)createTokenWithPayment:(nonnull PKPayment *)payment completion:(nonnull STPTokenCompletionBlock)completion;

// Form-encodes a PKPayment object for POSTing to the Stripe API. This method is used internally by STPAPIClient; you should not use it in your own code.
+ (nonnull NSData *)formEncodedDataForPayment:(nonnull PKPayment *)payment;

@end

void linkSTPAPIClientApplePayCategory(void);
