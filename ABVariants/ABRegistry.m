//
//  ABRegistry.m
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

#import "ABRegistry.h"

#import "ABCondition.h"
#import "ABFlag.h"
#import "ABMod.h"
#import "ABVariant.h"

NSString *const ABRegistryDidChangeNotification =
    @"ABRegistryDidChangeNotification";

@interface ABRegistry ()
- (void)_addFlag:(ABFlag *)flag;
- (void)_addVariant:(ABVariant *)variant;
- (void)_registerBuiltInConditionTypes;
- (ABVariant *)_variantFromDictionary:(NSDictionary *)dictionary;

@property(nonatomic, strong) dispatch_queue_t isolationQueue;
@property(nonatomic, strong) NSMutableDictionary *variantIDToVariant;
@property(nonatomic, strong) NSMutableDictionary *conditionTypeToSpecBlock;
@property(nonatomic, strong) NSMutableDictionary *flagNameToFlag;
@property(nonatomic, strong) NSMutableDictionary *flagNameToVariantIDSet;
@end

@implementation ABRegistry

+ (instancetype)defaultRegistry {
  static dispatch_once_t onceToken;
  static ABRegistry *_defaultRegistry = nil;
  dispatch_once(&onceToken, ^{ _defaultRegistry = [[ABRegistry alloc] init]; });
  return _defaultRegistry;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _isolationQueue =
        dispatch_queue_create("com.andybons.ABVariants.registryIsolationQueue",
                              DISPATCH_QUEUE_CONCURRENT);
    _variantIDToVariant = [NSMutableDictionary dictionary];
    _conditionTypeToSpecBlock = [NSMutableDictionary dictionary];
    _flagNameToFlag = [NSMutableDictionary dictionary];
    _flagNameToVariantIDSet = [NSMutableDictionary dictionary];

    [self _registerBuiltInConditionTypes];
  }
  return self;
}

- (id)flagValueWithName:(NSString *)name {
  return [self flagValueWithName:name context:nil];
}

- (id)flagValueWithName:(NSString *)name context:(id<NSCopying>)context {
  __block id value;
  dispatch_sync(self.isolationQueue, ^{
      value = [(ABFlag *)self.flagNameToFlag[name] baseValue];
      for (NSString *variantId in self.flagNameToVariantIDSet[name]) {
        ABVariant *v = self.variantIDToVariant[variantId];
        if ([v evaluateWithContext:context]) {
          value = [v valueForFlagWithName:name];
        }
      }
  });
  return value;
}

- (void)registerConditionTypeWithID:(NSString *)identifier
                          specBlock:(ABConditionSpec)specBlock {
  identifier = [identifier uppercaseString];
  dispatch_sync(self.isolationQueue, ^{
      if (self.conditionTypeToSpecBlock[identifier]) {
        [NSException
             raise:@"Condition has already been registered"
            format:
                @"A Condition with identifier %@ has already been registered",
                identifier];
      }
  });
  dispatch_barrier_async(self.isolationQueue, ^{
      self.conditionTypeToSpecBlock[identifier] = specBlock;
  });
}

- (void)loadConfigFromData:(NSData *)data error:(NSError **)error {
  NSDictionary *config =
      [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
  if (!config) {
    return;
  }
  [self loadConfigFromDictionary:config];
}

- (void)loadConfigFromDictionary:(NSDictionary *)dictionary {
  for (NSDictionary *d in dictionary[@"flag_defs"]) {
    [self _addFlag:[ABFlag flagFromDictionary:d]];
  }
  for (NSDictionary *d in dictionary[@"variants"]) {
    [self _addVariant:[self _variantFromDictionary:d]];
  }
  [[NSNotificationCenter defaultCenter]
      postNotificationName:ABRegistryDidChangeNotification
                    object:self];
}

#pragma mark - Private methods

- (void)_addFlag:(ABFlag *)flag {
  dispatch_sync(self.isolationQueue, ^{
      if (self.flagNameToFlag[flag.name]) {
        [NSException raise:@"Flag has already been added"
                    format:@"A Flag with the name %@ has already been added",
                           flag.name];
      }
  });
  dispatch_barrier_async(self.isolationQueue, ^{
      self.flagNameToFlag[flag.name] = flag;
      self.flagNameToVariantIDSet[flag.name] = [NSMutableSet set];
  });
}

- (void)_addVariant:(ABVariant *)variant {
  dispatch_sync(self.isolationQueue, ^{
      if (self.variantIDToVariant[variant.identifier]) {
        [NSException
             raise:@"Variant has already been added"
            format:@"A Variant with the idenfier %@ has already been added",
                   variant.identifier];
      }
  });
  for (ABMod *m in variant.mods) {
    dispatch_sync(self.isolationQueue, ^{
        if (![self.flagNameToFlag.allKeys containsObject:m.flagName]) {
          [NSException
               raise:@"Variant has unknown flag"
              format:@"Variant with the idenfier %@ has unknown flag %@",
                     variant.identifier, m.flagName];
        }
    });
    dispatch_barrier_async(self.isolationQueue, ^{
        [self.flagNameToVariantIDSet[m.flagName] addObject:variant.identifier];
    });
  }
  dispatch_barrier_async(self.isolationQueue, ^{
      self.variantIDToVariant[variant.identifier] = variant;
  });
}

- (void)_registerBuiltInConditionTypes {
  srand48(time(0));
  ABConditionSpec randomSpec = ^ABConditionEvaluator(id<NSCopying> value) {
      if (![(NSObject *)value isKindOfClass:[NSNumber class]] ||
          [(NSNumber *)value doubleValue] < 0 ||
          [(NSNumber *)value doubleValue] > 1) {
        [NSException
             raise:@"Invalid argument to RANDOM condition type"
            format:@"The value %@ must be an NSNumber between 0-1", value];
      }
      return ^BOOL(id<NSCopying> context) {
          return drand48() <= [(NSNumber *)value doubleValue];
      };
  };
  [self registerConditionTypeWithID:@"RANDOM" specBlock:randomSpec];

  ABConditionSpec rangeSpec = ^ABConditionEvaluator(id<NSCopying> value) {
      NSArray *values = (NSArray *)value;
      if (!values || values.count != 3) {
        [NSException
             raise:@"Invalid argument to MOD_RANGE condition type"
            format:@"Expected array with key and and two integer range values"];
      }
      if (![values[0] isKindOfClass:[NSString class]]) {
        [NSException raise:@"Invalid argument to MOD_RANGE condition type"
                    format:@"The first value %@ must be a string", values[0]];
      }
      NSString *key = (NSString *)values[0];
      if (![values[1] isKindOfClass:[NSNumber class]]) {
        [NSException raise:@"Invalid argument to MOD_RANGE condition type"
                    format:@"The second value %@ must be a number", values[1]];
      }
      NSNumber *rangeBegin = (NSNumber *)values[1];

      if (![values[2] isKindOfClass:[NSNumber class]]) {
        [NSException raise:@"Invalid argument to MOD_RANGE condition type"
                    format:@"The third value %@ must be a number", values[2]];
      }
      NSNumber *rangeEnd = (NSNumber *)values[2];

      if ([rangeBegin doubleValue] > [rangeEnd doubleValue]) {
        [NSException raise:@"Invalid argument to MOD_RANGE condition type"
                    format:@"Start range %@ must be less than end range %@",
                           rangeBegin, rangeEnd];
      }
      return ^BOOL(id<NSCopying> context) {
          if (![(NSObject *)context isKindOfClass:[NSDictionary class]]) {
            return NO;
          }
          id val = ((NSDictionary *)context)[key];
          if (![val isKindOfClass:[NSNumber class]]) {
            return NO;
          }
          NSInteger mod = [(NSNumber *)val integerValue] % 100;
          return mod >= rangeBegin.integerValue && mod <= rangeEnd.integerValue;
      };
  };
  [self registerConditionTypeWithID:@"MOD_RANGE" specBlock:rangeSpec];
}

- (ABVariant *)_variantFromDictionary:(NSDictionary *)dictionary {
  NSMutableArray *conditions = [NSMutableArray array];
  for (NSDictionary *d in dictionary[@"conditions"]) {
    NSString *type = [d[@"type"] uppercaseString];
    ABConditionSpec spec = self.conditionTypeToSpecBlock[type];
    if (!spec) {
      [NSException
           raise:@"Unregistered condition type"
          format:@"The condition type %@ has not been registered", type];
    }
    id<NSCopying> value = d[@"value"];
    NSArray *values = d[@"values"];
    if (value && values) {
      [NSException
           raise:@"Invalid Variant specification"
          format:@"Cannot specify both a value and array of values for %@",
                 type];
    }
    ABConditionEvaluator evaluator = value ? spec(value) : spec(values);
    [conditions
        addObject:[[ABCondition alloc] initWithEvaluationBlock:evaluator]];
  }
  NSMutableArray *mods = [NSMutableArray array];
  for (NSDictionary *d in dictionary[@"mods"]) {
    [mods addObject:[ABMod modFromDictionary:d]];
  }
  return [[ABVariant alloc] initWithIdentifier:dictionary[@"id"]
                                            op:dictionary[@"condition_operator"]
                                    conditions:conditions
                                          mods:mods];
}

@end
