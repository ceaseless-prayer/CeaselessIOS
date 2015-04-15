//
//  Utils.m
//  Ceaseless
//
//  Created by Christopher Lim on 3/31/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "AppUtils.h"

@implementation AppUtils

+ (UIImageView *)setBlurredBackgroundForFrame: (CGRect) frame {
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

	UIImageView *imageView = [[UIImageView alloc] initWithFrame: frame];
	imageView.contentMode = UIViewContentModeScaleAspectFill;
	UIImage *backgroundImage = [AppUtils getDynamicBackgroundImage];
	if(backgroundImage != nil) {
		imageView.image = backgroundImage;
	}

		// Blur effect
	UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
	UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
	[blurEffectView setFrame: frame];
	[imageView addSubview:blurEffectView];

//	imageView.image = [imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
//	imageView.tintColor = UIColorFromRGBWithAlpha(0x00012f, 0.4);

//	UIImage *blurredImage = [UIImageEffects imageByApplyingBlurToImage:imageView.image withRadius: 10 tintColor: UIColorFromRGBWithAlpha(0x00012f, 0.6) saturationDeltaFactor:1 maskImage:imageView.image];
//	imageView.image = blurredImage;
	return imageView;
	
}
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

    // get address book authorization
    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    
    if (status == kABAuthorizationStatusDenied) {
        // if you got here, user had previously denied/revoked permission for your
        // app to access the contacts, and all you can do is handle this gracefully,
        // perhaps telling the user that they have to go to settings to grant access
        // to contacts
        [[[UIAlertView alloc] initWithTitle:nil message:@"This app requires access to your contacts to function properly. Please visit to the \"Privacy\" section in the iPhone Settings app." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
    
    CFErrorRef error = NULL;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);
    // TODO figure out when we release the address book.
    //        if (_addressBook) CFRelease(_addressBook);
    
    if (error) {
        NSLog(@"ABAddressBookCreateWithOptions error: %@", CFBridgingRelease(error));
        if (addressBook) CFRelease(addressBook);
    }
    
    if (status == kABAuthorizationStatusNotDetermined) {
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
        
        if (accessGranted) {
            // TODO this should probably be a notification
            // which then kicks off the initalization process.
            // show a housekeeping loading view and hide it when the process is done.
            // if they gave you permission, then just carry on
            // send out notification that permission is granted.
            // we can detect the notification, kick off ensureContactsAreInitializedAndRefreshed
            // and show the UI.
            return addressBook;
        } else {
            // however, if they didn't give you permission, handle it gracefully, for example...
            dispatch_async(dispatch_get_main_queue(), ^{
                // BTW, this is not on the main thread, so dispatch UI updates back to the main queue
                [[[UIAlertView alloc] initWithTitle:nil message:@"This app requires access to your contacts to function properly. Please visit to the \"Privacy\" section in the iPhone Settings app." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            });
        }
    } else if (status == kABAuthorizationStatusAuthorized) {
        NSLog(@"Address Book initialized");
        return addressBook;
    }
    
    return addressBook;
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

@end
