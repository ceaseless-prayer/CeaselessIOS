//
//  Person.m
//  Ceaseless
//
//  Created by Lori Hill on 3/3/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "NonMOPerson.h"

@implementation NonMOPerson

- (Boolean) equivalentTo: (NonMOPerson *) person {
    Boolean namesMatch = person.firstName == self.firstName && person.lastName == self.lastName;
    Boolean phoneNumberMatch = NO;
    Boolean emailMatch = NO;
    
    for (id number in person.phoneNumbers) {
        // not sure if this will work--are NSStrings symbols in objective c?
        if([self.phoneNumbers containsObject:number]) {
            phoneNumberMatch = YES;
            break;
        }
    }
    
    for (id email in person.emails) {
        if([self.emails containsObject: email]) {
            emailMatch = YES;
            break;
        }
    }
    
    return namesMatch && (phoneNumberMatch || emailMatch);
};

- (BOOL)isEqualToPerson:(NonMOPerson *)person {
    if (!person) {
        return NO;
    }
    
    BOOL haveEqualFirstNames = (!self.firstName && !person.firstName) || [self.firstName isEqualToString:person.firstName];
    BOOL haveEqualLastNames = (!self.lastName && !person.lastName) || [self.lastName isEqualToString: self.lastName];
    BOOL phoneNumberMatch = NO;
    BOOL emailMatch = NO;
    
    if([person.phoneNumbers count] > 0 && [self.phoneNumbers count] > 0) {
        for (id number in person.phoneNumbers) {
            // will containsObject compare string contents in the array or will it only compare pointers (or are these strings interned)?
            if([self.phoneNumbers containsObject:number]) {
                phoneNumberMatch = YES;
                break;
            }
        }
    }
    
    if([person.emails count] > 0 && [self.emails count] > 0) {
        for (id email in person.emails) {
            // will containsObject compare string contents in the array or will it only compare pointers (or are these strings interned)?
            if([self.emails containsObject: email]) {
                emailMatch = YES;
                break;
            }
        }
    }
    
    return haveEqualFirstNames && haveEqualLastNames && (phoneNumberMatch || emailMatch);
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[NonMOPerson class]]) {
        return NO;
    }
    
    return [self isEqualToPerson:(NonMOPerson *)object];
}

- (NSUInteger) hash {
    return [self.firstName hash] ^ [self.lastName hash] ^ [self.phoneNumbers count] ^ [self.emails count];
}

@end
