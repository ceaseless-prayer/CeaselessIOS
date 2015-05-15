//
//  RootViewController.m
//  Ceaseless
//
//  Created by Christopher Lim on 3/2/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "RootViewController.h"
#import "ModelController.h"
#import "DataViewController.h"
//#import "UIImageEffects.h"
#import "AppUtils.h"
#import "UIFont+FontAwesome.h"
#import "NSString+FontAwesome.h"
#import "MenuViewController.h"

@interface RootViewController ()

@property (readonly, strong, nonatomic) ModelController *modelController;
@end

@implementation RootViewController

@synthesize modelController = _modelController;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.screenName = @"MainScreen";
    // Do any additional setup after loading the view, typically from a nib.
	UIImage *ceaselessImage = [UIImage imageNamed: @"logo_main"];
	ceaselessImage = [ceaselessImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	self.navigationItem.titleView = [[UIImageView alloc] initWithImage: ceaselessImage];

	// Configure the page view controller and add it as a child view controller.
    NSDictionary *opts = @{
                           @"UIPageViewControllerOptionInterPageSpacingKey": @20
                           };
    
    [self.prayerJournalButton setTitle:[NSString fontAwesomeIconStringForEnum:FABook]];
    [self.prayerJournalButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                      [UIFont fontWithName:@"FontAwesome" size:26.0], NSFontAttributeName,
                                                      [UIColor whiteColor], NSForegroundColorAttributeName,
                                                      nil]
                                            forState:UIControlStateNormal];
    
    [self.menuButton setTitle:[NSString fontAwesomeIconStringForEnum:FABars]];
    [self.menuButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                      [UIFont fontWithName:@"FontAwesome" size:26.0], NSFontAttributeName,
                                                      [UIColor whiteColor], NSForegroundColorAttributeName,
                                                      nil]
                                            forState:UIControlStateNormal];

    
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:opts];
    self.pageViewController.delegate = self;

    DataViewController *startingViewController = [self.modelController viewControllerAtIndex:0 storyboard:self.storyboard];
    if(startingViewController == nil) {
        startingViewController = [[DataViewController alloc]init];
    }
    NSArray *viewControllers = @[startingViewController];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];

    self.pageViewController.dataSource = self.modelController;

    [self addChildViewController:self.pageViewController];
    [self.view addSubview:self.pageViewController.view];


    [self.pageViewController didMoveToParentViewController:self];

    // Add the page view controller's gesture recognizers to the book view controller's view so that the gestures are started more easily.
    self.view.gestureRecognizers = self.pageViewController.gestureRecognizers;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (ModelController *)modelController {
    // Return the model controller object, creating it if necessary.
    // In more complex implementations, the model controller may be passed to the view controller.
    if (!_modelController) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            // listen for when the model changes
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshPageView) name:kModelRefreshNotification object:nil];
            
            //prepare the model
            _modelController = [[ModelController alloc] init];
            
            // make the model try to refresh whenever the app becomse active
            [[NSNotificationCenter defaultCenter] addObserver:_modelController selector:@selector(runIfNewDay) name:UIApplicationDidBecomeActiveNotification object:nil];
            
            // make the model show new content when forced by the user
            [[NSNotificationCenter defaultCenter] addObserver:_modelController selector:@selector(showNewContent) name:kForceShowNewContent object:nil];
            
            // show the loading view when the app enters the foreground
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showLoading) name:UIApplicationWillEnterForegroundNotification object:nil];

				// turn off the loading view when the page does not need to be refreshed
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideLoading) name: kHideLoadingNotification object:nil];

        });
        // TODO figure out when/where we need to call this
        //[[NSNotificationCenter defaultCenter] removeObserver:self name:kModelRefreshNotification object:nil];
		//[[NSNotificationCenter defaultCenter] removeObserver:self name:kHideLoadingNotification object:nil];

    }
    return _modelController;
}

- (void) showLoading {
    self.view.userInteractionEnabled = NO;
    if (self.loadingLabel.hidden) {
        [self.loadingIndicator startAnimating];
        self.loadingLabel.hidden = NO;
        self.pageViewController.view.hidden = YES;
    }
}

- (void) hideLoading {
    self.view.userInteractionEnabled = YES;
    if (!self.loadingLabel.hidden) {
        [self.loadingIndicator stopAnimating];
        self.loadingLabel.hidden = YES;
        self.pageViewController.view.hidden = NO;
    }
}

- (void) refreshPageView {
    NSLog(@"Refreshing page view");
    [self setBlurredBackground];
    DataViewController *startingViewController = [self.modelController viewControllerAtIndex:0 storyboard:self.storyboard];
    [self.pageViewController setViewControllers:@[startingViewController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    [self hideLoading];
}

#pragma mark - UIPageViewController delegate methods

- (UIPageViewControllerSpineLocation)pageViewController:(UIPageViewController *)pageViewController spineLocationForInterfaceOrientation:(UIInterfaceOrientation)orientation {
    if (UIInterfaceOrientationIsPortrait(orientation) || ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)) {
        // In portrait orientation or on iPhone: Set the spine position to "min" and the page view controller's view controllers array to contain just one view controller. Setting the spine position to 'UIPageViewControllerSpineLocationMid' in landscape orientation sets the doubleSided property to YES, so set it to NO here.
        
        UIViewController *currentViewController = self.pageViewController.viewControllers[0];
        NSArray *viewControllers = @[currentViewController];
        [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
        
        self.pageViewController.doubleSided = NO;
        return UIPageViewControllerSpineLocationMin;
    }

    // In landscape orientation: Set set the spine location to "mid" and the page view controller's view controllers array to contain two view controllers. If the current page is even, set it to contain the current and next view controllers; if it is odd, set the array to contain the previous and current view controllers.
    DataViewController *currentViewController = self.pageViewController.viewControllers[0];
    NSArray *viewControllers = nil;

    NSUInteger indexOfCurrentViewController = [self.modelController indexOfViewController:currentViewController];
    if (indexOfCurrentViewController == 0 || indexOfCurrentViewController % 2 == 0) {
        UIViewController *nextViewController = [self.modelController pageViewController:self.pageViewController viewControllerAfterViewController:currentViewController];
        viewControllers = @[currentViewController, nextViewController];
    } else {
        UIViewController *previousViewController = [self.modelController pageViewController:self.pageViewController viewControllerBeforeViewController:currentViewController];
        viewControllers = @[previousViewController, currentViewController];
    }
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];


    return UIPageViewControllerSpineLocationMid;
}

- (void)setBlurredBackground {

    UIImage *backgroundImage = [AppUtils getDynamicBackgroundImage];
    if(backgroundImage != nil) {
        self.backgroundImageView.image = backgroundImage;
    }

}
- (IBAction)unwindToRootViewController:(UIStoryboardSegue*)sender
{
		// Pull any data from the view controller which initiated the unwind segue.

}
- (IBAction)menuButtonPressed:(id)sender {

	CATransition* transition = [CATransition animation];
	transition.duration = 0.3f;
	transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
	transition.type = kCATransitionMoveIn; //kCATransitionMoveIn; //, kCATransitionPush, kCATransitionReveal, kCATransitionFade
	transition.subtype = kCATransitionFromTop; //kCATransitionFromLeft, kCATransitionFromRight, kCATransitionFromTop, kCATransitionFromBottom

	MenuViewController *menuViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"MenuViewController"];
	menuViewController.delegate = self;
	[self.navigationController.view.layer addAnimation:transition forKey:kCATransition];
	[self.navigationController pushViewController:menuViewController animated:NO];
}

#pragma mark - MenuViewControllerDelegate protocol conformance

- (void)menuViewControllerDidFinish:(MenuViewController *)menuViewController
{
	[self performDismissAnimationForController:menuViewController];

}

- (void) performDismissAnimationForController: (MenuViewController *)menuViewController {
	CATransition* transition = [CATransition animation];
	transition.duration = 0.3f;
	transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
	transition.type = kCATransitionReveal; //kCATransitionMoveIn; //, kCATransitionPush, kCATransitionReveal, kCATransitionFade
	transition.subtype = kCATransitionFromBottom; //kCATransitionFromLeft, kCATransitionFromRight, kCATransitionFromTop, kCATransitionFromBottom

	[self.navigationController.view.layer addAnimation:transition forKey:kCATransition];
	[self.navigationController popViewControllerAnimated:NO];
	
}
@end
