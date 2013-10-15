//
//  ORKInMemoryManagedObjectCache.h
//  RestKit
//
//  Created by Jeff Arena on 1/24/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "ORKManagedObjectCaching.h"

/**
 Provides a fast managed object cache where-in object instances are retained in
 memory to avoid hitting the Core Data persistent store. Performance is greatly
 increased over fetch request based strategy at the expense of memory consumption.
 */
@interface ORKInMemoryManagedObjectCache : NSObject <ORKManagedObjectCaching>

@end
