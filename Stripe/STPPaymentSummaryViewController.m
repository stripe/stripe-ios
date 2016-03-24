//
//  STPPaymentSummaryViewController.m
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentSummaryViewController.h"
#import "STPPaymentAuthorizationViewController.h"
#import "STPPaymentRequest.h"
#import "UIViewController+Stripe_ParentViewController.h"
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

@interface STPPaymentSummaryViewController()<UITableViewDataSource, UITableViewDelegate>

@property(nonatomic, weak) UITableView *tableView;
@property(nonatomic) NSArray<STPLineItem *> *lineItems;
@property(nonatomic, nonnull) id<STPSourceProvider> sourceProvider;

@end

@implementation STPPaymentSummaryViewController

- (nonnull instancetype)initWithPaymentRequest:(nonnull STPPaymentRequest *)paymentRequest sourceProvider:(nonnull id<STPSourceProvider>) sourceProvider {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _paymentRequest = paymentRequest;
        _sourceProvider = sourceProvider;
        _lineItems = paymentRequest.lineItems;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.dataSource = self;
    tableView.delegate = self;
    [tableView registerClass:[STPPaymentMethodCell class] forCellReuseIdentifier:STPPaymentMethodCellReuseIdentifier];
    [tableView registerClass:[STPLineItemCell class] forCellReuseIdentifier:STPLineItemCellReuseIdentifier];
    self.tableView = tableView;
    [self.view addSubview:tableView];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(pay:)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)cancel:(__unused id)sender {
    [self.delegate paymentSummaryViewControllerDidCancel:self];
}

- (void)pay:(__unused id)sender {
    [self.delegate paymentSummaryViewControllerDidPressBuy:self];
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
        [self.delegate paymentSummaryViewControllerDidEditPaymentMethod:self];
    }
}

@end
