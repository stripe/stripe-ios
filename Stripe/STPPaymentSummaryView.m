//
//  STPPaymentSummaryView.m
//  Stripe
//
//  Created by Ben Guo on 3/24/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentSummaryView.h"
#import "STPPaymentRequest.h"
#import "NSArray+Stripe_BoundSafe.h"
#import "STPLineItem.h"
#import "STPLineItemCell.h"
#import "STPSource.h"
#import "STPBasicSourceProvider.h"
#import "STPPaymentMethodCell.h"
#import "STPPaymentResult.h"

static NSString *const STPPaymentMethodCellReuseIdentifier = @"STPPaymentMethodCellReuseIdentifier";
static NSString *const STPLineItemCellReuseIdentifier = @"STPLineItemCellReuseIdentifier";

typedef NS_ENUM(NSInteger, STPPaymentSummaryViewControllerSection) {
    STPPaymentSummaryViewControllerSectionPaymentMethod,
    STPPaymentSummaryViewControllerSectionShippingAddress,
    STPPaymentSummaryViewControllerSectionLineItems,
};

@interface STPPaymentSummaryView()<UITableViewDataSource, UITableViewDelegate>

@property(nonatomic, weak) id<STPPaymentSummaryViewDelegate>delegate;
@property(nonatomic, weak) UITableView *tableView;

@property(nonatomic) NSArray<STPLineItem *> *lineItems;
@property(nonatomic, nonnull) id<STPSourceProvider> sourceProvider;

@end

@implementation STPPaymentSummaryView

- (instancetype)initWithPaymentRequest:(nonnull STPPaymentRequest *)paymentRequest
                        sourceProvider:(nonnull id<STPSourceProvider>) sourceProvider
                              delegate:(id<STPPaymentSummaryViewDelegate>)delegate {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _delegate = delegate;
        _sourceProvider = sourceProvider;
        _lineItems = paymentRequest.lineItems;
        _cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                      target:self action:@selector(cancel:)];
        _payButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                   target:self action:@selector(pay:)];
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.bounds style:UITableViewStylePlain];
        tableView.dataSource = self;
        tableView.delegate = self;
        [tableView registerClass:[STPPaymentMethodCell class] forCellReuseIdentifier:STPPaymentMethodCellReuseIdentifier];
        [tableView registerClass:[STPLineItemCell class] forCellReuseIdentifier:STPLineItemCellReuseIdentifier];
        _tableView = tableView;
        self.backgroundColor = [UIColor whiteColor];
        [self addSubview:tableView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.tableView.frame = self.bounds;
}

- (void)reload {
    [self.tableView reloadData];
}

- (void)cancel:(__unused id)sender {
    [self.delegate paymentSummaryViewDidCancel:self];
}

- (void)pay:(__unused id)sender {
    [self.delegate paymentSummaryViewDidPressBuy:self];
}

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case STPPaymentSummaryViewControllerSectionPaymentMethod:
            return 1;
        case STPPaymentSummaryViewControllerSectionLineItems:
            return self.lineItems.count;
        default:
            return 0;
    }
}

- (NSString *)tableView:(__unused UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case STPPaymentSummaryViewControllerSectionPaymentMethod:
            return @"Payment Method";
        case STPPaymentSummaryViewControllerSectionShippingAddress:
            return @"Shipping";
        case STPPaymentSummaryViewControllerSectionLineItems:
            return @"Payment Summary";
        default:
            return nil;
    }
}

- (UITableViewCell *)tableView:(__unused UITableView *)tableView cellForRowAtIndexPath:(__unused NSIndexPath *)indexPath {
    UITableViewCell *cell;
    switch (indexPath.section) {
        case STPPaymentSummaryViewControllerSectionPaymentMethod: {
            cell = [tableView dequeueReusableCellWithIdentifier:STPPaymentMethodCellReuseIdentifier];
            id<STPSource> source = self.sourceProvider.selectedSource;
            if (source) {
                cell.textLabel.text = source.label;
            } else {
                cell.textLabel.text = @"No selected payment method";
            }
            break;
        }
        case STPPaymentSummaryViewControllerSectionLineItems: {
            cell = [tableView dequeueReusableCellWithIdentifier:STPLineItemCellReuseIdentifier forIndexPath:indexPath];
            STPLineItem *lineItem = self.lineItems[indexPath.row];
            cell.textLabel.text = lineItem.label;
            cell.detailTextLabel.text = lineItem.amount.stringValue;
            break;
        }
        default:
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        [self.delegate paymentSummaryViewDidEditPaymentMethod:self];
    }
}

@end
