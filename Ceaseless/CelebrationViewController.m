//
//  CelebrationViewController.m
//  Ceaseless
//
//  Created by Lori Hill on 10/22/16.
//  Copyright © 2016 Christopher Lim. All rights reserved.
//

#import "CelebrationViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "UIView+Glow.h"
#import "AppUtils.h"

@interface CelebrationViewController ()

@end

@implementation CelebrationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImage *backgroundImage = [AppUtils getDynamicBackgroundImage];
    if(backgroundImage != nil) {
        self.celebrationView.backgroundImageView.image = backgroundImage;
    }
    
    [self formatCardView: self.celebrationView.cardView withShadowView:self.celebrationView.shadowView];
    
    self.celebrationView.showMoreButton.layer.cornerRadius = 2.0f;
    self.celebrationView.showMoreButton.layer.borderWidth = 1.0f;
    self.celebrationView.showMoreButton.layer.borderColor = [UIColor whiteColor].CGColor;
    [self.celebrationView.showMoreButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 5.0, 0.0, 5.0)];

    self.celebrationView.shareProgress.layer.cornerRadius = 2.0f;
    self.celebrationView.shareProgress.layer.borderWidth = 1.0f;
    self.celebrationView.shareProgress.layer.borderColor = [UIColor whiteColor].CGColor;
    [self.celebrationView.shareProgress setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 5.0, 0.0, 5.0)];
    
    NSArray *progress = (NSArray *) self.dataObject;
    NSNumber *totalPeople = progress[1];
    self.celebrationView.peopleCount.text = [NSString stringWithFormat: @"%@", totalPeople];
    
    NSString *localInstallationId = [AppUtils localInstallationId];

    [AppUtils postAnalyticsEventWithCategory:@"celebration_view" andAction:@"post_total_active_ceaseless_contacts" andLabel:localInstallationId andValue: totalPeople];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.screenName = @"CelebrationViewScreen";
    CGPoint crownViewCenter = CGPointMake(CGRectGetMidX(self.celebrationView.crownView.bounds),
                                        CGRectGetMidY(self.celebrationView.crownView.bounds));
    [self.celebrationView.crownView glowOnceAtLocation:crownViewCenter inView:self.celebrationView.crownView];

//    [self.celebrationView startGlowingWithColor:[UIColor whiteColor] intensity:.08f];
//    [self.celebrationView.crownView startGlowing];
    self.celebrationView.loadingMore.hidden=YES;
}

- (IBAction)showMorePeople:(id)sender {
    self.celebrationView.showMoreButton.hidden = YES;
    [self.celebrationView.loadingMore startAnimating];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *numberOfPeople = [NSNumber numberWithInteger:[defaults integerForKey:kDailyPersonCount]];
    [AppUtils postAnalyticsEventWithCategory:@"celebration_view" andAction:@"button_press" andLabel:@"show_more_people" andValue: numberOfPeople];
    [[NSNotificationCenter defaultCenter] postNotificationName:kForceShowNewContent object:nil];
}

//- (IBAction)shareProgress:(id)sender {
//    NSString * message = @"Hey, I found a potential roommate on RentHoop. What do you think?";
//    NSURL *appStoreURL = [NSURL URLWithString:@"https://itunes.apple.com/us/app/renthoop-roommate-finder/id1005098846?ls=1&mt=8"];
//    UIImage * image = [self screenshotOfViewController:self];
//    
//    NSArray * shareItems = @[message, appStoreURL, image];
//    
//    UIActivityViewController * avc = [[UIActivityViewController alloc] initWithActivityItems:shareItems applicationActivities:nil];
//    
//    [self presentViewController:avc animated:YES completion:nil];
//}

- (IBAction)shareProgress:(id)sender {
//    [AppUtils postAnalyticsEventWithCategory:@"celebration_share_action" andAction:@"share_celebration" andLabel:[self.dataObject valueForKey:@"citation"]];
    UIImage * image = [self screenshotOfViewController:self];

    NSString *contentToShare = [NSString stringWithFormat:@"%@", @"I prayed for all my contacts on Ceaseless! \n\nhttp://ceaselessprayer.com"];
    
    NSArray *objectsToShare = @[contentToShare, image]; // string and url is what we need to show.
    
    UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare  applicationActivities:nil];
//    // iPads need an anchor point for the popover view.
//    // http://stackoverflow.com/questions/25644054/uiactivityviewcontroller-crashing-on-ios8-ipads
//    controller.popoverPresentationController.sourceView = self.shareProgress;
//    CGRect rect = self.shareProgress.frame;
//    controller.popoverPresentationController.sourceRect = CGRectMake(rect.size.width, rect.size.height-42, 1, 1);
//    controller.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionDown;
    
    // Present the controller
    [self presentViewController:controller animated:YES completion:nil];
    
}
- (UIImage *) screenshotOfViewController:(UIViewController*)viewController {

    CGSize size = viewController.view.bounds.size;

    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);

    CGRect rec = CGRectMake(0, 0, size.width, size.height);
    [viewController.view drawViewHierarchyInRect:rec afterScreenUpdates:YES];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;

}
@end
