//
//  STPFPXBankStatusResponse.h
//  Stripe
//
//  Created by David Estes on 10/21/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"
#import "STPFPXBankBrand.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPFPXBankStatusResponse : NSObject <STPAPIResponseDecodable>

- (BOOL)bankBrandIsOnline:(STPFPXBankBrand)bankBrand;

@end

NS_ASSUME_NONNULL_END
