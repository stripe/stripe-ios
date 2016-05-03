//
//  STPSourceListViewController.m
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodsViewController.h"
#import "STPBackendAPIAdapter.h"
#import "STPAPIClient.h"
#import "STPToken.h"
#import "STPCard.h"
#import "NSArray+Stripe_BoundSafe.h"
#import "UINavigationController+Stripe_Completion.h"
#import "UIViewController+Stripe_ParentViewController.h"
#import "STPPaymentCardEntryViewController.h"
#import "STPCardPaymentMethod.h"
#import "STPApplePayPaymentMethod.h"
#import "STPPaymentContext.h"
#import "UIColor+Stripe.h"
#import "UIFont+Stripe.h"
#import "UIImage+Stripe.h"
#import "NSString+Stripe_CardBrands.h"

static NSString *const STPPaymentMethodCellReuseIdentifier = @"STPPaymentMethodCellReuseIdentifier";
static NSInteger STPPaymentMethodCardListSection = 0;
static NSInteger STPPaymentMethodAddCardSection = 1;

@interface STPPaymentMethodsViewController()<UITableViewDataSource, UITableViewDelegate>
@property(nonatomic)STPPaymentContext *paymentContext;
@property(nonatomic, weak, nullable)id<STPPaymentMethodsViewControllerDelegate>delegate;

@property(nonatomic, weak)UIActivityIndicatorView *activityIndicator;
@property(nonatomic, weak)UITableView *tableView;
@property(nonatomic)BOOL loading;

@end

@implementation STPPaymentMethodsViewController

- (instancetype)initWithPaymentContext:(STPPaymentContext *)paymentContext
                              delegate:(nonnull id<STPPaymentMethodsViewControllerDelegate>)delegate {
    self = [super init];
    if (self) {
        _paymentContext = paymentContext;
        _delegate = delegate;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor stp_backgroundGreyColor];
    
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [activityIndicator startAnimating];
    [self.view addSubview:activityIndicator];
    self.activityIndicator = activityIndicator;
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    tableView.alpha = 0;
    tableView.dataSource = self;
    tableView.delegate = self;
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:STPPaymentMethodCellReuseIdentifier];
    tableView.sectionHeaderHeight = 30;
    tableView.separatorInset = UIEdgeInsetsMake(0, 18, 0, 0);
    tableView.tintColor = [UIColor stp_linkBlueColor];
    self.tableView = tableView;
    [self.view addSubview:tableView];
    
    UIImageView *cardImageView = [[UIImageView alloc] initWithImage:[UIImage stp_largeCardFrontImage]];
    cardImageView.contentMode = UIViewContentModeCenter;
    cardImageView.frame = CGRectMake(0, 0, self.view.bounds.size.width, cardImageView.bounds.size.height + (57 * 2));
    self.tableView.tableHeaderView = cardImageView;
    
    self.navigationItem.title = NSLocalizedString(@"Choose Payment", nil);
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", nil) style:UIBarButtonItemStylePlain target:nil action:nil];
    __weak typeof(self) weakself = self;
    [self.paymentContext onSuccess:^{
        [UIView animateWithDuration:0.2 animations:^{
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 1)];
            [weakself.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
            weakself.tableView.alpha = 1;
        } completion:^(__unused BOOL finished) {
            [weakself.activityIndicator stopAnimating];
        }];
    }];
    self.loading = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    [self.paymentContext willAppear];
    NSDictionary *titleTextAttributes = @{NSFontAttributeName:[UIFont stp_navigationBarFont]};
    self.navigationController.navigationBar.titleTextAttributes = titleTextAttributes;
    if ([self stp_isTopNavigationController]) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    } else {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.bounds;
    self.activityIndicator.center = self.view.center;
}

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView *)tableView {
    return 2;
}

- (void)cancel:(__unused id)sender {
    [self.delegate paymentMethodsViewControllerDidCancel:self];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:STPPaymentMethodCellReuseIdentifier forIndexPath:indexPath];
    cell.textLabel.font = [UIFont systemFontOfSize:17];
    if (indexPath.section == STPPaymentMethodCardListSection) {
        id<STPPaymentMethod> paymentMethod = self.paymentContext.paymentMethods[indexPath.row];
        cell.imageView.image = paymentMethod.image;
        BOOL selected = [paymentMethod isEqual:self.paymentContext.selectedPaymentMethod];
        cell.textLabel.attributedText = [self buildAttributedStringForPaymentMethod:paymentMethod selected:selected];
        cell.accessoryType = selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    } else if (indexPath.section == STPPaymentMethodAddCardSection) {
        cell.textLabel.textColor = [UIColor stp_linkBlueColor];
        cell.imageView.image = [UIImage stp_addIcon];
        cell.textLabel.text = NSLocalizedString(@"Add New Card...", nil);
    }
    return cell;
}

- (NSAttributedString *)buildAttributedStringForPaymentMethod:(id<STPPaymentMethod>)paymentMethod
                                                     selected:(BOOL)selected {
    if ([paymentMethod isKindOfClass:[STPCardPaymentMethod class]]) {
        return [self buildAttributedStringForCard:((STPCardPaymentMethod *)paymentMethod).card selected:selected];
    } else if ([paymentMethod isKindOfClass:[STPApplePayPaymentMethod class]]) {
        NSString *label = NSLocalizedString(@"Apple Pay", nil);
        UIColor *primaryColor = selected ? [UIColor stp_linkBlueColor] : [UIColor stp_darkTextColor];
        return [[NSAttributedString alloc] initWithString:label attributes:@{NSForegroundColorAttributeName: primaryColor}];
    }
    return nil;
}

- (NSAttributedString *)buildAttributedStringForCard:(STPCard *)card selected:(BOOL)selected {
    NSString *template = NSLocalizedString(@"%@ Ending In %@", @"{card brand} ending in {last4}");
    NSString *brandString = [NSString stringWithCardBrand:card.brand];
    NSString *label = [NSString stringWithFormat:template, brandString, card.last4];
    UIColor *primaryColor = selected ? [UIColor stp_linkBlueColor] : [UIColor stp_darkTextColor];
    UIColor *secondaryColor = [primaryColor colorWithAlphaComponent:0.6f];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:label attributes:@{NSForegroundColorAttributeName: secondaryColor}];
    [attributedString addAttribute:NSForegroundColorAttributeName value:primaryColor range:[label rangeOfString:brandString]];
    [attributedString addAttribute:NSForegroundColorAttributeName value:primaryColor range:[label rangeOfString:card.last4]];
    return [attributedString copy];
}

- (void)tableView:(__unused UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == STPPaymentMethodCardListSection) {
        id<STPPaymentMethod> paymentMethod = [self.paymentContext.paymentMethods stp_boundSafeObjectAtIndex:indexPath.row];
        [self.paymentContext selectPaymentMethod:paymentMethod];
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:STPPaymentMethodCardListSection] withRowAnimation:UITableViewRowAnimationFade];
        [self finishWithPaymentMethod:paymentMethod];
    } else if (indexPath.section == STPPaymentMethodAddCardSection) {
        __weak typeof(self) weakself = self;
        STPPaymentCardEntryViewController *paymentCardViewController;
        paymentCardViewController = [[STPPaymentCardEntryViewController alloc] initWithAPIClient:self.paymentContext.apiClient requiredBillingAddressFields:self.paymentContext.requiredBillingAddressFields completion:^(STPToken *token, STPErrorBlock tokenCompletion) {
            if (token) {
                [self.paymentContext addToken:token completion:^(id<STPPaymentMethod> paymentMethod, NSError *error) {
                    if (error) {
                        tokenCompletion(error);
                    } else {
                        [weakself.paymentContext selectPaymentMethod:paymentMethod];
                        [weakself.tableView reloadData];
                        [weakself finishWithPaymentMethod:paymentMethod];
                        tokenCompletion(nil);
                    }
                }];
            } else {
                [self.navigationController stp_popViewControllerAnimated:YES completion:^{
                    tokenCompletion(nil);
                }];
            }
        }];
        [self.navigationController pushViewController:paymentCardViewController animated:YES];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)finishWithPaymentMethod:(id<STPPaymentMethod>)paymentMethod {
    [self.delegate paymentMethodsViewController:self didSelectPaymentMethod:paymentMethod];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if ([self tableView:tableView numberOfRowsInSection:section] == 0) {
        return 0.01f;
    }
    return 27.0f;
}

- (CGFloat)tableView:(__unused UITableView *)tableView heightForHeaderInSection:(__unused NSInteger)section {
    return 0.01f;
}

@end
