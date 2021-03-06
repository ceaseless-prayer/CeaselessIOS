//
//  Utils.h
//  Ceaseless
//
//  Created by Christopher Lim on 3/31/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AppConstants.h"
#import "PersonIdentifier.h"
#import "PersonInfo.h"
#import "Name.h"
#import <AddressBookUI/AddressBookUI.h>

#define UIColorFromRGBWithAlpha(rgbValue,a) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:a]

@interface AppUtils : NSObject
+ (void) showAlert;
+ (UIImage *) getDynamicBackgroundImage;
+ (NSNumber *) daysWithinEraFromDate:(NSDate *) startDate toDate:(NSDate *) endDate;
+ (ABAddressBookRef) getAddressBookRef;
+ (BOOL) requestAddressBookAccess;
+ (BOOL) addressBookAuthorized;
+ (void) bounceView: (UIView *) viewToAnimate distance: (CGFloat) toValue duration: (CGFloat) duration;
+ (void) postTrackedTiming: (NSTimeInterval) timing withCategory: (NSString*) category andName: (NSString*) name;
+ (void) postTrackedTiming: (NSTimeInterval) timing withCategory: (NSString*) category andName: (NSString*) name andLabel: (NSString*) label;
+ (void) postAnalyticsEventWithCategory: (NSString*) category andAction: (NSString*) action andLabel: (NSString*) label;
+ (void) postAnalyticsEventWithCategory: (NSString*) category andAction: (NSString*) action andLabel: (NSString*) label andValue: (NSNumber*) value;
+ (NSString*) localInstallationId;
+ (BOOL) needsOnboarding;
+ (BOOL) onboardingShownToday;
+ (NSNumber *) getNumberOfDaysAppOpened;
+ (void) incrementNumberOfDaysAppOpened;
+ (NSDate*) getDailyNotificationDate;
+ (NSString*) getDailyNotificationMessage;
+ (void)setupCardView:(UIView *)cardView withShadowView:(UIView *)shadowView;
@end
