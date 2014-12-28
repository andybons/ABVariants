Variants [![Build Status](https://travis-ci.org/andybons/ABVariants.svg?branch=master)](https://travis-ci.org/andybons/ABVariants)
========
Experiments/Mods system for iOS and OS X

Can be used for:
+ A/B testing
+ Experimental features
+ Trusted tester groups
+ Gradual feature rollouts

This README details the Cocoa implementation of Variants. For general background, see [the general README](https://github.com/Medium/variants/).

## Detailed Design

Flag and Variant definitions can be defined in a JSON file that can be loaded by a Registry object that manages the sanity and evaluation of each condition.

Example
```json
{
  "flag_defs": [
    {
      "flag": "ab_test",
      "base_value": false
    }
  ],
  "variants": [
    {
      "id": "FeatureABTest",
      "conditions": [
        {
          "type": "RANDOM",
          "value": 0.5
        }
      ],
      "mods": [
        {
          "flag": "ab_test",
          "value": true
        }
      ]
    }
  ]
}
```

In the above example, a flag called "ab_test" is defined, and behavior surrounding how that flag will be evaluated is defined by the variant definition below it. If the condition defined by the variant is met, then the associated mods will be realized (the flag "ab_test" will evaluate to true). The variant is using the built-in RANDOM condition type that will evaluate its result by checking whether a random number between 0.0 and 1.0 is less than or equal to the given value (0.5 in this case). So, in practice, a call to `[registry flagValueWithName:@"ab_test"]` will return an `NSNumber` with a `boolValue` of `YES` 50% of the time.

But say you don't want to use the built-in condition types...

Another example
```json
{
  "flag_defs": [
    {
      "flag": "enable_new_hotness_feature",
      "base_value": false
    }
  ],
  "variants": [
    {
      "id": "EnableNewHotnessFeature",
      "conditions": [
        {
          "type": "CUSTOM",
          "values": [
            "andybons",
            "pupius",
            "guitardave24"
          ]
        }
      ],
      "mods": [
        {
          "flag": "enable_new_hotness_feature",
          "value": true
        }
      ]
    }
  ]
}
```

Now, there is no built-in condition type called CUSTOM, so when the above config is loaded, the passed `NSError` will be populated. We need to define how a CUSTOM condition should be evaluated _before_ the above config is loaded.

```objective-c
[self.registry registerConditionTypeWithID:@"CUSTOM"
    specBlock:^ABConditionEvaluator(id<NSCopying> value) {
        return ^BOOL(id<NSCopying> context) {
            return [((NSDictionary *)context)[@"password"] isEqualToString:(NSString *)value];
        };
    } error:&error];
```

The above code evaluates the CUSTOM condition by checking to see if the value of the "username" key in the passed in context object is present in the values passed when the variant is constructed. Here are a couple examples of getting the flag value:

```objective-c
NSNumber hasAccess = [[ABRegistry sharedRegistry] flagValueWithName:@"enable_new_hotness_feature"
                                                            context:@{@"username": @"andybons"}];
// hasAccess.boolValue == YES

NSNumber hasAccess = [[ABRegistry sharedRegistry] flagValueWithName:@"enable_new_hotness_feature"
                                                            context:@{@"username": @"tessr"}];
// hasAccess.boolValue == NO
```

Take a look at the unit tests for a working example.

# Using Variants

## CocoaPods

```shell
pod install Variants
```

## Author

[Andrew Bonventre](https://github.com/andybons)

Variants was originally created by [David Byttow](https://github.com/guitardave24) for [Medium](https://github.com/Medium/variants)
