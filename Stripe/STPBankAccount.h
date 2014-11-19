//
//  STPBankAccount.h
//  Stripe
//
//  Created by Charles Scalesse on 10/1/14.
//
//

#import <Foundation/Foundation.h>
#import "STPFormEncodeProtocol.h"

@interface STPBankAccount : NSObject<STPFormEncodeProtocol>

@property (nonatomic, copy) NSString *accountNumber;
@property (nonatomic, copy) NSString *routingNumber;
@property (nonatomic, copy) NSString *country;

@property (nonatomic, readonly) NSString *object;
@property (nonatomic, readonly) NSString *bankAccountId;
@property (nonatomic, readonly) NSString *last4;
@property (nonatomic, readonly) NSString *bankName;
@property (nonatomic, readonly) NSString *fingerprint;
@property (nonatomic, readonly) NSString *currency;
@property (nonatomic, readonly) BOOL validated;
@property (nonatomic, readonly) BOOL disabled;

- (instancetype)initWithAttributeDictionary:(NSDictionary *)attributeDictionary;

- (BOOL)isEqualToBankAccount:(STPBankAccount *)bankAccount;

@end
