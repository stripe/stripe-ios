//
//  STPFormEncodeProtocol.h
//  Stripe
//
//  Created by Ray Morgan on 7/11/14.
//
//

@protocol STPFormEncodeProtocol<NSObject>

@required
- (NSData *)formEncode;

@end
