//
//  NSString+FetchedGroupByString.m
//  Ceaseless
//
//  Created by Lori Hill on 4/8/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "NSString+FetchedGroupByString.h"

@implementation NSString (FetchedGroupByString)
- (NSString *)stringGroupByFirstInitial {
	NSString *temp = [self uppercaseString];
	if (!temp.length) {
		return @" ";
	} else if (temp.length == 1) {
		return self;
	}
	return [temp substringToIndex:1];
}
@end
