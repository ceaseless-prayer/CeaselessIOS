//
//  AddressBook.h
//  Ceaseless
//
//  Created by Lori Hill on 3/3/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBookUI/AddressBookUI.h>
#import "PersonIdentifier.h"

@interface PersonPicker : NSObject

- (NSArray *) queuedPeople;
- (void) emptyQueue;
- (void) pickPeople;
- (NSNumber *) computePrayerCycleProgress;
    
@end
