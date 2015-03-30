//
//  Person.h
//  Ceaseless
//
//  Created by Lori Hill on 3/3/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonDigest.h>
#import "Person.h"

@interface NonMOPerson : NSObject

@property (strong, nonatomic) NSString *addressBookId;
@property (strong, nonatomic) NSString *firstName;
@property (strong, nonatomic) NSString *lastName;
@property (strong, nonatomic) NSString *phoneNumber;
@property (strong, nonatomic) UIImage *profileImage;
@property (strong, nonatomic) NSArray *emails;
@property (strong, nonatomic) NSArray *phoneNumbers;
@property (strong, nonatomic) Person *person;

- (void) favorite;
- (void) unfavorite;
- (void) removeFromCeaseless;
- (void) enableForCeaseless;



@end
