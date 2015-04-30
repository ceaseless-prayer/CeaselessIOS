//
//  ProgressViewController.m
//  Ceaseless
//
//  Created by Christopher Lim on 4/8/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "ProgressViewController.h"
#import "AppUtils.h"
#import "AppConstants.h"
#import "WebCardViewController.h"
#import "CeaselessService.h"

@interface ProgressViewController ()
    @property (strong, nonatomic) NSArray *announcements;
@end

@implementation ProgressViewController
NSString *const kLastAnnouncementDate = @"localLastAnnouncementDate";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImage *backgroundImage = [AppUtils getDynamicBackgroundImage];
    if(backgroundImage != nil) {
        self.progressView.backgroundImageView.image = backgroundImage;
    }

    [self formatCardView: self.progressView.cardView withShadowView:self.progressView.shadowView];
    
    [self showAnnouncementButtonIfNeeded];
    NSArray *progress = (NSArray *) self.dataObject;
    NSNumber *totalPeoplePrayedForThisCycle = progress[0];
    NSNumber *totalPeople = progress[1];
    
    float progressPercentage = 0;
    if([totalPeople intValue] > 0) {
        progressPercentage = [[NSNumber numberWithDouble:[totalPeoplePrayedForThisCycle doubleValue] / [totalPeople doubleValue]]floatValue];
        self.progressView.progressLabel.text = [NSString stringWithFormat: @"%@ / %@ people", totalPeoplePrayedForThisCycle, totalPeople];
        NSString *localInstallationId = [AppUtils localInstallationId];
        [AppUtils postAnalyticsEventWithCategory:@"progress_view" andAction:@"post_people_prayed_for_this_cycle" andLabel:localInstallationId andValue: totalPeoplePrayedForThisCycle];
        [AppUtils postAnalyticsEventWithCategory:@"progress_view" andAction:@"post_total_active_ceaseless_contacts" andLabel:localInstallationId andValue: totalPeople];
    } else {
        // when totalPeople == -1, this is the initial load, show the mailing list subscribe instead.
        self.progressView.progressLabel.hidden = YES;
        self.progressView.progressCaption.hidden = YES;
        self.progressView.subscribeToMailingListButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.progressView.subscribeToMailingListButton.hidden = NO;
    }
    
    [self.progressView.progressBar setProgress: progressPercentage animated:YES];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.screenName = @"ProgressViewScreen";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)showSubscribeToMailingList:(id)sender {
    WebCardViewController *webView = [[WebCardViewController alloc]init];
    webView.dataObject = [[CeaselessService sharedCeaselessService]getUrlForKey:kSubscribeToMailingListURL];
    [self.navigationController pushViewController:webView animated:YES];
}

- (IBAction)showMorePeople:(id)sender {
    self.progressView.showMoreButton.hidden = YES;
    [self.progressView.loadingMore startAnimating];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *numberOfPeople = [NSNumber numberWithInteger:[defaults integerForKey:kDailyPersonCount]];
    [AppUtils postAnalyticsEventWithCategory:@"progress_view" andAction:@"button_press" andLabel:@"show_more_people" andValue: numberOfPeople];
    [[NSNotificationCenter defaultCenter] postNotificationName:kForceShowNewContent object:nil];
}

- (void)showAnnouncementButtonIfNeeded {
    NSURL *url = [NSURL URLWithString: [[CeaselessService sharedCeaselessService] getUrlForKey:kFetchAnnouncementsURL]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:5.0];
    
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPMethod:@"GET"];
    // TODO make this async for a better user experience?
    [NSURLConnection sendAsynchronousRequest:request queue: [NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError == nil && data != nil) {
            NSSortDescriptor *sortByDate = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
            NSError *error;
            _announcements = [[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error] sortedArrayUsingDescriptors:@[sortByDate]];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSDate *lastAnnouncementDate = [defaults objectForKey:kLastAnnouncementDate];
            
            if(!lastAnnouncementDate) {
                // this is the initial announcement in the feed.
                // we're not going to show the initial test entry in the feed.
                lastAnnouncementDate = [NSDate dateWithTimeIntervalSince1970: 1427432895];
            }
            
            if([_announcements count] > 0) {
                // get last announcement refresh date
                // compare to the date of the announcement in the array
                // TODO define the announcement format more strictly.
                NSDate *latestAnnouncementDate = [NSDate dateWithTimeIntervalSince1970:
                                                  [[_announcements[0] objectForKey:@"date"] doubleValue]];
                
                BOOL developerMode = [defaults boolForKey:kDeveloperMode];
                if(developerMode || latestAnnouncementDate > lastAnnouncementDate) {
                    NSLog(@"Latest %@ Last %@", latestAnnouncementDate, lastAnnouncementDate);
                    NSString *headline = [NSString stringWithFormat: @"Announcement: %@", _announcements[0][@"headline"]];
                    [self.progressView.announcementButton setTitle: headline forState: UIControlStateNormal];
                    self.progressView.announcementButton.hidden = NO;
                }
            }
        }
    }];
}


- (IBAction) showAnnouncement:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *latestAnnouncementDate = [NSDate dateWithTimeIntervalSince1970:
                                      [[_announcements[0] objectForKey:@"date"] doubleValue]];
    [defaults setObject:latestAnnouncementDate forKey:kLastAnnouncementDate];
    [defaults synchronize];
    NSLog(@"Latest announcement shown!");
    
    [AppUtils postAnalyticsEventWithCategory:@"progress_view" andAction:@"button_press" andLabel:@"show_announcement"];
    WebCardViewController *webCard = [[WebCardViewController alloc] init];
    webCard.dataObject = _announcements[0][@"content"];
    [self.navigationController pushViewController:webCard animated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
