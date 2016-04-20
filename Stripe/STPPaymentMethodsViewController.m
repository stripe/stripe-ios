//
//  STPSourceListViewController.m
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodsViewController.h"
#import "STPBackendAPIAdapter.h"
#import "STPPaymentMethodCell.h"
#import "STPAPIClient.h"
#import "STPToken.h"
#import "STPCard.h"
#import "NSArray+Stripe_BoundSafe.h"
#import "UINavigationController+Stripe_Completion.h"
#import "STPPaymentCardEntryViewController.h"
#import "STPCardPaymentMethod.h"
#import "STPPaymentContext.h"

static NSString *const STPPaymentMethodCellReuseIdentifier = @"STPPaymentMethodCellReuseIdentifier";

@interface STPPaymentMethodsViewController()<UITableViewDataSource, UITableViewDelegate>
@property(nonatomic)STPPaymentContext *paymentContext;
@property(nonatomic, copy)STPPaymentMethodSelectionBlock completion;
@property(nonatomic, weak)UITableView *tableView;
@property(nonatomic, weak)UIBarButtonItem *addButton;
@property(nonatomic)BOOL loading;

@end

@implementation STPPaymentMethodsViewController

- (instancetype)initWithPaymentContext:(STPPaymentContext *)paymentContext
                            completion:(STPPaymentMethodSelectionBlock)completion {
    self = [super init];
    if (self) {
        _paymentContext = paymentContext;
        _completion = completion;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.dataSource = self;
    tableView.delegate = self;
    [tableView registerClass:[STPPaymentMethodCell class] forCellReuseIdentifier:STPPaymentMethodCellReuseIdentifier];
    self.tableView = tableView;
    [self.view addSubview:tableView];
    
    // TODO: wire up back button item here

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addSource:)];
    self.addButton = addButton;
    self.navigationItem.rightBarButtonItem = addButton;

    self.loading = YES;
    // TODO
//    [self.paymentMethodStore loadSources:^(NSError * error) {
//        self.loading = NO;
//        if (error) {
//            NSAssert(NO, @"TODO");
//            return;
//        }
//        [self.tableView reloadData];
//    }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.bounds;
}

- (void)reload {
    [self.tableView reloadData];
}

- (void)setLoading:(BOOL)loading {
    _loading = loading;
    self.addButton.enabled = !loading;
}

- (void)addSource:(__unused id)sender {

}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(__unused NSInteger)section {
    return self.paymentContext.paymentMethods.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    STPPaymentMethodCell *cell = [tableView dequeueReusableCellWithIdentifier:STPPaymentMethodCellReuseIdentifier forIndexPath:indexPath];
    id<STPPaymentMethod> paymentMethod = self.paymentContext.paymentMethods[indexPath.row];
    BOOL selected = paymentMethod == self.paymentContext.selectedPaymentMethod;
    [cell configureWithPaymentMethod:paymentMethod selected:selected];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    id<STPPaymentMethod> paymentMethod = [self.paymentContext.paymentMethods stp_boundSafeObjectAtIndex:indexPath.row];
    if (self.completion) {
        self.completion(paymentMethod);
        self.completion = nil;
    }
}

@end
