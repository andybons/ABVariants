//
//  ABFlag.h
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

/**
 An `ABFlag` defines a value that may change on a contextual basis based on the
 `ABVariant` objects that refer to it.
 */
@interface ABFlag : NSObject

/**
 *  Initializes an `ABFlag` object with the given name, description, and base
 *value.
 *
 *  @param name The name of the flag (e.g. `enable_feature_foo`).
 *  @param description A description of the flag (e.g. "enables feature foo").
 *  @param baseValue The default value of the flag.
 *
 *  @return A newly initialized `ABFlag` object.
 */
- (instancetype)initWithName:(NSString *)name
                 description:(NSString *)description
                   baseValue:(id<NSCopying>)baseValue;

/**
 *  Initializes an `ABFlag` object with the given `NSDictionary`. Typically used
 *in conjuction with the `NSJSONSerialization` class.
 *
 *  @param dictionary The `ABFlag` represented as key/value pairs.
 *
 *  @return A newly initialized `ABFlag` object.
 */
+ (instancetype)flagFromDictionary:(NSDictionary *)dictionary;

/**
 *  The name of the flag.
 */
@property(nonatomic, copy, readonly) NSString *name;

/**
 *  The description of the flag.
 */
@property(nonatomic, copy, readonly) NSString *flagDescription;

/**
 *  The base value of the flag.
 */
@property(nonatomic, copy, readonly) id baseValue;

@end
