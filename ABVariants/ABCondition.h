//
//  ABCondition.h
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
 *  An `ABConditionEvaluator` is a user-defined block that returns a `BOOL`
 *indicating whether the owning `ABVariant` is active or not.
 *
 *  @param id<NSCopying> An optional object that the block can use during
 *evaluation at runtime.
 *
 *  @return `YES` if the condition has been met with the given parameter. `NO`
 *otherwise.
 */
typedef BOOL (^ABConditionEvaluator)(id<NSCopying>);

/**
 *  An `ABConditionSpec` returns an `ABConditionEvaluator` based on the
 *parameters typically supplied by the configuration file. For instance, to
 *generate an `ABConditionEvaluator` that returns YES 50% of the time, one would
 *supply a condition of type `RANDOM` (a built-in type) with a value of 0.5.
 *
 *  @param id<NSCopying> A value used to generate and return the
 *`ABConditionEvaluator` block.
 *
 *  @return The `ABConditionEvaluator` block that is used to evaluate whether
 *the owning `ABVariant` is active.
 */
typedef ABConditionEvaluator (^ABConditionSpec)(id<NSCopying>);

/**
 An `ABCondition` wraps a user-defined block used to evaluate whether the owning
 `ABVariant` is “active.”
 */
@interface ABCondition : NSObject

/**
 *  Initializes an `ABCondition` object with the specified
 *`ABConditionEvaluator`. An `ABConditionEvaluator` is a user-defined block that
 *returns a `BOOL` indicating whether the owning `ABVariant` is active or not.
 *
 *  @param block a user-defined block used to evaluate whether the owning
 *`ABVariant` is active.
 *
 *  @return A newly initialized `ABCondition` object.
 */
- (instancetype)initWithEvaluationBlock:(ABConditionEvaluator)block;

/**
 *  The block used to evaluate whether the owning `ABVariant` is active or not.
 */
@property(nonatomic, copy, readonly) BOOL (^evaluationBlock)(id<NSCopying>);

@end
