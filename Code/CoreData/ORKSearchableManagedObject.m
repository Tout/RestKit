//
//  ORKSearchableManagedObject.m
//  RestKit
//
//  Created by Jeff Arena on 3/31/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "ORKSearchableManagedObject.h"
#import "OCoreData.h"
#import "ORKLog.h"

// Set Logging Component
#undef ORKLogComponent
#define ORKLogComponent lcl_cRestKitCoreDataSearchEngine

@implementation ORKSearchableManagedObject

@dynamic searchWords;

+ (NSArray *)searchableAttributes
{
    return [NSArray array];
}

+ (NSPredicate *)predicateForSearchWithText:(NSString *)searchText searchMode:(ORKSearchMode)mode
{
    if (searchText == nil) {
        return nil;
    } else {
        ORKManagedObjectSearchEngine *searchEngine = [ORKManagedObjectSearchEngine searchEngine];
        searchEngine.mode = mode;
        return [searchEngine predicateForSearch:searchText];
    }
}

- (void)refreshSearchWords
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    ORKLogDebug(@"Refreshing search words for %@ %@", NSStringFromClass([self class]), [self objectID]);
    NSMutableSet *searchWords = [NSMutableSet set];
    for (NSString *searchableAttribute in [[self class] searchableAttributes]) {
        NSString *attributeValue = [self valueForKey:searchableAttribute];
        if (attributeValue) {
            ORKLogTrace(@"Generating search words for searchable attribute: %@", searchableAttribute);
            NSArray *attributeValueWords = [ORKManagedObjectSearchEngine tokenizedNormalizedString:attributeValue];
            for (NSString *word in attributeValueWords) {
                if (word && [word length] > 0) {
                    ORKSearchWord *searchWord = [ORKSearchWord findFirstByAttribute:ORKSearchWordPrimaryKeyAttribute
                                                                        withValue:word
                                                                        inContext:self.managedObjectContext];
                    if (! searchWord) {
                        searchWord = [ORKSearchWord createInContext:self.managedObjectContext];
                    }
                    searchWord.word = word;
                    [searchWords addObject:searchWord];
                }
            }
        }
    }

    self.searchWords = searchWords;
    ORKLogTrace(@"Generating searchWords: %@", [searchWords valueForKey:ORKSearchWordPrimaryKeyAttribute]);

    [pool drain];
}

@end
