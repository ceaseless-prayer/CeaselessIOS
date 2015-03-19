//
//  Person.m
//  Ceaseless
//
//  Created by Lori Hill on 3/3/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "NonMOPerson.h"

@implementation NonMOPerson

- (void) favorite {
    self.person.favoritedDate = [NSDate date];
    [self save];
}
- (void) unfavorite {
    self.person.favoritedDate = nil;
    [self save];
}
- (void) removeFromCeaseless {
    self.person.removedDate = [NSDate date];
    [self save];
}
- (void) enableForCeaseless {
    self.person.removedDate = nil;
    [self save];
}

- (void) save {
    // save
    NSError *error;
    if (![self.person.managedObjectContext save:&error]) {
        NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
    }
}

@end
