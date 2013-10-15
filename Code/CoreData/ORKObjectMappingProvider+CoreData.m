//
//  ORKObjectMappingProvider+CoreData.m
//  RestKit
//
//  Created by Jeff Arena on 1/26/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "ORKObjectMappingProvider+CoreData.h"
#import "ORKOrderedDictionary.h"
#import "ORKFixCategoryBug.h"

ORK_FIX_CATEGORY_BUG(ORKObjectMappingProvider_CoreData)
@implementation ORKObjectMappingProvider (CoreData)

- (void)setObjectMapping:(ORKObjectMappingDefinition *)objectMapping forResourcePathPattern:(NSString *)resourcePath withFetchRequestBlock:(ORKObjectMappingProviderFetchRequestBlock)fetchRequestBlock
{
    [self setEntry:[ORKObjectMappingProviderContextEntry contextEntryWithMapping:objectMapping
                                                                       userData:Block_copy(fetchRequestBlock)] forResourcePathPattern:resourcePath];
}

- (NSFetchRequest *)fetchRequestForResourcePath:(NSString *)resourcePath
{
    ORKObjectMappingProviderContextEntry *entry = [self entryForResourcePath:resourcePath];
    if (entry.userData) {
        NSFetchRequest *(^fetchRequestBlock)(NSString *) = entry.userData;
        return fetchRequestBlock(resourcePath);
    }

    return nil;
}

@end
