//
//  ORKTestAddress.m
//  RestKit
//
//  Created by Blake Watters on 8/5/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "ORKTestAddress.h"

@implementation ORKTestAddress

@synthesize addressID = _addressID;
@synthesize city = _city;
@synthesize state = _state;
@synthesize country = _country;

+ (ORKTestAddress *)address
{
    return [[self new] autorelease];
}

// isEqual: is consulted by the mapping operation
// to determine if assocation values should be set
- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[ORKTestAddress class]]) {
        return [[(ORKTestAddress *)object addressID] isEqualToNumber:self.addressID];
    } else {
        return NO;
    }
}

@end
