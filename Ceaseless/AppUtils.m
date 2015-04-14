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
+ (NSInteger) daysWithinEraFromDate:(NSDate *) startDate toDate:(NSDate *) endDate {
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSInteger startDay = [gregorian ordinalityOfUnit:NSCalendarUnitDay
                                              inUnit: NSCalendarUnitEra forDate:startDate];
    NSInteger endDay = [gregorian ordinalityOfUnit:NSCalendarUnitDay
                                            inUnit: NSCalendarUnitEra forDate:endDate];
    return endDay-startDay;
}
@end
