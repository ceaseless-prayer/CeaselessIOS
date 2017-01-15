//
//  Utils.m
//  Ceaseless
//
//  Created by Christopher Lim on 3/31/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "AppUtils.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "CeaselessLocalContacts.h"
#import "RootViewController.h"

@implementation AppUtils

+ (UIImage *) getDynamicBackgroundImage {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentDirectory = [paths objectAtIndex:0];
	NSString *imagePath = [documentDirectory stringByAppendingPathComponent:kDynamicBackgroundImage];
	return [UIImage imageWithContentsOfFile:imagePath];
}

// https://developer.apple.com/library/prerelease/ios//documentation/Cocoa/Conceptual/DatesAndTimes/Articles/dtCalendricalCalculations.html#//apple_ref/doc/uid/TP40007836-SW1
// Listing 13. Days between two dates, as the number of midnights between
// http://stackoverflow.com/questions/14653114/nsdate-comparison-figuring-out-number-of-midnights-between-in-specific-local
+ (NSNumber *) daysWithinEraFromDate:(NSDate *) startDate toDate:(NSDate *) endDate {
    NSCalendar *cal = [NSCalendar autoupdatingCurrentCalendar];
    NSUInteger unit = NSCalendarUnitDay;
    NSDate *startDays, *endDays;
    
    [cal rangeOfUnit:unit startDate:&startDays interval:NULL forDate:startDate];
    [cal rangeOfUnit:unit startDate:&endDays interval:NULL forDate:endDate];
    
    NSDateComponents *comp = [cal components:unit fromDate:startDays toDate:endDays options:0];
    return [NSNumber numberWithLong:[comp day]];
}

// this is a blocking way to get an address book reference
// we can alternatively use the non-blocking way
// if we are in a view that can be updated after the user has set permissions.
+ (ABAddressBookRef) getAddressBookRef {

    CFErrorRef error = NULL;
    ABAddressBookRef addressBook = NULL;
    
    // get address book authorization
    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    
    if (status == kABAuthorizationStatusDenied) {
        // if you got here, user had previously denied/revoked permission for your
        // app to access the contacts, and all you can do is handle this gracefully,
        // perhaps telling the user that they have to go to settings to grant access
        // to contacts
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [self.class showAlert];
        });
        return addressBook;
    }
    
    // TODO figure out when we release the address book.
    //        if (_addressBook) CFRelease(_addressBook);
    
    if (error) {
        NSLog(@"ABAddressBookCreateWithOptions error: %@", CFBridgingRelease(error));
        if (addressBook) CFRelease(addressBook);
    }
    
    if (status == kABAuthorizationStatusNotDetermined) {
        if (![AppUtils onboardingShownToday]) { // we only request access automatically if onboarding isn't needed.
            
            BOOL accessGranted = [AppUtils requestAddressBookAccess];
            if (accessGranted) {
                // TODO this should probably be a notification
                // which then kicks off the initalization process.
                // show a housekeeping loading view and hide it when the process is done.
                // if they gave you permission, then just carry on
                // send out notification that permission is granted.
                // we can detect the notification, kick off ensureContactsAreInitializedAndRefreshed
                // and show the UI.
                addressBook = ABAddressBookCreateWithOptions(NULL, &error);
                return addressBook;
            } else {
                // however, if they didn't give you permission, handle it gracefully, for example...
                dispatch_async(dispatch_get_main_queue(), ^{
                    // BTW, this is not on the main thread, so dispatch UI updates back to the main queue
                    [self.class showAlert];
                });
            }
        } else {
            return addressBook;
        }
    } else if (status == kABAuthorizationStatusAuthorized) {
        NSLog(@"Address Book initialized");
        addressBook = ABAddressBookCreateWithOptions(NULL, &error);
        return addressBook;
    }
    
    return addressBook;
}

+ (BOOL) addressBookAuthorized {
    // get address book authorization
    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    return status == kABAuthorizationStatusAuthorized;
}

+ (BOOL) requestAddressBookAccess {
    ABAddressBookRef addressBook = NULL;
    __block BOOL accessGranted = NO;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    // present the user the UI that requests permission to contacts ...
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
        if (error) {
            NSLog(@"ABAddressBookRequestAccessWithCompletion error: %@", CFBridgingRelease(error));
            
        }
        accessGranted = granted;
        dispatch_semaphore_signal(sema);
    });
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    return accessGranted;
}

#pragma mark - Show onboarding or not
+ (BOOL) needsOnboarding {
    NSDictionary *infoPlist = [[NSBundle mainBundle] infoDictionary];
    NSDate *onboardingVersionDate = infoPlist[@"Onboarding Version Date"];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *lastRefreshDate = [defaults objectForKey:kLocalLastRefreshDate];
    NSDate *onboardingLastOpenedDate = [defaults objectForKey:kOnboardingLastOpenedDate];
    
    if (!onboardingLastOpenedDate) {
        // if the app has already been refreshed, we don't need to show onboarding
        // since the user has already used the app.
        if (lastRefreshDate) {
            return NO;
        }
        
        return YES;
    } else {
        // if the last onboarding date is less than the new onboarding version date we need to show it.
        return [onboardingLastOpenedDate compare: onboardingVersionDate] == NSOrderedAscending;
    }
}

+ (BOOL) onboardingShownToday {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *onboardingLastOpenedDate = [defaults objectForKey:kOnboardingLastOpenedDate];
    NSDate *now = [NSDate date];
    return [[AppUtils daysWithinEraFromDate: onboardingLastOpenedDate toDate: now]intValue] <= 0;
}

#pragma mark - Alert View Controller

+ (void) showAlert {
    UIViewController *presentingViewController = [self.class topMostController];
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:nil
                                          message:NSLocalizedString(@"contactsPermissionRequired", nil)
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel action")
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
                                       NSLog(@"Cancel action");
                                   }];
    
    
    UIAlertAction *enableContacts = [UIAlertAction
                                     actionWithTitle:NSLocalizedString(@"OK", @"OK")
                                     style:UIAlertActionStyleDefault
                                     handler:^(UIAlertAction *action)
                                     {
                                         ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
                                         if (status == kABAuthorizationStatusNotDetermined) {
                                             BOOL accessGranted = [AppUtils requestAddressBookAccess];
                                             if (accessGranted) {
                                                 CeaselessLocalContacts *clc = [CeaselessLocalContacts sharedCeaselessLocalContacts];
                                                 [clc ensureCeaselessContactsSynced];
                                             }
                                         } else {
                                            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                                             
                                         }
                                         NSLog(@"Allow action");
                                     }];
    
    [alertController addAction:enableContacts];
    [alertController addAction:cancelAction];
    
    // this prevents crash on iPad in iOS 8 - known Apple bug
    UIPopoverPresentationController *popover = alertController.popoverPresentationController;
    if (popover)
    {
        popover.sourceRect = presentingViewController.view.bounds;
        popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
    }
    
    [presentingViewController presentViewController:alertController animated:YES completion:nil];
}

+ (UIViewController*) topMostController
{
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

#pragma mark - Animation
+ (void) bounceView: (UIView *) viewToAnimate distance: (CGFloat) toValue duration: (CGFloat) duration{
    CABasicAnimation *hover = [CABasicAnimation animationWithKeyPath:@"position"];
    hover.additive = YES; // fromValue and toValue will be relative instead of absolute values
    hover.fromValue = [NSValue valueWithCGPoint:CGPointZero];
    hover.toValue = [NSValue valueWithCGPoint:CGPointMake(0.0, toValue)]; // y increases downwards on iOS
    hover.autoreverses = YES; // Animate back to normal afterwards
    hover.duration = duration; // The duration for one part of the animation (0.2 up and 0.2 down)
    hover.repeatCount = INFINITY; // The number of times the animation should repeat
    [viewToAnimate.layer addAnimation:hover forKey:@"myHoverAnimation"];
}

+ (void) postTrackedTiming: (NSTimeInterval) timing withCategory: (NSString*) category andName: (NSString*) name {
    [AppUtils postTrackedTiming:timing withCategory:category andName:name andLabel:nil];
}

+ (void) postTrackedTiming: (NSTimeInterval) timing withCategory: (NSString*) category andName: (NSString*) name andLabel: (NSString*) label {
    id tracker = [[GAI sharedInstance] defaultTracker];
    if(tracker) {
        [tracker send:[[GAIDictionaryBuilder createTimingWithCategory:category                      // Timing category (required)
                                                         interval:@((NSUInteger)(timing * 1000))   // Timing interval (required)
                                                            name:name                     // Timing name
                                                            label:label] build]];                      // Timing label
    }
}

+ (void) postAnalyticsEventWithCategory: (NSString*) category andAction: (NSString*) action andLabel: (NSString*) label {
    [AppUtils postAnalyticsEventWithCategory:category andAction:action andLabel:label andValue:nil];
}

+ (void) postAnalyticsEventWithCategory: (NSString*) category andAction: (NSString*) action andLabel: (NSString*) label andValue: (NSNumber*) value {
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    if(tracker) {
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:category     // Event category (required)
                                                          action:action  // Event action (required)
                                                           label:label          // Event label
                                                           value:value] build]];    // Event value
    }
}

+ (NSString*) localInstallationId {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:kLocalInstallationId]) {
        NSUUID  *UUID = [NSUUID UUID];
        NSString *localInstallationId = [UUID UUIDString];
        NSDate *localInstallationDate = [NSDate date];
        [defaults setObject:localInstallationId forKey:kLocalInstallationId];
        [defaults setObject:localInstallationDate forKey: kLocalInstallationDate];
        [defaults synchronize];
        return localInstallationId;
    } else {
        return [defaults objectForKey:kLocalInstallationId];
    }
}

+ (NSDate*) getDailyNotificationDate {
    NSDate *notificationDate;
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:kNotificationDate]) {
        NSDate *now = [NSDate date];
        NSDateComponents *dateComponent = [gregorian components:NSCalendarUnitYear | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitWeekday | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour fromDate: now];
        
        dateComponent.hour = 8; // the default notification time is 8am.
        dateComponent.minute = 0;
        dateComponent.second = 0;
        notificationDate = [[NSCalendar currentCalendar] dateFromComponents:dateComponent];
        [defaults setObject:notificationDate forKey:kNotificationDate];
        [defaults synchronize];
    } else {
        notificationDate = [defaults objectForKey:kNotificationDate];
    }
    return notificationDate;
}

+ (NSNumber *) getNumberOfDaysAppOpened {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *daysAppOpened = [defaults objectForKey: kDaysAppOpened];
    if (!daysAppOpened) {
        return [NSNumber numberWithLongLong: 1];
    } else {
        return daysAppOpened;
    }
}

+ (void) incrementNumberOfDaysAppOpened {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *daysAppOpened = [defaults objectForKey: kDaysAppOpened];
    if (!daysAppOpened) {
        // default number of days is 1
        daysAppOpened = [NSNumber numberWithLongLong: 1];
    } else {
        daysAppOpened =  @([daysAppOpened longLongValue] + 1);
    }
    
    [defaults setObject: daysAppOpened forKey: kDaysAppOpened];
    [defaults synchronize];
}

+ (NSString*) getDailyNotificationMessage {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:kPersonNameForNextDay] != nil) {
        NSString *personName = [defaults objectForKey:kPersonNameForNextDay];
        NSInteger othersCount = [defaults integerForKey:kDailyPersonCount] - 1;
        if (othersCount > 1) {
            return [NSString stringWithFormat:NSLocalizedString(@"Tap to pray for %@ and %@ others.", @"notification message"), personName, [NSNumber numberWithInteger:othersCount]];
        } else {
            return [NSString stringWithFormat:NSLocalizedString(@"Tap to pray for %@ and others.", @"notification message"), personName];
        }
    } else {
        return NSLocalizedString(@"Remember to pray for others today.", @"notification message");
    }
}

+ (void)setupCardView:(UIView *)cardView withShadowView:(UIView *)shadowView {
    cardView.layer.cornerRadius = 24.0;
    cardView.clipsToBounds = YES;

    shadowView.layer.shadowColor = [UIColor blackColor].CGColor;
    shadowView.layer.shadowOffset = CGSizeMake(1, 1);
    shadowView.layer.shadowRadius = 4.0;
    shadowView.layer.cornerRadius = 24.0;
    shadowView.layer.shadowOpacity = 0.8;
}

@end
