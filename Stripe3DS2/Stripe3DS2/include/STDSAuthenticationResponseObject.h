//
//  STDSAuthenticationResponseObject.h
//  Stripe3DS2
//
//  Created by Cameron Sabol on 5/20/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STDSAuthenticationResponse.h"
#import "STDSJSONDecodable.h"

NS_ASSUME_NONNULL_BEGIN

@interface STDSAuthenticationResponseObject : NSObject <STDSAuthenticationResponse, STDSJSONDecodable>

@end

NS_ASSUME_NONNULL_END
