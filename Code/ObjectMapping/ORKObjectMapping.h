//
//  ORKObjectMapping.h
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
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

#import <Foundation/Foundation.h>
#import "ORKObjectMappingDefinition.h"
#import "ORKObjectAttributeMapping.h"
#import "ORKObjectRelationshipMapping.h"

/**
 An object mapping defines the rules for transforming a key-value coding
 compliant object into another representation. The mapping is defined in terms
 of a source object class and a collection of rules defining how keyPaths should
 be transformed into target attributes and relationships.

 There are two types of transformations possible:

 1. keyPath to attribute. Defines that the value found at the keyPath should be
transformed and assigned to the property specified by the attribute. The transformation
to be performed is determined by inspecting the type of the target property at runtime.
 1. keyPath to relationship. Defines that the value found at the keyPath should be
transformed into another object instance and assigned to the property specified by the
relationship. Relationships are processed using an object mapping as well.

 Through the use of relationship mappings, an arbitrarily complex object graph can be mapped for you.

 Instances of ORKObjectMapping are used to configure ORKObjectMappingOperation instances, which actually
 perform the mapping work. Both object loading and serialization are defined in terms of object mappings.
 */
@interface ORKObjectMapping : ORKObjectMappingDefinition <NSCopying> {
    Class _objectClass;
    NSMutableArray *_mappings;
}

/**
 The target class this object mapping is defining rules for
 */
@property (nonatomic, assign) Class objectClass;

/**
 The name of the target class the receiver defines a mapping for.

 @see objectClass
 */
@property (nonatomic, copy) NSString *objectClassName;

/**
 The aggregate collection of attribute and relationship mappings within this object mapping
 */
@property (nonatomic, readonly) NSArray *mappings;

/**
 The collection of attribute mappings within this object mapping
 */
@property (nonatomic, readonly) NSArray *attributeMappings;

/**
 The collection of relationship mappings within this object mapping
 */
@property (nonatomic, readonly) NSArray *relationshipMappings;

/**
 The collection of mappable keyPaths that are defined within this object mapping. These
 keyPaths refer to keys within the source object being mapped (i.e. the parsed JSON payload).
 */
@property (nonatomic, readonly) NSArray *mappedKeyPaths;

/**
 When YES, any attributes that have mappings defined but are not present within the source
 object will be set to nil, clearing any existing value.
 */
@property (nonatomic, assign, getter = shouldSetDefaultValueForMissingAttributes) BOOL setDefaultValueForMissingAttributes;

/**
 When YES, any relationships that have mappings defined but are not present within the source
 object will be set to nil, clearing any existing value.
 */
@property (nonatomic, assign) BOOL setNilForMissingRelationships;

/**
 When YES, RestKit will invoke key-value validation at object mapping time.

 **Default**: YES
 @see validateValue:forKey:error:
 */
@property (nonatomic, assign) BOOL performKeyValueValidation;

/**
 When YES, RestKit will check that the object being mapped is key-value coding
 compliant for the mapped key. If it is not, the attribute/relationship mapping will
 be ignored and mapping will continue. When NO, unknown keyPath mappings will generate
 NSUnknownKeyException errors for the unknown keyPath.

 Defaults to NO to help the developer catch incorrect mapping configurations during
 development.

 **Default**: NO
 */
@property (nonatomic, assign) BOOL ignoreUnknownKeyPaths;

/**
 An array of NSDateFormatter objects to use when mapping string values
 into NSDate attributes on the target objectClass. Each date formatter
 will be invoked with the string value being mapped until one of the date
 formatters does not return nil.

 Defaults to the application-wide collection of date formatters configured via:
 [ORKObjectMapping setDefaultDateFormatters:]

 @see [ORKObjectMapping defaultDateFormatters]
 */
@property (nonatomic, retain) NSArray *dateFormatters;

/**
 The NSFormatter object for your application's preferred date
 and time configuration. This date formatter will be used when generating
 string representations of NSDate attributes (i.e. during serialization to
 URL form encoded or JSON format).

 Defaults to the application-wide preferred date formatter configured via:
 [ORKObjectMapping setPreferredDateFormatter:]

 @see [ORKObjectMapping preferredDateFormatter]
 */
@property (nonatomic, retain) NSFormatter *preferredDateFormatter;

#pragma mark - Mapping Instantiation

/**
 Returns an object mapping for the specified class that is ready for configuration
 */
+ (id)mappingForClass:(Class)objectClass;

/**
 Creates and returns an object mapping for the class with the given name

 @param objectClassName The name of the class the mapping is for.
 @return A new object mapping with for the class with given name.
 */
+ (id)mappingForClassWithName:(NSString *)objectClassName;

/**
 Returns an object mapping useful for configuring a serialization mapping. The object
 class is configured as NSMutableDictionary
 */
+ (id)serializationMapping;

#if NS_BLOCKS_AVAILABLE
/**
 Returns an object mapping targeting the specified class. The ORKObjectMapping instance will
 be yieled to the block so that you can perform on the fly configuration without having to
 obtain a reference variable for the mapping.

 For example, consider we have a one-off request that will load a few attributes for our object.
 Using blocks, this is very succinct:

    [[ORKObjectManager sharedManager] postObject:self usingBlock:^(ORKObjectLoader *loader) {
        loader.objectMapping = [ORKObjectMapping mappingForClass:[Person class] usingBlock:^(ORKObjectMapping *mapping) {
            [mapping mapAttributes:@"email", @"first_name", nil];
        }];
    }];
 */
+ (id)mappingForClass:(Class)objectClass usingBlock:(void (^)(ORKObjectMapping *mapping))block;

/**
 Returns serialization mapping for encoding a local object to a dictionary for transport. The ORKObjectMapping instance will
 be yieled to the block so that you can perform on the fly configuration without having to
 obtain a reference variable for the mapping.

 For example, consider we have a one-off request within which we want to post a subset of our object
 data. Using blocks, this is very succinct:

    - (BOOL)changePassword:(NSString *)newPassword error:(NSError **)error {
        if ([self validatePassword:newPassword error:error]) {
            self.password = newPassword;
            [[ORKObjectManager sharedManager] putObject:self delegate:self block:^(ORKObjectLoader *loader) {
                loader.serializationMapping = [ORKObjectMapping serializationMappingUsingBlock:^(ORKObjectMapping *mapping) {
                    [mapping mapAttributes:@"password", nil];
                }];
            }];
        }
    }

 Using the block forms we are able to quickly configure and send this request on the fly.
 */
+ (id)serializationMappingUsingBlock:(void (^)(ORKObjectMapping *serializationMapping))block;
#endif

/**
 Add a configured attribute mapping to this object mapping

 @see ORKObjectAttributeMapping
 */
- (void)addAttributeMapping:(ORKObjectAttributeMapping *)mapping;

/**
 Add a configured attribute mapping to this object mapping

 @see ORKObjectRelationshipMapping
 */
- (void)addRelationshipMapping:(ORKObjectRelationshipMapping *)mapping;

#pragma mark - Retrieving Mappings

/**
 Returns the attribute or relationship mapping for the given source keyPath.

 @param sourceKeyPath A keyPath within the mappable source object that is mapped to an
 attribute or relationship in this object mapping.
 */
- (id)mappingForKeyPath:(NSString *)sourceKeyPath;

/**
 Returns the attribute or relationship mapping for the given source keyPath.

 @param sourceKeyPath A keyPath within the mappable source object that is mapped to an
 attribute or relationship in this object mapping.
 */
- (id)mappingForSourceKeyPath:(NSString *)sourceKeyPath;

/**
 Returns the attribute or relationship mapping for the given destination keyPath.

 @param destinationKeyPath A keyPath on the destination object that is currently
 */
- (id)mappingForDestinationKeyPath:(NSString *)destinationKeyPath;

/**
 Returns the attribute mapping targeting the specified attribute on the destination object

 @param attributeKey The name of the attribute we want to retrieve the mapping for
 */
- (ORKObjectAttributeMapping *)mappingForAttribute:(NSString *)attributeKey;

/**
 Returns the relationship mapping targeting the specified relationship on the destination object

 @param relationshipKey The name of the relationship we want to retrieve the mapping for
 */
- (ORKObjectRelationshipMapping *)mappingForRelationship:(NSString *)relationshipKey;

#pragma mark - Attribute & Relationship Mapping

/**
 Define an attribute mapping for one or more keyPaths where the source keyPath and destination attribute property
 have the same name.

 For example, given the transformation from a JSON dictionary:

    {"name": "My Name", "age": 28}

 To a Person class with corresponding name &amp; age properties, we could configure the attribute mappings via:

    [mapping mapAttributes:@"name", @"age", nil];

 @param attributeKey A key-value coding key corresponding to a value in the mappable source object and an attribute
 on the destination class that have the same name.
 */
- (void)mapAttributes:(NSString *)attributeKey, ... NS_REQUIRES_NIL_TERMINATION;

/**
 Defines an attribute mapping for each string attribute in the collection where the source keyPath and the
 destination attribute property have the same name.

 For example, given the transformation from a JSON dictionary:

    {"name": "My Name", "age": 28}

 To a Person class with corresponding name &amp; age properties, we could configure the attribute mappings via:

    [mapping mapAttributesFromSet:[NSSet setWithObjects:@"name", @"age", nil]];

 @param set A set of string attribute keyPaths to deifne mappings for
 */
- (void)mapAttributesFromSet:(NSSet *)set;

/**
 Defines an attribute mapping for each string attribute in the collection where the source keyPath and the
 destination attribute property have the same name.

 For example, given the transformation from a JSON dictionary:

    {"name": "My Name", "age": 28}

 To a Person class with corresponding name &amp; age properties, we could configure the attribute mappings via:

    [mapping mapAttributesFromSet:[NSArray arrayWithObjects:@"name", @"age", nil]];

 @param array An array of string attribute keyPaths to deifne mappings for
 */
- (void)mapAttributesFromArray:(NSArray *)set;

/**
 Defines a relationship mapping for a key where the source keyPath and the destination relationship property
 have the same name.

 For example, given the transformation from a JSON dictionary:

 {"name": "My Name", "age": 28, "cat": { "name": "Asia" } }

 To a Person class with corresponding 'cat' relationship property, we could configure the mappings via:

     ORKObjectMapping *catMapping = [ORKObjectMapping mappingForClass:[Cat class]];
     [personMapping mapRelationship:@"cat" withObjectMapping:catMapping];

 @param relationshipKey A key-value coding key corresponding to a value in the mappable source object and a property
    on the destination class that have the same name.
 @param objectOrDynamicMapping An ORKObjectMapping or ORKObjectDynamic mapping to apply when mapping the relationship
 */
- (void)mapRelationship:(NSString *)relationshipKey withMapping:(ORKObjectMappingDefinition *)objectOrDynamicMapping;

/**
 Syntactic sugar to improve readability when defining a relationship mapping. Implies that the mapping
 targets a one-to-many relationship nested within the source data.

 @see mapRelationship:withObjectMapping:
 */
- (void)hasMany:(NSString *)keyPath withMapping:(ORKObjectMappingDefinition *)objectOrDynamicMapping;

/**
 Syntactic sugar to improve readability when defining a relationship mapping. Implies that the mapping
 targets a one-to-one relationship nested within the source data.

 @see mapRelationship:withObjectMapping:
 */
- (void)hasOne:(NSString *)keyPath withMapping:(ORKObjectMappingDefinition *)objectOrDynamicMapping;

/**
 Instantiate and add an ORKObjectAttributeMapping instance targeting a keyPath within the mappable
 source data to an attribute on the target object.

 Used to quickly define mappings where the source value is deeply nested in the mappable data or
 the source and destination do not have corresponding names.

 Examples:
    // We want to transform the name to something Cocoa-esque
    [mapping mapKeyPath:@"created_at" toAttribute:@"createdAt"];

    // We want to extract nested data and map it to a property
    [mapping mapKeyPath:@"results.metadata.generated_on" toAttribute:@"generationTimestamp"];

 @param sourceKeyPath A key-value coding keyPath to fetch the mappable value from
 @param destinationAttribute The attribute name to assign the mapped value to
 @see ORKObjectAttributeMapping
 */
- (void)mapKeyPath:(NSString *)sourceKeyPath toAttribute:(NSString *)destinationAttribute;

/**
 Instantiate and add an ORKObjectRelationshipMapping instance targeting a keyPath within the mappable
 source data to a relationship property on the target object.

 Used to quickly define mappings where the source value is deeply nested in the mappable data or
 the source and destination do not have corresponding names.

 Examples:
     // We want to transform the name to something Cocoa-esque
     [mapping mapKeyPath:@"best_friend" toRelationship:@"bestFriend" withObjectMapping:friendMapping];

     // We want to extract nested data and map it to a property
     [mapping mapKeyPath:@"best_friend.favorite_cat" toRelationship:@"bestFriendsFavoriteCat" withObjectMapping:catMapping];

 @param sourceKeyPath A key-value coding keyPath to fetch the mappable value from
 @param destinationRelationship The relationship name to assign the mapped value to
 @param objectMapping An object mapping to use when processing the nested objects
 @see ORKObjectRelationshipMapping
 */
- (void)mapKeyPath:(NSString *)sourceKeyPath toRelationship:(NSString *)destinationRelationship withMapping:(ORKObjectMappingDefinition *)objectOrDynamicMapping;

/**
 Instantiate and add an ORKObjectRelationshipMapping instance targeting a keyPath within the mappable
 source data to a relationship property on the target object.

 Used to indicate whether the relationship should be included in serialization.

 @param sourceKeyPath A key-value coding keyPath to fetch the mappable value from
 @param destinationRelationship The relationship name to assign the mapped value to
 @param objectMapping An object mapping to use when processing the nested objects
 @param serialize A boolean value indicating whether to include this relationship in serialization

 @see mapKeyPath:toRelationship:withObjectMapping:
 */
- (void)mapKeyPath:(NSString *)relationshipKeyPath toRelationship:(NSString *)keyPath withMapping:(ORKObjectMappingDefinition *)objectOrDynamicMapping serialize:(BOOL)serialize;

/**
 Quickly define a group of attribute mappings using alternating keyPath and attribute names. You must provide
 an equal number of keyPath and attribute pairs or an exception will be generated.

 For example:
    [personMapping mapKeyPathsToAttributes:@"name", @"name", @"createdAt", @"createdAt", @"street_address", @"streetAddress", nil];

 @param sourceKeyPath A key-value coding key path to fetch a mappable value from
 @param ... A nil-terminated sequence of strings alternating between source key paths and destination attributes
 */
- (void)mapKeyPathsToAttributes:(NSString *)sourceKeyPath, ... NS_REQUIRES_NIL_TERMINATION;


/**
 Configures a sub-key mapping for cases where JSON has been nested underneath a key named after an attribute.

 For example, consider the following JSON:

     { "users":
        {
            "blake": { "id": 1234, "email": "blake@restkit.org" },
            "rachit": { "id": 5678", "email": "rachit@restkit.org" }
        }
     }

 We can configure our mappings to handle this in the following form:

    ORKObjectMapping *mapping = [ORKObjectMapping mappingForClass:[User class]];
    mapping.forceCollectionMapping = YES; // RestKit cannot infer this is a collection, so we force it
    [mapping mapKeyOfNestedDictionaryToAttribute:@"firstName"];
    [mapping mapFromKeyPath:@"(firstName).id" toAttribute:"userID"];
    [mapping mapFromKeyPath:@"(firstName).email" toAttribute:"email"];

    [[ORKObjectManager sharedManager].mappingProvider setObjectMapping:mapping forKeyPath:@"users"];
 */
- (void)mapKeyOfNestedDictionaryToAttribute:(NSString *)attributeName;

/**
 Returns the attribute mapping targeting the key of a nested dictionary in the source JSON.
 This attribute mapping corresponds to the attributeName configured via mapKeyOfNestedDictionaryToAttribute:

 @see mapKeyOfNestedDictionaryToAttribute:
 @returns An attribute mapping for the key of a nested dictionary being mapped or nil
 */
- (ORKObjectAttributeMapping *)attributeMappingForKeyOfNestedDictionary;

/**
 Removes all currently configured attribute and relationship mappings from the object mapping
 */
- (void)removeAllMappings;

/**
 Removes an instance of an attribute or relationship mapping from the object mapping

 @param attributeOrRelationshipMapping The attribute or relationship mapping to remove
 */
- (void)removeMapping:(ORKObjectAttributeMapping *)attributeOrRelationshipMapping;

/**
 Remove the attribute or relationship mapping for the specified source keyPath

 @param sourceKeyPath A key-value coding key path to remove the mappings for
 */
- (void)removeMappingForKeyPath:(NSString *)sourceKeyPath;

#pragma mark - Inverse Mappings

/**
 Generates an inverse mapping for the rules specified within this object mapping. This can be used to
 quickly generate a corresponding serialization mapping from a configured object mapping. The inverse
 mapping will have the source and destination keyPaths swapped for all attribute and relationship mappings.
 */
- (ORKObjectMapping *)inverseMapping;

/**
 Returns the default value to be assigned to the specified attribute when it is missing from a
 mappable payload.

 The default implementation returns nil for transient object mappings. On managed object mappings, the
 default value returned from the Entity definition will be used.

 @see [ORKManagedObjectMapping defaultValueForMissingAttribute:]
 */
- (id)defaultValueForMissingAttribute:(NSString *)attributeName;

/**
 Returns an auto-released object that can be used to apply this object mapping
 given a set of mappable data. For transient objects, this generally returns an
 instance of the objectClass. For Core Data backed persistent objects, mappableData
 will be inspected to search for primary key data to lookup existing object instances.
 */
- (id)mappableObjectForData:(id)mappableData;

/**
 Returns the class of the attribute or relationship property of the target objectClass

 Given the name of a string property, this will return an NSString, etc.

 @param propertyName The name of the property we would like to retrieve the type of
 */
- (Class)classForProperty:(NSString *)propertyName;


// Deprecations
+ (id)mappingForClass:(Class)objectClass withBlock:(void (^)(ORKObjectMapping *))block DEPRECATED_ATTRIBUTE;
+ (id)mappingForClass:(Class)objectClass block:(void (^)(ORKObjectMapping *))block DEPRECATED_ATTRIBUTE;
+ (id)serializationMappingWithBlock:(void (^)(ORKObjectMapping *))block DEPRECATED_ATTRIBUTE;

@end

/////////////////////////////////////////////////////////////////////////////

/**
 Defines the inteface for configuring time and date formatting handling within RestKit
 object mappings. For performance reasons, RestKit reuses a pool of date formatters rather
 than constructing them at mapping time. This collection of date formatters can be configured
 on a per-object mapping or application-wide basis using the static methods exposed in this
 category.
 */
@interface ORKObjectMapping (DateAndTimeFormatting)

/**
 Returns the collection of default date formatters that will be used for all object mappings
 that have not been configured specifically.

 Out of the box, RestKit initializes the following default date formatters for you in the
 UTC time zone:
    * yyyy-MM-dd'T'HH:mm:ss'Z'
    * MM/dd/yyyy

 @return An array of NSFormatter objects used when mapping strings into NSDate attributes
 */
+ (NSArray *)defaultDateFormatters;

/**
 Sets the collection of default date formatters to the specified array. The array should
 contain configured instances of NSDateFormatter in the order in which you want them applied
 during object mapping operations.

 @param dateFormatters An array of date formatters to replace the existing defaults
 @see defaultDateFormatters
 */
+ (void)setDefaultDateFormatters:(NSArray *)dateFormatters;

/**
 Adds a date formatter instance to the default collection

 @param dateFormatter An NSFormatter object to append to the end of the default formatters collection
 @see defaultDateFormatters
 */
+ (void)addDefaultDateFormatter:(NSFormatter *)dateFormatter;

/**
 Convenience method for quickly constructing a date formatter and adding it to the collection of default
 date formatters. The locale is auto-configured to en_US_POSIX

 @param dateFormatString The dateFormat string to assign to the newly constructed NSDateFormatter instance
 @param nilOrTimeZone The NSTimeZone object to configure on the NSDateFormatter instance. Defaults to UTC time.
 @result A new NSDateFormatter will be appended to the defaultDateFormatters with the specified date format and time zone
 @see NSDateFormatter
 */
+ (void)addDefaultDateFormatterForString:(NSString *)dateFormatString inTimeZone:(NSTimeZone *)nilOrTimeZone;

/**
 Returns the preferred date formatter to use when generating NSString representations from NSDate attributes.
 This type of transformation occurs when RestKit is mapping local objects into JSON or form encoded serializations
 that do not have a native time construct.

 Defaults to a date formatter configured for the UTC Time Zone with a format string of "yyyy-MM-dd HH:mm:ss Z"

 @return The preferred NSFormatter object to use when serializing dates into strings
 */
+ (NSFormatter *)preferredDateFormatter;

/**
 Sets the preferred date formatter to use when generating NSString representations from NSDate attributes.
 This type of transformation occurs when RestKit is mapping local objects into JSON or form encoded serializations
 that do not have a native time construct.

 @param dateFormatter The NSFormatter object to designate as the new preferred instance
 */
+ (void)setPreferredDateFormatter:(NSFormatter *)dateFormatter;

@end
