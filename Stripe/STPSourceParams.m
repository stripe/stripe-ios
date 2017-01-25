//
//  STPSourceParams.m
//  Stripe
//
//  Created by Ben Guo on 1/23/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPSourceParams.h"
#import "STPCardParams.h"
#import "STPFormEncoder.h"

@implementation STPSourceParams

@synthesize additionalAPIParameters = _additionalAPIParameters;

- (instancetype)init {
    self = [super init];
    if (self) {
        _additionalAPIParameters = @{};
    }
    return self;
}

+ (STPSourceParams *)bancontactParamsWithAmount:(NSUInteger)amount
                                           name:(NSString *)name
                                      returnURL:(NSString *)returnURL
                            statementDescriptor:(nullable NSString *)statementDescriptor {
    STPSourceParams *params = [STPSourceParams new];
    params.type = @"bancontact";
    params.amount = @(amount);
    params.currency = @"eur"; // Bancontact must always use eur
    params.owner = @{ @"name": name };
    params.redirect = @{ @"return_url": returnURL };
    if (statementDescriptor != nil) {
        params.additionalAPIParameters = @{
                                           @"bancontact": @{
                                                   @"statement_descriptor": statementDescriptor
                                                   }
                                           };
    }
    return params;
}

+ (STPSourceParams *)bitcoinParamsWithAmount:(NSUInteger)amount
                                    currency:(NSString *)currency
                                       email:(NSString *)email {
    STPSourceParams *params = [STPSourceParams new];
    params.type = @"bitcoin";
    params.amount = @(amount);
    params.currency = currency;
    params.owner = @{ @"email": email };
    return params;
}

+ (STPSourceParams *)cardParamsWithCard:(STPCardParams *)card {
    STPSourceParams *params = [STPSourceParams new];
    params.type = @"card";
    NSDictionary *keyPairs = [STPFormEncoder keyPairDictionaryForObject:card];
    NSMutableDictionary *cardDict = [NSMutableDictionary dictionary];
    NSArray<NSString *>*cardKeys = @[@"number", @"cvc", @"exp_month", @"exp_year"];
    for (NSString *key in cardKeys) {
        cardDict[key] = keyPairs[key];
    }
    params.additionalAPIParameters = @{ @"card": cardDict };
    NSMutableDictionary *addressDict = [NSMutableDictionary dictionary];
    NSDictionary<NSString *,NSString *>*addressKeyMapping = @{
                                                              @"address_line1": @"line1",
                                                              @"address_line2": @"line2",
                                                              @"address_city": @"city",
                                                              @"address_state": @"state",
                                                              @"address_zip": @"postal_code",
                                                              @"address_country": @"country",
                                                              };
    for (NSString *key in [addressKeyMapping allKeys]) {
        NSString *newKey = [addressKeyMapping objectForKey:key];
        addressDict[newKey] = keyPairs[key];
    }
    params.owner = @{ @"address": addressDict };
    return params;
}

+ (STPSourceParams *)giropayParamsWithAmount:(NSUInteger)amount
                                        name:(NSString *)name
                                   returnURL:(NSString *)returnURL
                         statementDescriptor:(nullable NSString *)statementDescriptor {
    STPSourceParams *params = [STPSourceParams new];
    params.type = @"giropay";
    params.amount = @(amount);
    params.currency = @"eur"; // Giropay must always use eur
    params.owner = @{ @"name": name };
    params.redirect = @{ @"return_url": returnURL };
    if (statementDescriptor != nil) {
        params.additionalAPIParameters = @{
                                           @"giropay": @{
                                                   @"statement_descriptor": statementDescriptor
                                                   }
                                           };
    }
    return params;
}

+ (STPSourceParams *)idealParamsWithAmount:(NSUInteger)amount
                                      name:(NSString *)name
                                 returnURL:(NSString *)returnURL
                       statementDescriptor:(nullable NSString *)statementDescriptor
                                      bank:(nullable NSString *)bank {
    STPSourceParams *params = [STPSourceParams new];
    params.type = @"ideal";
    params.amount = @(amount);
    params.currency = @"eur"; // iDEAL must always use eur
    params.owner = @{ @"name": name };
    params.redirect = @{ @"return_url": returnURL };
    if (statementDescriptor != nil || bank != nil) {
        NSMutableDictionary *idealDict = [NSMutableDictionary dictionary];
        idealDict[@"statement_descriptor"] = statementDescriptor;
        idealDict[@"bank"] = bank;
        params.additionalAPIParameters = @{ @"ideal": idealDict };
    }
    return params;
}

+ (STPSourceParams *)sepaDebitParamsWithAmount:(NSUInteger)amount
                                          name:(NSString *)name
                                          iban:(NSString *)iban
                                       address:(NSDictionary<NSString *,NSString *>*)address {
    STPSourceParams *params = [STPSourceParams new];
    params.type = @"sepa_debit";
    params.amount = @(amount);
    params.currency = @"eur"; // SEPA Debit must always use eur
    params.owner = @{
                     @"name": name,
                     @"address": address
                     };
    params.additionalAPIParameters = @{
                                       @"sepa_debit": @{
                                               @"iban": iban
                                               }
                                       };
    return params;
}

+ (STPSourceParams *)sofortParamsWithAmount:(NSUInteger)amount
                                  returnURL:(NSString *)returnURL
                                    country:(NSString *)country
                        statementDescriptor:(nullable NSString *)statementDescriptor {
    STPSourceParams *params = [STPSourceParams new];
    params.type = @"sofort";
    params.amount = @(amount);
    params.currency = @"eur"; // sofort must always use eur
    params.redirect = @{ @"return_url": returnURL };
    NSMutableDictionary *sofortDict = [NSMutableDictionary dictionary];
    sofortDict[@"country"] = country;
    if (statementDescriptor != nil) {
        sofortDict[@"statement_descriptor"] = statementDescriptor;
    }
    params.additionalAPIParameters = @{ @"sofort": sofortDict };
    return params;
}

+ (STPSourceParams *)threeDSecureParamsWithAmount:(NSUInteger)amount
                                         currency:(NSString *)currency
                                        returnURL:(NSString *)returnURL
                                             card:(NSString *)card {
    STPSourceParams *params = [STPSourceParams new];
    params.type = @"three_d_secure";
    params.amount = @(amount);
    params.currency = currency;
    params.additionalAPIParameters = @{
                                       @"three_d_secure": @{
                                               @"card": card
                                               }
                                       };
    params.redirect = @{ @"return_url": returnURL };
    return params;
}

#pragma mark - STPFormEncodable

+ (NSString *)rootObjectName {
    return nil;
}

+ (NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             NSStringFromSelector(@selector(type)): @"type",
             NSStringFromSelector(@selector(amount)): @"amount",
             NSStringFromSelector(@selector(currency)): @"currency",
             NSStringFromSelector(@selector(flow)): @"flow",
             NSStringFromSelector(@selector(metadata)): @"metadata",
             NSStringFromSelector(@selector(owner)): @"owner",
             NSStringFromSelector(@selector(redirect)): @"redirect",
             NSStringFromSelector(@selector(token)): @"token",
             NSStringFromSelector(@selector(usage)): @"usage",
             };
}

@end
