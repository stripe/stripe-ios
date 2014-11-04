//
//  STPTestPaymentSummaryViewController.m
//  StripeExample
//
//  Created by Jack Flintermann on 9/8/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000

#import "STPTestPaymentSummaryViewController.h"
#import "STPTestDataTableViewController.h"
#import "STPTestCardStore.h"
#import "STPTestAddressStore.h"
#import "STPTestShippingMethodStore.h"
#import "PKPayment+STPTestKeys.h"

NSString *const STPTestPaymentAuthorizationSummaryItemIdentifier = @"STPTestPaymentAuthorizationSummaryItemIdentifier";
NSString *const STPTestPaymentAuthorizationTestDataIdentifier = @"STPTestPaymentAuthorizationTestDataIdentifier";

NSString *const STPTestPaymentSectionTitleCards = @"Credit Card";
NSString *const STPTestPaymentSectionTitleBillingAddress = @"Billing Address";
NSString *const STPTestPaymentSectionTitleShippingAddress = @"Shipping Address";
NSString *const STPTestPaymentSectionTitleShippingMethod = @"Shipping Method";
NSString *const STPTestPaymentSectionTitlePayment = @"Payment";

@interface STPTestPaymentSummaryItemCell : UITableViewCell
@end

@interface STPTestPaymentDataCell : UITableViewCell
@end

@interface STPTestPaymentSummaryViewController () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *payButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) PKPaymentRequest *paymentRequest;
@property (nonatomic) NSArray *summaryItems;
@property (nonatomic) STPTestCardStore *cardStore;
@property (nonatomic) STPTestAddressStore *billingAddressStore;
@property (nonatomic) STPTestAddressStore *shippingAddressStore;
@property (nonatomic) STPTestShippingMethodStore *shippingMethodStore;
@property (nonatomic) NSArray *sectionTitles;
@end

@implementation STPTestPaymentSummaryViewController

- (instancetype)initWithPaymentRequest:(PKPaymentRequest *)paymentRequest {
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        _paymentRequest = paymentRequest;
        _summaryItems = paymentRequest.paymentSummaryItems;
        _cardStore = [STPTestCardStore new];
        _billingAddressStore = [STPTestAddressStore new];
        _shippingAddressStore = [STPTestAddressStore new];
        _shippingMethodStore = [[STPTestShippingMethodStore alloc] initWithShippingMethods:paymentRequest.shippingMethods];
        self.navigationItem.rightBarButtonItem =
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    }
    return self;
}

- (void)updateSectionTitles {
    NSMutableArray *array = [NSMutableArray array];
    [array addObject:STPTestPaymentSectionTitleCards];
    if (self.paymentRequest.requiredBillingAddressFields != PKAddressFieldNone) {
        [array addObject:STPTestPaymentSectionTitleBillingAddress];
    }
    if (self.paymentRequest.requiredShippingAddressFields != PKAddressFieldNone) {
        [array addObject:STPTestPaymentSectionTitleShippingAddress];
    }
    if (self.shippingMethodStore.allItems.count) {
        [array addObject:STPTestPaymentSectionTitleShippingMethod];
    }
    [array addObject:STPTestPaymentSectionTitlePayment];
    self.sectionTitles = [array copy];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateSectionTitles];
    [self.tableView registerClass:[STPTestPaymentSummaryItemCell class] forCellReuseIdentifier:STPTestPaymentAuthorizationSummaryItemIdentifier];
    [self.tableView registerClass:[STPTestPaymentDataCell class] forCellReuseIdentifier:STPTestPaymentAuthorizationTestDataIdentifier];
    if (self.paymentRequest.requiredShippingAddressFields != PKAddressFieldNone) {
        [self didSelectShippingAddress];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (IBAction)makePayment:(id)sender {
    self.payButton.hidden = YES;
    [self.activityIndicator startAnimating];

    PKPayment *payment = [PKPayment new];
    NSDictionary *card = self.cardStore.selectedItem;

    payment.stp_testCardNumber = card[@"number"];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([payment respondsToSelector:@selector(setShippingMethod:)] && self.shippingMethodStore.selectedItem) {
        [payment performSelector:@selector(setShippingMethod:) withObject:self.shippingMethodStore.selectedItem];
    }
    ABRecordRef shippingRecord = [self.shippingAddressStore contactForSelectedItemObscure:NO];
    if ([payment respondsToSelector:@selector(setShippingAddress:)] && shippingRecord) {
        [payment performSelector:@selector(setShippingAddress:) withObject:(__bridge id)(shippingRecord)];
    }
    ABRecordRef billingRecord = [self.billingAddressStore contactForSelectedItemObscure:NO];
    if ([payment respondsToSelector:@selector(setBillingAddress:)] && billingRecord) {
        [payment performSelector:@selector(setBillingAddress:) withObject:(__bridge id)(billingRecord)];
    }
#pragma clang diagnostic pop

    PKPaymentAuthorizationViewController *auth = (PKPaymentAuthorizationViewController *)self;

    [self.activityIndicator startAnimating];
    [self.delegate paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)auth
                                  didAuthorizePayment:payment
                                           completion:^(PKPaymentAuthorizationStatus status) {
                                               [self.activityIndicator stopAnimating];
                                               [self.delegate paymentAuthorizationViewControllerDidFinish:auth];
                                           }];
}

- (void)cancel:(id)sender {
    [self.delegate paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)self];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sectionTitles.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sectionTitles[section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *title = self.sectionTitles[section];
    if ([title isEqualToString:STPTestPaymentSectionTitlePayment]) {
        return self.summaryItems.count;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *title = self.sectionTitles[indexPath.section];
    NSString *identifier = [title isEqualToString:STPTestPaymentSectionTitlePayment] ? STPTestPaymentAuthorizationTestDataIdentifier :
                                                                                       STPTestPaymentAuthorizationSummaryItemIdentifier;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    [self configureCell:cell forRowAtIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *title = self.sectionTitles[indexPath.section];
    if ([title isEqualToString:STPTestPaymentSectionTitlePayment]) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        PKPaymentSummaryItem *item = self.summaryItems[indexPath.row];
        NSString *text = [item.label uppercaseString];
        if (indexPath.row == [self.tableView numberOfRowsInSection:indexPath.section] - 1) {
            if (text == nil) {
                text = @"";
            }
            text = [@"PAY " stringByAppendingString:text];
        }
        cell.textLabel.text = text;

        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", item.amount.stringValue, self.paymentRequest.currencyCode];
        return;
    }

    id<STPTestDataStore> store = [self storeForSection:title];
    NSArray *descriptions = [store descriptionsForItem:store.selectedItem];

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = descriptions[0];
    cell.detailTextLabel.text = descriptions[1];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *title = self.sectionTitles[indexPath.section];
    if ([title isEqualToString:STPTestPaymentSectionTitlePayment]) {
        return 20.0f;
    }
    return 44.0f;
}

- (id<STPTestDataStore>)storeForSection:(NSString *)section {
    id<STPTestDataStore> store;
    if ([section isEqualToString:STPTestPaymentSectionTitleCards]) {
        store = self.cardStore;
    }
    if ([section isEqualToString:STPTestPaymentSectionTitleShippingAddress]) {
        store = self.shippingAddressStore;
    }
    if ([section isEqualToString:STPTestPaymentSectionTitleBillingAddress]) {
        store = self.billingAddressStore;
    }
    if ([section isEqualToString:STPTestPaymentSectionTitleShippingMethod]) {
        store = self.shippingMethodStore;
    }
    return store;
}

#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section != [tableView numberOfSections] - 1;
}

- (void)didSelectShippingAddress {
    if ([self.delegate respondsToSelector:@selector(paymentAuthorizationViewController:didSelectShippingAddress:completion:)]) {
        [self.activityIndicator startAnimating];
        self.payButton.enabled = NO;
        self.tableView.userInteractionEnabled = NO;
        ABRecordRef record = [self.shippingAddressStore contactForSelectedItemObscure:YES];
        [self.delegate paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)self
                                 didSelectShippingAddress:record
                                               completion:^(PKPaymentAuthorizationStatus status, NSArray *shippingMethods, NSArray *summaryItems) {
                                                   if (status == PKPaymentAuthorizationStatusFailure) {
                                                       [self.delegate paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)self];
                                                       return;
                                                   }
                                                   self.summaryItems = summaryItems;
                                                   [self.shippingMethodStore setShippingMethods:shippingMethods];
                                                   [self updateSectionTitles];
                                                   [self.tableView reloadData];
                                                   self.payButton.enabled = YES;
                                                   self.tableView.userInteractionEnabled = YES;
                                                   [self.activityIndicator stopAnimating];
                                               }];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    id<STPTestDataStore> store = [self storeForSection:self.sectionTitles[indexPath.section]];
    STPTestDataTableViewController *controller = [[STPTestDataTableViewController alloc] initWithStore:store];
    if (store == self.shippingAddressStore) {
        controller.callback = ^void(id item) { [self didSelectShippingAddress]; };
    }
    if (store == self.shippingMethodStore) {
        controller.callback = ^void(id item) {
            if ([self.delegate respondsToSelector:@selector(paymentAuthorizationViewController:didSelectShippingMethod:completion:)]) {
                [self.activityIndicator startAnimating];
                self.payButton.enabled = NO;
                self.tableView.userInteractionEnabled = NO;
                PKPaymentAuthorizationViewController *vc = (PKPaymentAuthorizationViewController *)self;
                [self.delegate paymentAuthorizationViewController:vc
                                          didSelectShippingMethod:item
                                                       completion:^(PKPaymentAuthorizationStatus status, NSArray *summaryItems) {
                                                           if (status == PKPaymentAuthorizationStatusFailure) {
                                                               [self.delegate paymentAuthorizationViewControllerDidFinish:vc];
                                                               return;
                                                           }
                                                           self.summaryItems = summaryItems;
                                                           [self updateSectionTitles];
                                                           [self.tableView reloadData];
                                                           self.payButton.enabled = YES;
                                                           self.tableView.userInteractionEnabled = YES;
                                                           [self.activityIndicator stopAnimating];
                                                       }];
            }
        };
    }
    [self.navigationController pushViewController:controller animated:YES];
}

@end

@implementation STPTestPaymentSummaryItemCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}
@end

@implementation STPTestPaymentDataCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:12.0];
        self.detailTextLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:12.0];
    }
    return self;
}
@end

#endif
