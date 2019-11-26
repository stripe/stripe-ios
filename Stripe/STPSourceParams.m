//
//  STPSourceParams.m
//  Stripe
//
//  Created by Ben Guo on 1/23/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPSourceParams.h"
#import "STPSourceParams+Private.h"

#import "NSBundle+Stripe_AppName.h"
#import "STPCardParams.h"
#import "STPFormEncoder.h"
#import "STPSource+Private.h"
#import "STPKlarnaLineItem.h"

@interface STPSourceParams ()

// See STPSourceParams+Private.h

@end

@implementation STPSourceParams

@synthesize additionalAPIParameters = _additionalAPIParameters;

- (instancetype)init {
    self = [super init];
    if (self) {
        _rawTypeString = @"";
        _flow = STPSourceFlowUnknown;
        _usage = STPSourceUsageUnknown;
        _additionalAPIParameters = @{};
    }
    return self;
}

- (STPSourceType)type {
    return [STPSource typeFromString:self.rawTypeString];
}

- (void)setType:(STPSourceType)type {
    // If setting unknown and we're already unknown, don't want to override raw value
    if (type != self.type) {
        self.rawTypeString = [STPSource stringFromType:type];
    }
}

- (NSString *)flowString {
    return [STPSource stringFromFlow:self.flow];
}

- (NSString *)usageString {
    return [STPSource stringFromUsage:self.usage];
}

#pragma mark - Description

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                       // Basic source details
                       [NSString stringWithFormat:@"type = %@", ([STPSource stringFromType:self.type]) ?: @"unknown"],
                       [NSString stringWithFormat:@"rawTypeString = %@", self.rawTypeString],

                       // Additional source details (alphabetical)
                       [NSString stringWithFormat:@"amount = %@", self.amount],
                       [NSString stringWithFormat:@"currency = %@", self.currency],
                       [NSString stringWithFormat:@"flow = %@", ([STPSource stringFromFlow:self.flow]) ?: @"unknown"],
                       [NSString stringWithFormat:@"metadata = %@", (self.metadata) ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"owner = %@", (self.owner) ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"redirect = %@", self.redirect],
                       [NSString stringWithFormat:@"token = %@", self.token],
                       [NSString stringWithFormat:@"usage = %@", ([STPSource stringFromUsage:self.usage]) ?: @"unknown"],
                       ];

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - Constructors

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
                                      name:(nullable NSString *)name
                                 returnURL:(NSString *)returnURL
                       statementDescriptor:(nullable NSString *)statementDescriptor
                                      bank:(nullable NSString *)bank {
    STPSourceParams *params = [self new];
    params.type = STPSourceTypeIDEAL;
    params.amount = @(amount);
    params.currency = @"eur"; // iDEAL must always use eur
    if (name.length > 0) {
        params.owner = @{ @"name": name };
    }
    params.redirect = @{ @"return_url": returnURL };
    if (statementDescriptor.length > 0 || bank.length > 0) {
        NSMutableDictionary *idealDict = [NSMutableDictionary dictionary];
        idealDict[@"statement_descriptor"] = (statementDescriptor.length > 0) ? statementDescriptor : nil;
        idealDict[@"bank"] = (bank.length > 0) ? bank : nil;
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

    NSMutableDictionary *owner = [NSMutableDictionary new];
    owner[@"name"] = name;

    NSMutableDictionary<NSString *,NSString *> *address = [NSMutableDictionary new];
    address[@"city"] = city;
    address[@"postal_code"] = postalCode;
    address[@"country"] = country;
    address[@"line1"] = addressLine1;

    if (address.count > 0) {
        owner[@"address"] = address;
    }

    params.owner = owner;
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

+ (STPSourceParams *)klarnaParamsWithReturnURL:(NSString *)returnURL
                                      currency:(NSString *)currency
                               purchaseCountry:(NSString *)purchaseCountry
                                         items:(NSArray<STPKlarnaLineItem *> *)items
                          customPaymentMethods:(STPKlarnaPaymentMethods)customPaymentMethods
                                billingAddress:(STPAddress *)address
                              billingFirstName:(NSString *)firstName
                               billingLastName:(NSString *)lastName
                                    billingDOB:(STPDateOfBirth *)dateOfBirth {
    STPSourceParams *params = [self new];
    params.type = STPSourceTypeKlarna;
    params.currency = currency;
    params.redirect = @{ @"return_url": returnURL };
    NSMutableDictionary *additionalAPIParameters = [NSMutableDictionary dictionary];

    NSMutableDictionary *klarnaDict = [NSMutableDictionary dictionary];
    klarnaDict[@"product"] = @"payment";
    klarnaDict[@"purchase_country"] = purchaseCountry;
        
    if (address) {
        if ([address.country isEqualToString:purchaseCountry] &&
            address.line1 != nil &&
            address.postalCode != nil &&
            address.city != nil &&
            address.email != nil &&
            firstName != nil &&
            lastName != nil) {
            klarnaDict[@"first_name"] = firstName;
            klarnaDict[@"last_name"] = lastName;
            
            NSMutableDictionary *ownerDict = [NSMutableDictionary dictionary];
            NSMutableDictionary *addressDict = [NSMutableDictionary dictionary];

            addressDict[@"line1"] = address.line1;
            addressDict[@"line2"] = address.line2;
            addressDict[@"city"] = address.city;
            addressDict[@"state"] = address.state;
            addressDict[@"postal_code"] = address.postalCode;
            addressDict[@"country"] = address.country;

            ownerDict[@"address"] = addressDict;
            ownerDict[@"phone"] = address.phone;
            ownerDict[@"email"] = address.email;
            additionalAPIParameters[@"owner"] = ownerDict;
        }
    }
    
    if (dateOfBirth) {
        klarnaDict[@"owner_dob_day"] = [NSString stringWithFormat:@"%02ld", (long)dateOfBirth.day];
        klarnaDict[@"owner_dob_month"] = [NSString stringWithFormat:@"%02ld", (long)dateOfBirth.month];
        klarnaDict[@"owner_dob_year"] = [NSString stringWithFormat:@"%li", (long)dateOfBirth.year];
    }

    NSUInteger amount = 0;
    NSMutableArray *sourceOrderItems = [NSMutableArray arrayWithCapacity:[items count]];
    for (STPKlarnaLineItem *item in items) {
        NSString *itemType = nil;
        switch (item.itemType) {
            case STPKlarnaLineItemTypeSKU:
                itemType = @"sku";
                break;
            case STPKlarnaLineItemTypeTax:
                itemType = @"tax";
                break;
            case STPKlarnaLineItemTypeShipping:
                itemType = @"shipping";
                break;
            default:
                break;
        }
        [sourceOrderItems addObject:@{
            @"type": itemType,
            @"description": item.itemDescription,
            @"quantity": item.quantity,
            @"amount": item.totalAmount,
            @"currency": currency
        }];
        amount = [item.totalAmount unsignedIntValue] + amount;
    }
    params.amount = @(amount);
    
    if (customPaymentMethods != STPKlarnaPaymentMethodsNone) {
        NSMutableArray *customPaymentMethodsArray = [NSMutableArray array];
        if (customPaymentMethods & STPKlarnaPaymentMethodsPayIn4) {
            [customPaymentMethodsArray addObject:@"payin4"];
        }
        if (customPaymentMethods & STPKlarnaPaymentMethodsInstallments) {
            [customPaymentMethodsArray addObject:@"installments"];
        }
        klarnaDict[@"custom_payment_methods"] = [customPaymentMethodsArray componentsJoinedByString:@","];
    }

    additionalAPIParameters[@"source_order"] = @{@"items" : sourceOrderItems};
    additionalAPIParameters[@"klarna"] = klarnaDict;
    additionalAPIParameters[@"flow"] = @"redirect";

    params.additionalAPIParameters = additionalAPIParameters;
    return params;
}

+ (STPSourceParams *)klarnaParamsWithReturnURL:(NSString *)returnURL
            currency:(NSString *)currency
     purchaseCountry:(NSString *)purchaseCountry
               items:(NSArray<STPKlarnaLineItem *> *)items
                          customPaymentMethods:(STPKlarnaPaymentMethods)customPaymentMethods {
    return [self klarnaParamsWithReturnURL:returnURL currency:currency purchaseCountry:purchaseCountry items:items customPaymentMethods:customPaymentMethods billingAddress:nil billingFirstName:nil billingLastName:nil billingDOB:nil];
}

+ (STPSourceParams *)threeDSecureParamsWithAmount:(NSUInteger)amount
                                         currency:(NSString *)currency
                                        returnURL:(NSString *)returnURL
                                             card:(NSString *)card {
    NSCAssert(card != nil, @"'card' id is required to create a 3DS params for the card");
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

+ (STPSourceParams *)alipayParamsWithAmount:(NSUInteger)amount
                                   currency:(NSString *)currency
                                  returnURL:(NSString *)returnURL {
    STPSourceParams *params = [self new];
    params.type = STPSourceTypeAlipay;
    params.amount = @(amount);
    params.currency = currency;
    params.redirect = @{ @"return_url": returnURL };

    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    NSString *versionKey = [NSBundle stp_applicationVersion];
    if (bundleID && versionKey) {
        params.additionalAPIParameters = @{
                                           @"alipay": @{
                                                   @"app_bundle_id": bundleID,
                                                   @"app_version_key": versionKey,
                                                   },
                                           };
    }
    return params;
}

+ (STPSourceParams *)alipayReusableParamsWithCurrency:(NSString *)currency
                                            returnURL:(NSString *)returnURL {
    STPSourceParams *params = [self new];
    params.type = STPSourceTypeAlipay;
    params.currency = currency;
    params.redirect = @{ @"return_url": returnURL };
    params.usage = STPSourceUsageReusable;

    return params;
}

+ (STPSourceParams *)p24ParamsWithAmount:(NSUInteger)amount
                                currency:(NSString *)currency
                                   email:(NSString *)email
                                    name:(nullable NSString *)name
                               returnURL:(NSString *)returnURL {
    STPSourceParams *params = [self new];
    params.type = STPSourceTypeP24;
    params.amount = @(amount);
    params.currency = currency;

    NSMutableDictionary *ownerDict = @{ @"email" : email }.mutableCopy;
    if (name) {
        ownerDict[@"name"] = name;
    }
    params.owner = ownerDict.copy;
    params.redirect = @{ @"return_url": returnURL };
    return params;
}

+ (STPSourceParams *)visaCheckoutParamsWithCallId:(NSString *)callId {
    STPSourceParams *params = [self new];
    params.type = STPSourceTypeCard;
    params.additionalAPIParameters = @{ @"card": @{ @"visa_checkout": @{ @"callid": callId } } };
    return params;
}

+ (STPSourceParams *)masterpassParamsWithCartId:(NSString *)cartId
                                  transactionId:(NSString *)transactionId {
    STPSourceParams *params = [self new];
    params.type = STPSourceTypeCard;
    params.additionalAPIParameters = @{ @"card": @{
                                                @"masterpass": @{
                                                        @"cart_id": cartId,
                                                        @"transaction_id": transactionId,
                                                        }
                                                }

                                        };
    return params;
}

+ (STPSourceParams *)epsParamsWithAmount:(NSUInteger)amount
                                    name:(NSString *)name
                               returnURL:(NSString *)returnURL
                     statementDescriptor:(nullable NSString *)statementDescriptor {
    STPSourceParams *params = [self new];
    params.type = STPSourceTypeEPS;
    params.amount = @(amount);
    params.currency = @"eur"; // EPS must always use eur
    params.owner = @{ @"name": name };
    params.redirect = @{ @"return_url": returnURL };

    if (statementDescriptor.length > 0) {
        params.additionalAPIParameters = @{ @"statement_descriptor": statementDescriptor };
    }

    return params;
}

+ (STPSourceParams *)multibancoParamsWithAmount:(NSUInteger)amount
                                      returnURL:(NSString *)returnURL
                                          email:(NSString *)email {
    STPSourceParams *params = [self new];
    params.type = STPSourceTypeMultibanco;
    params.currency = @"eur"; // Multibanco must always use eur
    params.amount = @(amount);
    params.redirect = @{ @"return_url": returnURL };
    params.owner = @{ @"email": email };
    return params;
}

+ (STPSourceParams *)wechatPayParamsWithAmount:(NSUInteger)amount
                                      currency:(NSString *)currency
                                         appId:(NSString *)appId
                           statementDescriptor:(nullable NSString *)statementDescriptor {
    STPSourceParams *params = [self new];

    params.type = STPSourceTypeWeChatPay;
    params.amount = @(amount);
    params.currency = currency;

    NSMutableDictionary *wechat = [NSMutableDictionary new];
    wechat[@"appid"] = appId;
    if (statementDescriptor.length > 0) {
        wechat[@"statement_descriptor"] = statementDescriptor;
    }
    params.additionalAPIParameters = @{ @"wechat": [wechat copy] };
    return params;
}

#pragma mark - Redirect Dictionary

/**
 Private setter allows for setting the name of the app in the returnURL so
 that it can be displayed on hooks.stripe.com if the automatic redirect back
 to the app fails.
 
 We intercept the reading of redirect dictionary from STPFormEncoder and replace
 the value of return_url if necessary
 */
- (NSDictionary *)redirectDictionaryWithMerchantNameIfNecessary {
    if (self.redirectMerchantName
        && self.redirect[@"return_url"]) {

        NSURL *url = [NSURL URLWithString:self.redirect[@"return_url"]];
        if (url) {
            NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url
                                                        resolvingAgainstBaseURL:NO];

            if (urlComponents) {

                for (NSURLQueryItem *item in urlComponents.queryItems) {
                    if ([item.name isEqualToString:@"redirect_merchant_name"]) {
                        // Just return, don't replace their value
                        return self.redirect;
                    }
                }

                // If we get here, there was no existing redirect name

                NSMutableArray<NSURLQueryItem *> *queryItems = (urlComponents.queryItems ?: @[]).mutableCopy;

                [queryItems addObject:[NSURLQueryItem queryItemWithName:@"redirect_merchant_name"
                                                                  value:self.redirectMerchantName]];
                urlComponents.queryItems = queryItems;


                NSMutableDictionary *redirectCopy = self.redirect.mutableCopy;
                redirectCopy[@"return_url"] = urlComponents.URL.absoluteString;
                
                return redirectCopy.copy;
            }
        }

    }

    return self.redirect;

}

#pragma mark - STPFormEncodable

+ (NSString *)rootObjectName {
    return nil;
}

+ (NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             NSStringFromSelector(@selector(rawTypeString)): @"type",
             NSStringFromSelector(@selector(amount)): @"amount",
             NSStringFromSelector(@selector(currency)): @"currency",
             NSStringFromSelector(@selector(flowString)): @"flow",
             NSStringFromSelector(@selector(metadata)): @"metadata",
             NSStringFromSelector(@selector(owner)): @"owner",
             NSStringFromSelector(@selector(redirectDictionaryWithMerchantNameIfNecessary)): @"redirect",
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
