//
//  ORKLog.m
//  RestKit
//
//  Created by Blake Watters on 6/10/11.
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

#import "ORKLog.h"
#import "lcl.h"

int ORKLogLevelForString(NSString *, NSString *);

static BOOL loggingInitialized = NO;

void ORKLogInitialize(void)
{
    if (loggingInitialized == NO) {
        lcl_configure_by_name("RestKit*", ORKLogLevelDefault);
        lcl_configure_by_name("App", ORKLogLevelDefault);
        ORKLogInfo(@"RestKit initialized...");
        loggingInitialized = YES;
    }
}


void ORKLogConfigureFromEnvironment(void)
{
    NSArray *validEnvVariables = [NSArray arrayWithObjects:
                                       @"ORKLogLevel.App",
                                       @"ORKLogLevel.RestKit",
                                       @"ORKLogLevel.RestKit.CoreData",
                                       @"ORKLogLevel.RestKit.CoreData.SearchEngine",
                                       @"ORKLogLevel.RestKit.Network",
                                       @"ORKLogLevel.RestKit.Network.Cache",
                                       @"ORKLogLevel.RestKit.Network.Queue",
                                       @"ORKLogLevel.RestKit.Network.Reachability",
                                       @"ORKLogLevel.RestKit.ObjectMapping",
                                       @"ORKLogLevel.RestKit.Support",
                                       @"ORKLogLevel.RestKit.Support.Parsers",
                                       @"ORKLogLevel.RestKit.Testing",
                                       @"ORKLogLevel.RestKit.Three20",
                                       @"ORKLogLevel.RestKit.UI",
                                       nil];

    static NSString *logComponentPrefix = @"ORKLogLevel.";

    NSDictionary *envVars = [[NSProcessInfo processInfo] environment];

    for (NSString *envVarName in [envVars allKeys]) {
        if ([envVarName hasPrefix:logComponentPrefix]) {
            if (![validEnvVariables containsObject:envVarName]) {
                 @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"The ORKLogLevel Environment Variable name must be one of the following: %@", validEnvVariables] userInfo:nil];
            }
            NSString *logLevel = [envVars valueForKey:envVarName];
            NSString *logComponent = [envVarName stringByReplacingOccurrencesOfString:logComponentPrefix withString:@""];
            logComponent = [logComponent stringByReplacingOccurrencesOfString:@"." withString:@"/"];

            const char *log_component_c_str = [logComponent cStringUsingEncoding:NSUTF8StringEncoding];
            int log_level_int = ORKLogLevelForString(logLevel, envVarName);
            ORKLogConfigureByName(log_component_c_str, log_level_int);
        }
    }
}


int ORKLogLevelForString(NSString *logLevel, NSString *envVarName)
{
    // Forgive the user if they specify the full name for the value i.e. "ORKLogLevelDebug" instead of "Debug"
    logLevel = [logLevel stringByReplacingOccurrencesOfString:@"ORKLogLevel" withString:@""];

    if ([logLevel isEqualToString:@"Off"] ||
        [logLevel isEqualToString:@"0"]) {
        return ORKLogLevelOff;
    }
    else if ([logLevel isEqualToString:@"Critical"] ||
             [logLevel isEqualToString:@"1"]) {
        return ORKLogLevelCritical;
    }
    else if ([logLevel isEqualToString:@"Error"] ||
             [logLevel isEqualToString:@"2"]) {
        return ORKLogLevelError;
    }
    else if ([logLevel isEqualToString:@"Warning"] ||
             [logLevel isEqualToString:@"3"]) {
        return ORKLogLevelWarning;
    }
    else if ([logLevel isEqualToString:@"Info"] ||
             [logLevel isEqualToString:@"4"]) {
        return ORKLogLevelInfo;
    }
    else if ([logLevel isEqualToString:@"Debug"] ||
             [logLevel isEqualToString:@"5"]) {
        return ORKLogLevelDebug;
    }
    else if ([logLevel isEqualToString:@"Trace"] ||
             [logLevel isEqualToString:@"6"]) {
        return ORKLogLevelTrace;
    }
    else if ([logLevel isEqualToString:@"Default"]) {
        return ORKLogLevelDefault;
    }
    else {
        NSString *errorMessage = [NSString stringWithFormat:@"The value: \"%@\" for the environment variable: \"%@\" is invalid. \
                                  \nThe log level must be set to one of the following values \
                                  \n    Default  or 0 \
                                  \n    Critical or 1 \
                                  \n    Error    or 2 \
                                  \n    Warning  or 3 \
                                  \n    Info     or 4 \
                                  \n    Debug    or 5 \
                                  \n    Trace    or 6\n", logLevel, envVarName];
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:errorMessage userInfo:nil];

        return -1;
    }
}

void ORKLogValidationError(NSError *validationError) {
    if ([[validationError domain] isEqualToString:@"NSCocoaErrorDomain"]) {
        NSDictionary *userInfo = [validationError userInfo];
        NSArray *errors = [userInfo valueForKey:@"NSDetailedErrors"];
        if (errors) {
            for (NSError *detailedError in errors) {
                NSDictionary *subUserInfo = [detailedError userInfo];
                ORKLogError(@"Core Data Save Error\n \
                           NSLocalizedDescription:\t\t%@\n \
                           NSValidationErrorKey:\t\t\t%@\n \
                           NSValidationErrorPredicate:\t%@\n \
                           NSValidationErrorObject:\n%@\n",
                           [subUserInfo valueForKey:@"NSLocalizedDescription"],
                           [subUserInfo valueForKey:@"NSValidationErrorKey"],
                           [subUserInfo valueForKey:@"NSValidationErrorPredicate"],
                           [subUserInfo valueForKey:@"NSValidationErrorObject"]);
            }
        }
        else {
            ORKLogError(@"Core Data Save Error\n \
                       NSLocalizedDescription:\t\t%@\n \
                       NSValidationErrorKey:\t\t\t%@\n \
                       NSValidationErrorPredicate:\t%@\n \
                       NSValidationErrorObject:\n%@\n",
                       [userInfo valueForKey:@"NSLocalizedDescription"],
                       [userInfo valueForKey:@"NSValidationErrorKey"],
                       [userInfo valueForKey:@"NSValidationErrorPredicate"],
                       [userInfo valueForKey:@"NSValidationErrorObject"]);
        }
    }
}

void ORKLogIntegerAsBinary(NSUInteger bitMask) {
    NSUInteger bit = ~(NSUIntegerMax >> 1);
    NSMutableString *string = [NSMutableString string];
    do {
        [string appendString:(((NSUInteger)bitMask & bit) ? @"1" : @"0")];
    } while (bit >>= 1);

    NSLog(@"Value of %ld in binary: %@", (long)bitMask, string);
}
