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
#import "STPPaymentMethodsStore.h"

static NSString *const STPPaymentMethodCellReuseIdentifier = @"STPPaymentMethodCellReuseIdentifier";

@interface STPPaymentMethodsViewController()<UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, weak)id<STPPaymentMethodsViewControllerDelegate> delegate;
@property(nonatomic) STPPaymentMethodsStore *paymentMethodsStore;
@property(nonatomic, weak)UITableView *tableView;
@property(nonatomic, weak)UIBarButtonItem *addButton;
@property(nonatomic)BOOL loading;

@end

@implementation STPPaymentMethodsViewController

- (nonnull instancetype)initWithPaymentMethodsStore:(nonnull STPPaymentMethodsStore *)paymentMethodsStore
                                           delegate:(nonnull id<STPPaymentMethodsViewControllerDelegate>)delegate {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _paymentMethodsStore = paymentMethodsStore;
        _delegate = delegate;
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
    [self.paymentMethodsStore loadSources:^(NSError * error) {
        self.loading = NO;
        if (error) {
            NSAssert(NO, @"TODO");
            return;
        }
        [self.tableView reloadData];
    }];
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
    return self.paymentMethodsStore.paymentMethods.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    STPPaymentMethodCell *cell = [tableView dequeueReusableCellWithIdentifier:STPPaymentMethodCellReuseIdentifier forIndexPath:indexPath];
    id<STPPaymentMethod> paymentMethod = self.paymentMethodsStore.paymentMethods[indexPath.row];
    BOOL selected = paymentMethod == self.paymentMethodsStore.selectedPaymentMethod;
    [cell configureWithPaymentMethod:paymentMethod selected:selected];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    id<STPPaymentMethod> paymentMethod = [self.paymentMethodsStore.paymentMethods stp_boundSafeObjectAtIndex:indexPath.row];
    [self.delegate paymentMethodsViewController:self didFinishWithPaymentMethod:paymentMethod];
}

@end
