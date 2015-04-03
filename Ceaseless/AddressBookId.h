//
//  AddressBookId.h
//  Ceaseless
//
//  Created by Christopher Lim on 3/13/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PersonIdentifier;

@interface AddressBookId : NSManagedObject

@property (nonatomic, retain) NSString * deviceId;
@property (nonatomic, retain) NSString * recordId;
@property (nonatomic, retain) PersonIdentifier *ceaselessContact;

@end
