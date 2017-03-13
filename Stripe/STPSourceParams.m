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
#import "STPSource+Private.h"

@implementation STPSourceParams

@synthesize additionalAPIParameters = _additionalAPIParameters;

- (instancetype)init {
    self = [super init];
    if (self) {
        _type = STPSourceTypeUnknown;
        _flow = STPSourceFlowUnknown;
        _usage = STPSourceUsageUnknown;
        _additionalAPIParameters = @{};
    }
    return self;
}

- (NSString *)typeString {
    return [STPSource stringFromType:self.type];
}

- (NSString *)flowString {
    return [STPSource stringFromFlow:self.flow];
}

- (NSString *)usageString {
    return [STPSource stringFromUsage:self.usage];
}

+ (STPSourceParams *)bancontactParamsWithAmount:(NSUInteger)amount
                                           name:(NSString *)name
                                      returnURL:(NSString *)returnURL
                            statementDescriptor:(nullable NSString *)statementDescriptor {
    STPSourceParams *params = [self new];
    params.type = STPSourceTypeBancontact;
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
    STPSourceParams *params = [self new];
    params.type = STPSourceTypeBitcoin;
    params.amount = @(amount);
    params.currency = currency;
    params.owner = @{ @"email": email };
    return params;
}

+ (STPSourceParams *)cardParamsWithCard:(STPCardParams *)card {
    STPSourceParams *params = [self new];
    params.type = STPSourceTypeCard;
    NSDictionary *keyPairs = [STPFormEncoder dictionaryForObject:card][@"card"];
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
        NSString *newKey = addressKeyMapping[key];
        addressDict[newKey] = keyPairs[key];
    }
    NSMutableDictionary *ownerDict = [NSMutableDictionary dictionary];
    ownerDict[@"address"] = [addressDict copy];
    ownerDict[@"name"] = card.name;
    params.owner = [ownerDict copy];
    return params;
}

+ (STPSourceParams *)giropayParamsWithAmount:(NSUInteger)amount
                                        name:(NSString *)name
                                   returnURL:(NSString *)returnURL
                         statementDescriptor:(nullable NSString *)statementDescriptor {
    STPSourceParams *params = [self new];
    params.type = STPSourceTypeGiropay;
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
    STPSourceParams *params = [self new];
    params.type = STPSourceTypeIDEAL;
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

+ (STPSourceParams *)sepaDebitParamsWithName:(NSString *)name
                                        iban:(NSString *)iban
                                addressLine1:(NSString *)addressLine1
                                        city:(NSString *)city
                                  postalCode:(NSString *)postalCode
                                     country:(NSString *)country {
    STPSourceParams *params = [self new];
    params.type = STPSourceTypeSEPADebit;
    params.currency = @"eur"; // SEPA Debit must always use eur

    NSDictionary<NSString *,NSString *> *address =
    @{
      @"line1": addressLine1,
      @"city": city,
      @"postal_code": postalCode,
      @"country": country
      };

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
    STPSourceParams *params = [self new];
    params.type = STPSourceTypeSofort;
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
    STPSourceParams *params = [self new];
    params.type = STPSourceTypeThreeDSecure;
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
             NSStringFromSelector(@selector(typeString)): @"type",
             NSStringFromSelector(@selector(amount)): @"amount",
             NSStringFromSelector(@selector(currency)): @"currency",
             NSStringFromSelector(@selector(flowString)): @"flow",
             NSStringFromSelector(@selector(metadata)): @"metadata",
             NSStringFromSelector(@selector(owner)): @"owner",
             NSStringFromSelector(@selector(redirect)): @"redirect",
             NSStringFromSelector(@selector(token)): @"token",
             NSStringFromSelector(@selector(usageString)): @"usage",
             };
}

#pragma mark - NSCopying

- (id)copyWithZone:(__unused NSZone *)zone {
    STPSourceParams *copy = [self.class new];
    copy.type = self.type;
    copy.amount = self.amount;
    copy.currency = self.currency;
    copy.flow = self.flow;
    copy.metadata = [self.metadata copy];
    copy.owner = [self.owner copy];
    copy.redirect = [self.redirect copy];
    copy.token = self.token;
    copy.usage = self.usage;
    return copy;
}

@end
