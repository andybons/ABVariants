//
//  ABRegistryTest.m
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
@import XCTest;

#import "ABVariants.h"

@interface ABVariantsRegistryTest : XCTestCase
@property(nonatomic, strong) ABRegistry *registry;
@end

@implementation ABVariantsRegistryTest

- (void)setUp {
  self.registry = [[ABRegistry alloc] init];
  [super setUp];
}

- (void)loadConfigFile:(NSString *)filename {
  NSError *error;
  NSString *filePath =
      [[NSBundle bundleForClass:[self class]] pathForResource:filename
                                                       ofType:nil];
  [self.registry loadConfigFromData:[NSData dataWithContentsOfFile:filePath]
                              error:&error];
  XCTAssertNil(error);
}

- (void)testRegistrySingleton {
  XCTAssertNotNil([ABRegistry sharedRegistry]);
  XCTAssertEqualObjects([ABRegistry sharedRegistry],
                        [ABRegistry sharedRegistry]);
}

- (void)testErrorConditions {
  NSDictionary *config = @{
    @"variants" : @[
      @{
        @"id" : @"Fail",
        @"condition_operator" : @"AND",
        @"conditions" : @[
          @{@"type" : @"RANDOM", @"value" : @"foo", @"values" : @[ @"foo" ]}
        ],
        @"mods" : @[ @{@"flag" : @"foo", @"value" : @"bar"} ]
      }
    ]
  };
  XCTAssertThrows(
      [[ABRegistry sharedRegistry] loadConfigFromDictionary:config]);
}

- (void)testRandom {
  [self loadConfigFile:@"testdata.json"];
  NSNumber *val = [self.registry flagValueWithName:@"always_passes"];
  XCTAssertTrue(val.boolValue);
  val = [self.registry flagValueWithName:@"always_fails"];
  XCTAssertFalse(val.boolValue);
}

- (void)testModRange {
  [self loadConfigFile:@"testdata.json"];
  NSNumber *val = [self.registry flagValueWithName:@"mod_range"
                                           context:@{
                                             @"user_id" : @0
                                           }];
  XCTAssertTrue(val.boolValue);
  val = [self.registry flagValueWithName:@"mod_range"
                                 context:@{
                                   @"user_id" : @3
                                 }];
  XCTAssertTrue(val.boolValue);
  val = [self.registry flagValueWithName:@"mod_range"
                                 context:@{
                                   @"user_id" : @9
                                 }];
  XCTAssertTrue(val.boolValue);
  val = [self.registry flagValueWithName:@"mod_range"
                                 context:@{
                                   @"user_id" : @50
                                 }];
  XCTAssertFalse(val.boolValue);
}

- (void)testOperators {
  [self loadConfigFile:@"testdata.json"];
  NSNumber *val =
      [self.registry flagValueWithName:@"or_result"
                               context:[NSNumber numberWithBool:YES]];
  XCTAssertTrue(val.boolValue);
  val = [self.registry flagValueWithName:@"and_result"
                                 context:[NSNumber numberWithBool:NO]];
  XCTAssertFalse(val.boolValue);
}

- (void)testNoOperators {
  XCTAssertThrowsSpecificNamed(
      [self loadConfigFile:@"broken_nooperator.json"], NSException,
      @"Invalid arguments to Variant initializer",
      @"Cannot have multiple variant conditions without an operator");
}

- (void)testNoCondition {
  XCTAssertThrowsSpecificNamed(
      [self loadConfigFile:@"broken_nocondition.json"], NSException,
      @"Invalid arguments to Variant initializer",
      @"Cannot have a Variant operator without multiple conditions");
}

- (void)testCustomCondition {
  [self.registry
      registerConditionTypeWithId:@"CUSTOM"
                        specBlock:^ABConditionEvaluator(id<NSCopying> value) {
                            return ^BOOL(id<NSCopying> context) {
                                return [((NSDictionary *)context)[@"password"]
                                    isEqualToString:(NSString *)value];
                            };
                        }];
  [self loadConfigFile:@"custom.json"];
  NSNumber *val = [self.registry flagValueWithName:@"custom_value" context:@{}];
  XCTAssertEqual(val.integerValue, 0);
  val = [self.registry flagValueWithName:@"custom_value"
                                 context:@{
                                   @"password" : @"wrong"
                                 }];
  XCTAssertEqual(val.integerValue, 0);
  val = [self.registry flagValueWithName:@"custom_value"
                                 context:@{
                                   @"password" : @"secret"
                                 }];
  XCTAssertEqual(val.integerValue, 42);
}

- (void)testGetFlags {
  [self loadConfigFile:@"testdata.json"];
  NSArray *allFlags = [self.registry allFlags];
  XCTAssertTrue([allFlags containsObject:@"always_passes"]);
  XCTAssertTrue([allFlags containsObject:@"always_fails"]);
  XCTAssertTrue([allFlags containsObject:@"coin_flip"]);
  XCTAssertTrue([allFlags containsObject:@"mod_range"]);
}

- (void)testGetVariants {
  [self loadConfigFile:@"testdata.json"];
  ABVariant *variant;
  for (ABVariant *v in [self.registry allVariants]) {
    if ([v.identifier isEqualToString:@"CoinFlipTest"]) {
      variant = v;
      break;
    }
  }
  XCTAssertNotNil(variant);
}

@end
