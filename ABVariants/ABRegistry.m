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
NSString *const ABRegistryFlagDefinitionsKey = @"flag_defs";
NSString *const ABRegistryVariantsKey = @"variants";
NSString *const ABVariantsRegistryErrorDomain =
    @"ABVariantsRegistryErrorDomain";

@interface ABRegistry ()
- (BOOL)_addFlag:(ABFlag *)flag error:(NSError **)error;
- (BOOL)_addVariant:(ABVariant *)variant error:(NSError **)error;
- (void)_registerBuiltInConditionTypes;
- (ABVariant *)_variantFromDictionary:(NSDictionary *)dictionary
                                error:(NSError **)error;
- (NSError *)_registryErrorWithDescription:(NSString *)description;

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

+ (instancetype)registryWithIdentifier:(NSString *)identifier {
  static dispatch_once_t registryListToken;
  static NSMutableDictionary *_registryIDToRegistry = nil;
  static dispatch_queue_t _registryListQueue;
  dispatch_once(&registryListToken, ^{
      _registryListQueue =
          dispatch_queue_create("com.andybons.ABVariants.namedRegistryQueue",
                                DISPATCH_QUEUE_CONCURRENT);
      _registryIDToRegistry = [NSMutableDictionary dictionary];
  });
  __block ABRegistry *registry;
  dispatch_sync(_registryListQueue,
                ^{ registry = _registryIDToRegistry[identifier]; });
  if (!registry) {
    dispatch_barrier_async(_registryListQueue, ^{
        _registryIDToRegistry[identifier] = [[ABRegistry alloc] init];
    });
    dispatch_sync(_registryListQueue,
                  ^{ registry = _registryIDToRegistry[identifier]; });
  }
  return registry;
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

- (BOOL)registerConditionTypeWithID:(NSString *)identifier
                          specBlock:(ABConditionSpec)specBlock
                              error:(NSError **)error {
  __block NSError *registerError;
  identifier = [identifier uppercaseString];
  dispatch_sync(self.isolationQueue, ^{
      if (self.conditionTypeToSpecBlock[identifier]) {
        NSString *errorDescription =
            [NSString stringWithFormat:NSLocalizedString(
                                           @"A Condition with identifier %@ "
                                           @"has already been registered",
                                           nil),
                                       identifier];
        registerError = [self _registryErrorWithDescription:errorDescription];
      }
  });
  if (error && registerError) {
    *error = registerError;
    return NO;
  }
  dispatch_barrier_async(self.isolationQueue, ^{
      self.conditionTypeToSpecBlock[identifier] = specBlock;
  });
  return YES;
}

- (BOOL)loadConfigFromData:(NSData *)data error:(NSError **)error {
  NSDictionary *config =
      [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
  if (!config) {
    return NO;
  }
  return [self loadConfigFromDictionary:config error:error];
}

- (BOOL)loadConfigFromDictionary:(NSDictionary *)dictionary
                           error:(NSError **)error {
  for (NSDictionary *d in dictionary[ABRegistryFlagDefinitionsKey]) {
    [self _addFlag:[ABFlag flagFromDictionary:d] error:error];
  }
  for (NSDictionary *d in dictionary[ABRegistryVariantsKey]) {
    ABVariant *variant = [self _variantFromDictionary:d error:error];
    if (!variant || (error && *error)) {
      return NO;
    }
    [self _addVariant:variant error:error];
    if (error && *error) {
      return NO;
    }
  }
  [[NSNotificationCenter defaultCenter]
      postNotificationName:ABRegistryDidChangeNotification
                    object:self];
  return YES;
}

#pragma mark - Private methods

- (BOOL)_addFlag:(ABFlag *)flag error:(NSError **)error {
  __block NSError *addError;
  dispatch_sync(self.isolationQueue, ^{
      if (self.flagNameToFlag[flag.name]) {
        NSString *errorDescription = [NSString
            stringWithFormat:
                NSLocalizedString(
                    @"A flag with the name %@ has already been added", nil),
                flag.name];
        addError = [self _registryErrorWithDescription:errorDescription];
      }
  });
  if (error && addError) {
    *error = addError;
    return NO;
  }
  dispatch_barrier_async(self.isolationQueue, ^{
      self.flagNameToFlag[flag.name] = flag;
      self.flagNameToVariantIDSet[flag.name] = [NSMutableSet set];
  });
  return YES;
}

- (BOOL)_addVariant:(ABVariant *)variant error:(NSError **)error {
  __block NSError *addError;
  dispatch_sync(self.isolationQueue, ^{
      if (self.variantIDToVariant[variant.identifier]) {
        NSString *errorDescription = [NSString
            stringWithFormat:
                NSLocalizedString(
                    @"A Variant with the identifier %@ has already been added",
                    nil),
                variant.identifier];
        addError = [self _registryErrorWithDescription:errorDescription];
      }
  });
  if (error && addError) {
    *error = addError;
    return NO;
  }
  for (ABMod *m in variant.mods) {
    dispatch_sync(self.isolationQueue, ^{
        if (![self.flagNameToFlag.allKeys containsObject:m.flagName]) {
          NSString *errorDescription = [NSString
              stringWithFormat:
                  NSLocalizedString(
                      @"Variant with the idenfier %@ has unknown flag %@", nil),
                  variant.identifier, m.flagName];
          addError = [self _registryErrorWithDescription:errorDescription];
        }
    });
    if (error && addError) {
      *error = addError;
      return NO;
    }
    dispatch_barrier_async(self.isolationQueue, ^{
        [self.flagNameToVariantIDSet[m.flagName] addObject:variant.identifier];
    });
  }
  dispatch_barrier_async(self.isolationQueue, ^{
      self.variantIDToVariant[variant.identifier] = variant;
  });
  return YES;
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
  NSError *error;
  [self registerConditionTypeWithID:@"RANDOM"
                          specBlock:randomSpec
                              error:&error];
  if (error) {
    [NSException raise:@"Internal inconsistency exception"
                format:@"%@", error.localizedDescription];
  }

  ABConditionSpec rangeSpec = ^ABConditionEvaluator(id<NSCopying> value) {
      // TODO(andybons): The amount of exceptions here is a bit gnarly.
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
  [self registerConditionTypeWithID:@"MOD_RANGE"
                          specBlock:rangeSpec
                              error:&error];
  if (error) {
    [NSException raise:@"Internal inconsistency exception"
                format:@"%@", error.localizedDescription];
  }
}

- (ABVariant *)_variantFromDictionary:(NSDictionary *)dictionary
                                error:(NSError **)error {
  NSError *variantError;
  NSMutableArray *conditions = [NSMutableArray array];
  for (NSDictionary *d in dictionary[@"conditions"]) {
    NSString *type = [d[@"type"] uppercaseString];
    ABConditionSpec spec = self.conditionTypeToSpecBlock[type];
    if (!spec) {
      NSString *str = [NSString
          stringWithFormat:@"The condition type %@ has not been registered",
                           type];
      variantError =
          [self _registryErrorWithDescription:NSLocalizedString(str, nil)];
      if (error) {
        *error = variantError;
      }
      return nil;
    }
    id<NSCopying> value = d[@"value"];
    NSArray *values = d[@"values"];
    if (value && values) {
      NSString *str = [NSString
          stringWithFormat:
              @"Cannot specify both a value and array of values for %@", type];
      variantError =
          [self _registryErrorWithDescription:NSLocalizedString(str, nil)];
      if (error) {
        *error = variantError;
      }
      return nil;
    }
    ABConditionEvaluator evaluator = value ? spec(value) : spec(values);
    [conditions
        addObject:[[ABCondition alloc] initWithEvaluationBlock:evaluator]];
  }
  NSMutableArray *mods = [NSMutableArray array];
  for (NSDictionary *d in dictionary[@"mods"]) {
    [mods addObject:[ABMod modFromDictionary:d]];
  }
  NSString *op = dictionary[@"condition_operator"];
  if ((op && conditions.count < 2) || (!op && conditions.count >= 2)) {
    variantError =
        [self _registryErrorWithDescription:
                  NSLocalizedString(op ? @"Cannot have a Variant operator "
                                        @"without multiple conditions"
                                       : @"Cannot have multiple variant "
                                        @"conditions without an operator",
                                    nil)];
    if (error) {
      *error = variantError;
    }
    return nil;
  }
  if (op && (![op isEqualToString:ABVariantOperatorAND] &&
             ![op isEqualToString:ABVariantOperatorOR])) {
    NSString *str = [NSString
        stringWithFormat:
            @"Expected operator to be \"AND\" or \"OR\", got \"%@\"", op];
    variantError =
        [self _registryErrorWithDescription:NSLocalizedString(str, nil)];
    if (error) {
      *error = variantError;
    }
    return nil;
  }
  return [[ABVariant alloc] initWithIdentifier:dictionary[@"id"]
                                            op:op
                                    conditions:conditions
                                          mods:mods];
}

- (NSError *)_registryErrorWithDescription:(NSString *)description {
  return [NSError errorWithDomain:ABVariantsRegistryErrorDomain
                             code:0
                         userInfo:@{
                           NSLocalizedDescriptionKey : description,
                         }];
}

@end
