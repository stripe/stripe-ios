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
#import "UIViewController+Stripe_ParentViewController.h"
#import "STPPaymentCardEntryViewController.h"
#import "STPCardPaymentMethod.h"
#import "STPPaymentContext.h"
#import "UIColor+Stripe.h"
#import "UIFont+Stripe.h"
#import "UIImage+Stripe.h"

static NSString *const STPPaymentMethodCellReuseIdentifier = @"STPPaymentMethodCellReuseIdentifier";
static NSString *const STPPaymentMethodAddCellReuseIdentifier = @"STPPaymentMethodAddCellReuseIdentifier";
static NSInteger STPPaymentMethodCardListSection = 0;
static NSInteger STPPaymentMethodAddCardSection = 1;

@interface STPPaymentMethodsViewController()<UITableViewDataSource, UITableViewDelegate>
@property(nonatomic)STPPaymentContext *paymentContext;
@property(nonatomic, copy)STPPaymentMethodSelectionBlock completion;

@property(nonatomic, weak)UITableView *tableView;
@property(nonatomic)BOOL loading;

@end

@implementation STPPaymentMethodsViewController

- (instancetype)initWithPaymentContext:(STPPaymentContext *)paymentContext {
    self = [super init];
    if (self) {
        _paymentContext = paymentContext;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = [UIColor stp_backgroundGreyColor];

    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    tableView.dataSource = self;
    tableView.delegate = self;
    [tableView registerClass:[STPPaymentMethodCell class] forCellReuseIdentifier:STPPaymentMethodCellReuseIdentifier];
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:STPPaymentMethodAddCellReuseIdentifier];
    tableView.sectionHeaderHeight = 40;
    tableView.separatorInset = UIEdgeInsetsMake(0, 18, 0, 0);
    tableView.tintColor = [UIColor stp_linkBlueColor];
    self.tableView = tableView;
    [self.view addSubview:tableView];
    
    UIImageView *cardImageView = [[UIImageView alloc] initWithImage:[UIImage stp_largeCardFrontImage]];
    cardImageView.contentMode = UIViewContentModeCenter;
    self.tableView.tableHeaderView = cardImageView;
    
    self.navigationItem.title = NSLocalizedString(@"Choose Payment", nil);
    [self.paymentContext performInitialLoad];
    [self.paymentContext onSuccess:^{
        [UIView animateWithDuration:0.2 animations:^{
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 1)];
            [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
        }];
    }];
    self.loading = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self resetSelectedCell];
    NSDictionary *titleTextAttributes = @{NSFontAttributeName:[UIFont stp_navigationBarFont]};
    self.navigationController.navigationBar.titleTextAttributes = titleTextAttributes;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.bounds;
    CGFloat baseInset = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    self.tableView.contentInset = UIEdgeInsetsMake(baseInset + self.tableView.sectionHeaderHeight, 0, 0, 0);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
}

- (void)resetSelectedCell {
    for (id<STPPaymentMethod> paymentMethod in self.paymentContext.paymentMethods) {
        NSInteger row = [self.paymentContext.paymentMethods indexOfObject:paymentMethod];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:STPPaymentMethodCardListSection];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        if ([paymentMethod isEqual:self.paymentContext.selectedPaymentMethod]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(__unused NSInteger)section {
    if (section == STPPaymentMethodCardListSection) {
        return self.paymentContext.paymentMethods.count;
    } else if (section == STPPaymentMethodAddCardSection) {
        return 1;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if (indexPath.section == STPPaymentMethodCardListSection) {
        cell = [tableView dequeueReusableCellWithIdentifier:STPPaymentMethodCellReuseIdentifier forIndexPath:indexPath];
        id<STPPaymentMethod> paymentMethod = self.paymentContext.paymentMethods[indexPath.row];
        BOOL selected = [paymentMethod isEqual:self.paymentContext.selectedPaymentMethod];
        [(STPPaymentMethodCell *)cell configureWithPaymentMethod:paymentMethod selected:selected];
    } else if (indexPath.section == STPPaymentMethodAddCardSection) {
        cell = [tableView dequeueReusableCellWithIdentifier:STPPaymentMethodAddCellReuseIdentifier forIndexPath:indexPath];
        cell.textLabel.textColor = [UIColor stp_linkBlueColor];
        cell.imageView.image = [UIImage stp_addIcon];
        cell.textLabel.text = NSLocalizedString(@"Add New Card...", nil);
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == STPPaymentMethodCardListSection) {
        id<STPPaymentMethod> paymentMethod = [self.paymentContext.paymentMethods stp_boundSafeObjectAtIndex:indexPath.row];
        [self selectPaymentMethod:paymentMethod];
        [self finishWithPaymentMethod:paymentMethod];
    } else if (indexPath.section == STPPaymentMethodAddCardSection) {
        BOOL useNavigationTransition = [self stp_isTopNavigationController];
        STPPaymentCardEntryViewController *paymentCardViewController;
        paymentCardViewController = [[STPPaymentCardEntryViewController alloc] initWithAPIClient:self.paymentContext.apiClient completion:^(id<STPSource> source) {
            id<STPPaymentMethod> paymentMethod = [[STPCardPaymentMethod alloc] initWithSource:source];
            [self selectPaymentMethod:paymentMethod];
            [self.tableView reloadData];
            if (useNavigationTransition) {
                [self.navigationController stp_popViewControllerAnimated:YES completion:^{
                    if (source) {
                        [self finishWithPaymentMethod:paymentMethod];
                    }
                }];
            } else {
                [self dismissViewControllerAnimated:YES completion:^{
                    if (source) {
                        [self finishWithPaymentMethod:paymentMethod];
                    }
                }];
            }
            
        }];
        if (useNavigationTransition) {
            [self.navigationController pushViewController:paymentCardViewController animated:YES];
        } else {
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:paymentCardViewController];
            [self presentViewController:navigationController animated:YES completion:nil];
        }
    }
}

- (void)selectPaymentMethod:(id<STPPaymentMethod>)paymentMethod {
    [self.paymentContext selectPaymentMethod:paymentMethod];
    [self resetSelectedCell];
}

- (void)finishWithPaymentMethod:(id<STPPaymentMethod>)paymentMethod {
    if (self.completion) {
        self.completion(paymentMethod);
        self.completion = nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return tableView.sectionHeaderHeight;
    }
    return tableView.sectionHeaderHeight / 2;
}

@end
