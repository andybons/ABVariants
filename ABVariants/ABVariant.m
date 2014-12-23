//
//  ABVariant.m
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

#import "ABVariant.h"

#import "ABCondition.h"
#import "ABMod.h"

NSString *const ABVariantOperatorAND = @"AND";
NSString *const ABVariantOperatorOR = @"OR";

@implementation ABVariant

- (instancetype)initWithIdentifier:(NSString *)identifier
                                op:(NSString *)op
                        conditions:(NSArray *)conditions
                              mods:(NSArray *)mods {
  self = [super init];
  if (self) {
    if ((op && conditions.count < 2) || (!op && conditions.count >= 2)) {
      [NSException raise:@"Invalid arguments to Variant initializer"
                  format:op ? @"Cannot have a Variant operator "
                             @"without multiple conditions"
                            : @"Cannot have multiple variant "
                             @"conditions without an operator"];
    }
    if (op && (![op isEqualToString:ABVariantOperatorAND] &&
               ![op isEqualToString:ABVariantOperatorOR])) {
      [NSException
           raise:@"Invalid operator passed to Variant initializer"
          format:@"Expected operator to be \"AND\" or \"OR\", got \"%@\"", op];
    }

    _identifier = [identifier copy];
    _op = [op copy];
    _conditions = [conditions copy];
    _mods = [mods copy];
  }
  return self;
}

- (id)valueForFlagWithName:(NSString *)name {
  for (ABMod *m in self.mods) {
    if ([m.flagName isEqualToString:name]) {
      return m.value;
    }
  }
  return nil;
}

- (BOOL)evaluateWithContext:(id<NSCopying>)context {
  if ([self.op isEqualToString:ABVariantOperatorOR]) {
    for (ABCondition *c in self.conditions) {
      if (c.evaluationBlock(context)) {
        return YES;
      }
    }
    return NO;
  } else if (self.conditions.count <= 1 ||
             [self.op isEqualToString:ABVariantOperatorAND]) {
    for (ABCondition *c in self.conditions) {
      if (!c.evaluationBlock(context)) {
        return NO;
      }
    }
    return YES;
  }
  return NO;
}

@end
