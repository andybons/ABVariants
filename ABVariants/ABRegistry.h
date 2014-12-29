//
//  ABRegistry.h
//  ABVariants
//
//  Copyright (c) 2014 Andrew Bonventre
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.

@import Foundation;

#import "ABCondition.h"

/**
 *  An `ABRegistry` keeps track of all `ABFlags`, `ABConditions`, and
 * `ABVariants`.
 */
@interface ABRegistry : NSObject

/**
 *  Returns the default `ABRegistry`.
 */
+ (instancetype)defaultRegistry;

/**
 *  Returns the value of a flag given an empty context object.
 *
 *  @param name The name of the flag to evalute.
 *
 *  @return A value determined by any `ABVariant` that affects the flag,
 *typically a foundation object (`NSNumber`) that is marshalled from a JSON
 *file.
 */
- (id)flagValueWithName:(NSString *)name;

/**
 *  Returns the value of a flag given a context object.
 *
 *  @param name    The name of the flag to evaluate.
 *  @param context Any context to pass to the user-defined block in the
 *`ABCondition` that will be used to evaluate whether an `ABVariant` will be
 *applied to the resulting value.
 *
 *  @return A value determined by any `ABVariant` that affects the flag,
 *typically a foundation object (`NSNumber`) that is marshalled from a JSON
 *file.
 */
- (id)flagValueWithName:(NSString *)name context:(id<NSCopying>)context;

/**
 *  Registers a new condition type with the given identifier and evaluation
 *block.
 *
 *  @param identifier A unique identifier for the condition type. It cannot be
 *an identifier already registered. Note that `RANDOM` and `MOD_RANGE` are
 *built-in condition types that are registered in all `ABRegistry` objects.
 *  @param specBlock  A block that returns an `ABConditionEvaluator` based on
 *the
 *parameters typically supplied by a configuration file.
 *  @param error      If an error occurs, upon return contains an NSError object
 *that describes the problem.
 */
- (void)registerConditionTypeWithID:(NSString *)identifier
                          specBlock:(ABConditionSpec)specBlock
                              error:(NSError **)error;

/**
 *  Loads `ABFlags`, `ABConditions`, and `ABVariants` into the Registry from an
 *NSData object that will be deserialized using `NSJSONSerialization`.
 *
 *  @param data  <#data description#>
 *  @param error If an error occurs, upon return contains an NSError object that
 *describes the problem.
 */
- (void)loadConfigFromData:(NSData *)data error:(NSError **)error;

/**
 *  Loads `ABFlags`, `ABConditions`, and `ABVariants` into the Registry from an
 *`NSDictionary` representation.
 *
 *  @param dictionary The `ABRegistry` represented as key/value pairs.
 *  @param error      If an error occurs, upon return contains an NSError object
 *that describes the problem.
 */
- (void)loadConfigFromDictionary:(NSDictionary *)dictionary
                           error:(NSError **)error;
@end

/**
 *  This notification is posted when a change is made to an `ABRegistry`.
 *
 *  The notification object is the `ABRegistry` object. This notification does
 *not contain a userInfo dictionary.
 */
extern NSString *const ABRegistryDidChangeNotification;
