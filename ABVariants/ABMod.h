//
//  ABMod.h
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
 An `ABMod` defines how an `ABFlag` changes. `ABVariants` contain `ABMods` that
 take effect when the `ABVariant` is active.
 */
@interface ABMod : NSObject

/**
 *  Initializes an `ABMod` with the given name and value.
 *
 *  @param flagName The name of the `ABFlag` that this `ABMod` applies to.
 *  @param value    The value that will be applied to the `ABFlag` if the
 *`ABVariant` is active.
 *
 *  @return A newly initialized `ABMod` object.
 */
- (instancetype)initWithFlagName:(NSString *)flagName
                           value:(id<NSCopying>)value;

/**
 *  Initializes an `ABMod` object with the given `NSDictionary`. Typically used
 *in conjuction with the `NSJSONSerialization` class.
 *
 *  @param dictionary The `ABMod` represented as key/value pairs.
 *
 *  @return A newly initialized `ABMod` object.
 */
+ (instancetype)modFromDictionary:(NSDictionary *)dictionary;

/**
 *  The name of the `ABFlag` that this `ABMod` applies to.
 */
@property(nonatomic, copy, readonly) NSString *flagName;

/**
 *  The value to be applied to the flag with the name `flagName` if the
 * `ABVariant` is active.
 */
@property(nonatomic, copy, readonly) id value;

@end
