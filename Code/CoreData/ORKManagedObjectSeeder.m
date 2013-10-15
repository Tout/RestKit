//
//  ORKObjectSeeder.m
//  RestKit
//
//  Created by Blake Watters on 3/4/10.
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

#if TARGET_OS_IPHONE
#import <MobileCoreServices/UTType.h>
#endif

#import "ORKManagedObjectSeeder.h"
#import "ORKManagedObjectStore.h"
#import "ORKParserRegistry.h"
#import "ORKLog.h"

// Set Logging Component
#undef ORKLogComponent
#define ORKLogComponent lcl_cRestKitCoreData

@interface ORKManagedObjectSeeder (Private)
- (id)initWithObjectManager:(ORKObjectManager *)manager;
- (void)seedObjectsFromFileNames:(NSArray *)fileNames;
@end

NSString * const ORKDefaultSeedDatabaseFileName = @"ORKSeedDatabase.sqlite";

@implementation ORKManagedObjectSeeder

@synthesize delegate = _delegate;

+ (void)generateSeedDatabaseWithObjectManager:(ORKObjectManager *)objectManager fromFiles:(NSString *)firstFileName, ...
{
    ORKManagedObjectSeeder *seeder = [ORKManagedObjectSeeder objectSeederWithObjectManager:objectManager];

    va_list args;
    va_start(args, firstFileName);
    NSMutableArray *fileNames = [NSMutableArray array];
    for (NSString *fileName = firstFileName; fileName != nil; fileName = va_arg(args, id)) {
        [fileNames addObject:fileName];
    }
    va_end(args);

    // Seed the files
    for (NSString *fileName in fileNames) {
        [seeder seedObjectsFromFile:fileName withObjectMapping:nil];
    }

    [seeder finalizeSeedingAndExit];
}

+ (ORKManagedObjectSeeder *)objectSeederWithObjectManager:(ORKObjectManager *)objectManager
{
    return [[[ORKManagedObjectSeeder alloc] initWithObjectManager:objectManager] autorelease];
}

- (id)initWithObjectManager:(ORKObjectManager *)manager
{
    self = [self init];
    if (self) {
        _manager = [manager retain];

        // If the user hasn't configured an object store, set one up for them
        if (nil == _manager.objectStore) {
            _manager.objectStore = [ORKManagedObjectStore objectStoreWithStoreFilename:ORKDefaultSeedDatabaseFileName];
        }

        // Delete any existing persistent store
        [_manager.objectStore deletePersistentStore];
    }

    return self;
}

- (void)dealloc
{
    [_manager release];
    [super dealloc];
}

- (NSString *)pathToSeedDatabase
{
    return _manager.objectStore.pathToStoreFile;
}

- (void)seedObjectsFromFiles:(NSString *)firstFileName, ...
{
    va_list args;
    va_start(args, firstFileName);
    NSMutableArray *fileNames = [NSMutableArray array];
    for (NSString *fileName = firstFileName; fileName != nil; fileName = va_arg(args, id)) {
        [fileNames addObject:fileName];
    }
    va_end(args);

    for (NSString *fileName in fileNames) {
        [self seedObjectsFromFile:fileName withObjectMapping:nil];
    }
}

- (void)seedObjectsFromFile:(NSString *)fileName withObjectMapping:(ORKObjectMapping *)nilOrObjectMapping
{
    [self seedObjectsFromFile:fileName withObjectMapping:nilOrObjectMapping bundle:nil];
}

- (void)seedObjectsFromFile:(NSString *)fileName withObjectMapping:(ORKObjectMapping *)nilOrObjectMapping bundle:(NSBundle *)nilOrBundle
{
    NSError *error = nil;

    if (nilOrBundle == nil) {
        nilOrBundle = [NSBundle mainBundle];
    }

    NSString *filePath = [nilOrBundle pathForResource:fileName ofType:nil];
    NSString *payload = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];

    if (payload) {
        NSString *MIMEType = [fileName MIMETypeForPathExtension];
        if (MIMEType == nil) {
            // Default the MIME type to the value of the Accept header if we couldn't detect it...
            MIMEType = _manager.acceptMIMEType;
        }
        id<ORKParser> parser = [[ORKParserRegistry sharedRegistry] parserForMIMEType:MIMEType];
        NSAssert1(parser, @"Could not find a parser for the MIME Type '%@'", MIMEType);
        id parsedData = [parser objectFromString:payload error:&error];
        NSAssert(parsedData, @"Cannot perform object load without data for mapping");

        ORKObjectMappingProvider *mappingProvider = nil;
        if (nilOrObjectMapping) {
            mappingProvider = [[ORKObjectMappingProvider new] autorelease];
            [mappingProvider setMapping:nilOrObjectMapping forKeyPath:@""];
        } else {
            mappingProvider = _manager.mappingProvider;
        }

        ORKObjectMapper *mapper = [ORKObjectMapper mapperWithObject:parsedData mappingProvider:mappingProvider];
        ORKObjectMappingResult *result = [mapper performMapping];
        if (result == nil) {
            ORKLogError(@"Database seeding from file '%@' failed due to object mapping errors: %@", fileName, mapper.errors);
            return;
        }

        NSArray *mappedObjects = [result asCollection];
        NSAssert1([mappedObjects isKindOfClass:[NSArray class]], @"Expected an NSArray of objects, got %@", mappedObjects);

        // Inform the delegate
        if (self.delegate) {
            for (NSManagedObject *object in mappedObjects) {
                [self.delegate didSeedObject:object fromFile:fileName];
            }
        }

        ORKLogInfo(@"Seeded %lu objects from %@...", (unsigned long)[mappedObjects count], [NSString stringWithFormat:@"%@", fileName]);
    } else {
        ORKLogError(@"Unable to read file %@: %@", fileName, [error localizedDescription]);
    }
}

- (void)finalizeSeedingAndExit
{
    NSError *error = nil;
    BOOL success = [[_manager objectStore] save:&error];
    if (! success) {
        ORKLogError(@"[RestKit] ORKManagedObjectSeeder: Error saving object context: %@", [error localizedDescription]);
    }

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSString *storeFileName = [[_manager objectStore] storeFilename];
    NSString *destinationPath = [basePath stringByAppendingPathComponent:storeFileName];
    ORKLogInfo(@"A seeded database has been generated at '%@'. "
          @"Please execute `open \"%@\"` in your Terminal and copy %@ to your app. Be sure to add the seed database to your \"Copy Resources\" build phase.",
          destinationPath, basePath, storeFileName);

    exit(1);
}

@end
