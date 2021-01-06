//
//  STDSChallengeResponseObject+TestObjects.h
//  Stripe3DS2DemoUI
//
//  Created by Andrew Harrison on 3/7/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSChallengeResponseObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface STDSChallengeResponseObject (TestObjects)

+ (id<STDSChallengeResponse>)textChallengeResponseWithWhitelist:(BOOL)whitelist resendCode:(BOOL)resendCode;
+ (id<STDSChallengeResponse>)singleSelectChallengeResponse;
+ (id<STDSChallengeResponse>)multiSelectChallengeResponse;
+ (id<STDSChallengeResponse>)OOBChallengeResponse;
+ (id<STDSChallengeResponse>)HTMLChallengeResponse;

@end

NS_ASSUME_NONNULL_END
