//
//  ABVariant.h
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
 An `ABVariant` contains arrays of `ABCondition` and `ABMod` objects. When all
 `ABCondition`s are met, the `ABMod`s take effect. An `ABVariant` must contain
 at least one `ABMod` to be valid.
 */
@interface ABVariant : NSObject

/**
 *  Initializes an `ABVariant` with the given identifier, operator, conditions,
 *and mods.
 *
 *  @param identifier A unique identifier for the `ABVariant`.
 *  @param op         The operator used to evaluate the conditions.
 *  @param conditions An array of `ABCondition` objects.
 *  @param mods       An array of `ABMod` objects.
 *
 *  @return A newly initialized `ABVariant` object.
 */
- (instancetype)initWithIdentifier:(NSString *)identifier
                                op:(NSString *)op
                        conditions:(NSArray *)conditions
                              mods:(NSArray *)mods;

/**
 *  Returns the result of a modified flag using this object's `ABMod`s.
 *
 *  @param name The flag name to evaluate.
 *
 *  @return The value determined by this `ABVariant`. Typically a foundation
 *object (`NSNumber`).
 */
- (id)valueForFlagWithName:(NSString *)name;

/**
 *  Evaluates whether this object should apply its `ABMod`s to a flag given a
 *context object.
 *
 *  @param context A user-defined context object dependent on the evaluation
 *function used by this object's `ABCondition` objects.
 *
 *  @return Whether this `ABVariant` is active and should apply its `ABMod`s.
 */
- (BOOL)evaluateWithContext:(id<NSCopying>)context;

/**
 *  A unique identifier for this object.
 */
@property(nonatomic, copy, readonly) NSString *identifier;

/**
 *  The operator (either `ABVariantOperatorAND` or `ABVariantOperatorOR`) used
 * to evaluate the conditions.
 */
@property(nonatomic, copy, readonly) NSString *op;

/**
 *  An array of `ABCondition` objects used to determine the active state of this
 * object.
 */
@property(nonatomic, copy, readonly) NSArray *conditions;

/**
 *  An array of `ABMod` objects used to determine how to modify flag values
 * should this object be active.
 */
@property(nonatomic, copy, readonly) NSArray *mods;

/**
 *  The AND operator. Used by an `ABVariant` to evaluate its `ABCondition`s.
 */
extern NSString *const ABVariantOperatorAND;

/**
 *  The OR operator. Used by an `ABVariant` to evaluate its `ABCondition`s.
 */
extern NSString *const ABVariantOperatorOR;

@end
