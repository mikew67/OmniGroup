// Copyright 2010-2015 Omni Development, Inc. All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniUI/OUISegmentedViewController.h>

RCS_ID("$Id$")

@interface OUISegmentedViewController () <UINavigationBarDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) UINavigationBar *navigationBar;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;

@property (nonatomic, weak) id<UINavigationControllerDelegate> originalNavDelegate;

@property (nonatomic, assign) CGSize selectedViewSizeAfterLayout;

@end

@implementation OUISegmentedViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)awakeFromNib;
{
    [super awakeFromNib];
    
    [self _setupSegmentedControl];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationBar = [[UINavigationBar alloc] init];
    self.navigationBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.navigationBar.delegate = self;
    [self.view addSubview:self.navigationBar];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_navigationBar);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_navigationBar]|" options:0 metrics:nil views:views]];
    
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.navigationBar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];
}

#pragma mark - Public API
- (void)setViewControllers:(NSArray *)viewControllers;
{
    OBPRECONDITION(viewControllers && [viewControllers count] > 0);
    
    if (_viewControllers == viewControllers) {
        return;
    }
    
    _viewControllers = [viewControllers copy];
    self.selectedViewController = [_viewControllers firstObject];
    
    [self _setupSegmentedControl];
}

- (void)setSelectedViewController:(UIViewController *)selectedViewController;
{
    OBPRECONDITION([_viewControllers containsObject:selectedViewController]);
    
    if (_selectedViewController == selectedViewController) {
        return;
    }
    
    // Remove currently selected view controller.
    if (_selectedViewController) {
        [_selectedViewController willMoveToParentViewController:nil];
        
        if ([_selectedViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *selectedNavigationController = (UINavigationController *)_selectedViewController;
            selectedNavigationController.delegate = self.originalNavDelegate;
        }
        [_selectedViewController.view removeFromSuperview];
        
        [_selectedViewController removeFromParentViewController];
        _selectedViewController = nil;
    }
    
    _selectedViewController = selectedViewController;
    _selectedViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Move in new view controller/view. addChildViewController: automatically calls the childs willMoveToParentViewController: passing in the new parent. We shouldn't call that directly while adding the child VC.
//    [_selectedViewController willMoveToParentViewController:self];
    [self addChildViewController:_selectedViewController];

    [self.view addSubview:_selectedViewController.view];
    
    // Add constraints
    NSDictionary *views = @{ @"navigationBar" : _navigationBar, @"childView" : _selectedViewController.view };
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[childView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];

    if ([_selectedViewController isKindOfClass:[UINavigationController class]]) {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[navigationBar][childView]|"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:views]];
        UINavigationController *selectedNavigationController = (UINavigationController *)_selectedViewController;
        self.originalNavDelegate = selectedNavigationController.delegate;
        selectedNavigationController.delegate = self;
        
    }
    else {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[childView]|"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:views]];
    }
    
    [_selectedViewController didMoveToParentViewController:self];
    
    // Ensure that the segmented control is showing the correctly selected segment.
    // Make sure to use the _selectedIndex ivar directly here because the setter will end up calling into this method and we don't want to create an infinite loop.
    _selectedIndex = [self.viewControllers indexOfObject:_selectedViewController];
    self.segmentedControl.selectedSegmentIndex = _selectedIndex;
    [self.view bringSubviewToFront:self.navigationBar];
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex;
{
    if (_selectedIndex == selectedIndex) {
        return;
    }
    
    _selectedIndex = selectedIndex;
    
    UIViewController *viewControllerToSelect = self.viewControllers[selectedIndex];
    self.selectedViewController = viewControllerToSelect;
}

#pragma mark - Private API
- (void)_setupSegmentedControl;
{
    NSMutableArray *segmentTitles = [NSMutableArray array];
    for (UIViewController *vc in self.viewControllers) {
        NSString *title = vc.title;
        OBASSERT(title);
        
        [segmentTitles addObject:title];
    }
    
    
    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:segmentTitles];
    [self.segmentedControl setSelectedSegmentIndex:0];
    [self.segmentedControl addTarget:self action:@selector(_segmentValueChanged:) forControlEvents:UIControlEventValueChanged];
    
    self.navigationItem.titleView = self.segmentedControl;
    if (self.leftBarButtonItem) {
        self.navigationItem.leftBarButtonItem = self.leftBarButtonItem;
    }
    [self.navigationBar pushNavigationItem:self.navigationItem animated:NO];
}

- (void)_segmentValueChanged:(id)sender;
{
    OBPRECONDITION([sender isKindOfClass:[UISegmentedControl class]]);
    
    UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
    NSInteger selectedIndex = segmentedControl.selectedSegmentIndex;
    
    [self setSelectedIndex:selectedIndex];
}

- (void)_dismiss:(id)sender;
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)setShouldShowDismissButton:(BOOL)shouldShow;
{
    if (shouldShow) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(_dismiss:)];
    }
    else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

#pragma mark - UINavigationBarDelegate
- (UIBarPosition)positionForBar:(id <UIBarPositioning>)bar;
{
    if (bar == self.navigationBar) {
        return UIBarPositionTopAttached;
    }

    return UIBarPositionAny;
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated;
{
    if ([self.originalNavDelegate respondsToSelector:@selector(navigationController:willShowViewController:animated:)]) {
        [self.originalNavDelegate navigationController:navigationController willShowViewController:viewController animated:animated];
    }
    
    [viewController.navigationController setNavigationBarHidden:viewController.wantsHiddenNavigationBar animated:YES];
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated;
{
    if ([self.originalNavDelegate respondsToSelector:@selector(navigationController:didShowViewController:animated:)]) {
        [self.originalNavDelegate navigationController:navigationController didShowViewController:viewController animated:animated];
    }
}

- (NSUInteger)navigationControllerSupportedInterfaceOrientations:(UINavigationController *)navigationController;
{
    if ([self.originalNavDelegate respondsToSelector:@selector(navigationControllerSupportedInterfaceOrientations:)]) {
        return [self.originalNavDelegate navigationControllerSupportedInterfaceOrientations:navigationController];
    }
    
    return UIInterfaceOrientationMaskAll;
}

- (UIInterfaceOrientation)navigationControllerPreferredInterfaceOrientationForPresentation:(UINavigationController *)navigationController;
{
    if ([self.originalNavDelegate respondsToSelector:@selector(navigationControllerPreferredInterfaceOrientationForPresentation:)]) {
        return [self.originalNavDelegate navigationControllerPreferredInterfaceOrientationForPresentation:navigationController];
    }
    
    return UIInterfaceOrientationPortrait;
}

- (id <UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
                          interactionControllerForAnimationController:(id <UIViewControllerAnimatedTransitioning>) animationController;
{
    if ([self.originalNavDelegate respondsToSelector:@selector(navigationController:interactionControllerForAnimationController:)]) {
        return [self.originalNavDelegate navigationController:navigationController interactionControllerForAnimationController:animationController];
    }
    
    return nil;
}

- (id <UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                   animationControllerForOperation:(UINavigationControllerOperation)operation
                                                fromViewController:(UIViewController *)fromVC
                                                  toViewController:(UIViewController *)toVC;
{
    if ([self.originalNavDelegate respondsToSelector:@selector(navigationController:animationControllerForOperation:fromViewController:toViewController:)]) {
        return [self.originalNavDelegate navigationController:navigationController animationControllerForOperation:operation fromViewController:fromVC toViewController:toVC];
    }
    
    return nil;
}

@end


@implementation UIViewController (OUISegmentedViewControllerExtras)
- (BOOL)wantsHiddenNavigationBar;
{
    return NO;
}

- (OUISegmentedViewController *)segmentedViewController;
{
    UIViewController *viewControllerToCheck = self;
    
    while (viewControllerToCheck) {
        if ([viewControllerToCheck isKindOfClass:[OUISegmentedViewController class]]) {
            return (OUISegmentedViewController *)viewControllerToCheck;
        }
        
        viewControllerToCheck = viewControllerToCheck.parentViewController;
    }
    
    return nil;
}

@end
