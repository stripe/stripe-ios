//
//  STPPaymentSummaryViewController.m
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <PassKit/PassKit.h>
#import "STPPaymentSummaryViewController.h"
#import "STPPaymentAuthorizationViewController.h"
#import "UIViewController+Stripe_ParentViewController.h"
#import "NSArray+Stripe_BoundSafe.h"
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

@property(nonatomic, weak, nullable) id<STPPaymentSummaryViewControllerDelegate> delegate;
@property(nonatomic, weak) UITableView *tableView;
@property(nonatomic) NSArray<PKPaymentSummaryItem *> *lineItems;
@property(nonatomic, nonnull) PKPaymentRequest *paymentRequest;
@property(nonatomic, nonnull, readonly) id<STPSourceProvider> sourceProvider;

@end

@implementation STPPaymentSummaryViewController
@dynamic view;

- (nonnull instancetype)initWithPaymentRequest:(nonnull PKPaymentRequest *)paymentRequest
                                sourceProvider:(nonnull id<STPSourceProvider>) sourceProvider
                                      delegate:(nonnull id<STPPaymentSummaryViewControllerDelegate>)delegate {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _delegate = delegate;
        _paymentRequest = paymentRequest;
        _sourceProvider = sourceProvider;
        _lineItems = paymentRequest.paymentSummaryItems;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    tableView.dataSource = self;
    tableView.delegate = self;
    [tableView registerClass:[STPPaymentMethodCell class] forCellReuseIdentifier:STPPaymentMethodCellReuseIdentifier];
    [tableView registerClass:[STPLineItemCell class] forCellReuseIdentifier:STPLineItemCellReuseIdentifier];
    _tableView = tableView;
    [self.view addSubview:tableView];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                  target:self action:@selector(cancel:)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                          target:self action:@selector(pay:)];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.bounds;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)cancel:(__unused id)sender {
    [self.delegate paymentSummaryViewControllerDidCancel:self];
}

- (void)pay:(__unused id)sender {
    [self.delegate paymentSummaryViewController:self didPressBuyCompletion:^(__unused NSError * _Nullable error) {
        // TODO update UI based on result
    }];
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
            PKPaymentSummaryItem *lineItem = self.lineItems[indexPath.row];
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
