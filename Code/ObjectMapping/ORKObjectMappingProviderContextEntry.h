//
//  ORKObjectMappingProviderContextEntry.h
//  RestKit
//
//  Created by Jeff Arena on 1/26/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "ORKObjectMappingDefinition.h"

@interface ORKObjectMappingProviderContextEntry : NSObject

+ (ORKObjectMappingProviderContextEntry *)contextEntryWithMapping:(ORKObjectMappingDefinition *)mapping;
+ (ORKObjectMappingProviderContextEntry *)contextEntryWithMapping:(ORKObjectMappingDefinition *)mapping userData:(id)userData;

@property (nonatomic, retain) ORKObjectMappingDefinition *mapping;
@property (nonatomic, retain) id userData;

@end
