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
#import "UIImageEffects.h"

@interface RootViewController ()

@property (readonly, strong, nonatomic) ModelController *modelController;
@end

@implementation RootViewController

@synthesize modelController = _modelController;

- (void)viewDidLoad {
    [super viewDidLoad];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshPageView) name:kModelRefreshNotification object:nil];
    // TODO figure out when/where we need to call this
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:kModelRefreshNotification object:nil];
    
    // Do any additional setup after loading the view, typically from a nib.
	self.navigationItem.titleView = [[UIImageView alloc] initWithImage: [UIImage imageNamed: @"logo_main"]];

	[self setBlurredBackground];

    // Configure the page view controller and add it as a child view controller.
    NSDictionary *opts = @{
                           @"UIPageViewControllerOptionInterPageSpacingKey": @20
                           };
    
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
- (void) viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	self.navigationController.navigationBar.translucent = NO;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (ModelController *)modelController {
    // Return the model controller object, creating it if necessary.
    // In more complex implementations, the model controller may be passed to the view controller.
    if (!_modelController) {
        _modelController = [[ModelController alloc] init];
    }
    return _modelController;
}

- (void) refreshPageView {
    DataViewController *startingViewController = [self.modelController viewControllerAtIndex:0 storyboard:self.storyboard];
    [self.pageViewController setViewControllers:@[startingViewController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
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
		//| ----------------------------------------------------------------------------
		//! Applies a blur, tint color, and saturation adjustment to @a inputImage,
		//! optionally within the area specified by @a maskImage.
		//!
		//! @param  inputImage
		//!         The source image.  A modified copy of this image will be returned.
		//! @param  blurRadius
		//!         The radius of the blur in points.
		//! @param  tintColor
		//!         An optional UIColor object that is uniformly blended with the
		//!         result of the blur and saturation operations.  The alpha channel
		//!         of this color determines how strong the tint is.
		//! @param  saturationDeltaFactor
		//!         A value of 1.0 produces no change in the resulting image.  Values
		//!         less than 1.0 will desaturation the resulting image while values
		//!         greater than 1.0 will have the opposite effect.
		//! @param  maskImage
		//!         If specified, @a inputImage is only modified in the area(s) defined
		//!         by this mask.  This must be an image mask or it must meet the
		//!         requirements of the mask parameter of CGContextClipToMask.

	UIImage *blurredImage = [UIImageEffects imageByApplyingBlurToImage:self.backgroundImageView.image withRadius: 10 tintColor: UIColorFromRGBWithAlpha(0x00012f, 0.6) saturationDeltaFactor:1 maskImage:self.backgroundImageView.image];
	self.backgroundImageView.image = blurredImage;
}

- (IBAction)settingsButtonPressed:(id)sender {
	NSLog (@"settings button pressed");
}
@end
