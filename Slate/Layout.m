//
//  Layout.m
//  Slate
//
//  Created by Jigish Patel on 6/13/11.
//  Copyright 2011 Jigish Patel. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see http://www.gnu.org/licenses

#import "ApplicationOptions.h"
#import "Constants.h"
#import "Layout.h"
#import "Operation.h"
#import "StringTokenizer.h"
#import "SlateLogger.h"

@implementation Layout

@synthesize name;
@synthesize appStates;
@synthesize appOptions;
@synthesize appOrder;
@synthesize before, after;

- (id)init {
  self = [super init];
  if (self) {
    appStates = [NSMutableDictionary dictionary];
    appOptions = [NSMutableDictionary dictionary];
    appOrder = [NSMutableArray array];
    before = [NSMutableArray array];
    after = [NSMutableArray array];
  }
  return self;
}

- (id)initWithString:(NSString *)layout {
  self = [self init];
  if (self) {
    [self addWithString:layout];
  }
  return self;
}

- (id)initWithName:(NSString *)_name dict:(NSDictionary *)dict {
  self = [self init];
  if (self) {
    if (_name == nil) { return nil; }
    [self setName:_name];
    for (NSString *appName in [dict allKeys]) {
      id appDict = [dict objectForKey:appName];
      if (appDict == nil || ![appDict isKindOfClass:[NSDictionary class]]) continue;
      id _ops = [appDict objectForKey:OPT_OPERATIONS];
      if (_ops == nil) continue;
      NSMutableArray *ops = nil;
      if ([_ops isKindOfClass:[NSArray class]]) ops = [_ops mutableCopy];
      else ops = [NSMutableArray arrayWithObject:_ops];
      if (ops == nil || ![ops isKindOfClass:[NSArray class]]) continue;
      if ([OPT_BEFORE isEqualToString:appName]) {
        [self setBefore:ops];
      } else if ([OPT_AFTER isEqualToString:appName]) {
        [self setAfter:ops];
      } else {
        [[self appOrder] addObject:appName];
        [[self appStates] setObject:ops forKey:appName];
        ApplicationOptions *appOpts = [[ApplicationOptions alloc] init];
        if ([appDict objectForKey:OPT_IGNORE_FAIL] != nil && [[appDict objectForKey:OPT_IGNORE_FAIL] boolValue]) {
          [appOpts setIgnoreFail:YES];
        }
        if ([appDict objectForKey:OPT_REPEAT] != nil && [[appDict objectForKey:OPT_REPEAT] boolValue]) {
          [appOpts setRepeat:YES];
        }
        if ([appDict objectForKey:OPT_REPEAT_LAST] != nil && [[appDict objectForKey:OPT_REPEAT_LAST] boolValue]) {
          [appOpts setRepeatLast:YES];
        }
        if ([appDict objectForKey:OPT_MAIN_FIRST] != nil && [[appDict objectForKey:OPT_MAIN_FIRST] boolValue]) {
          [appOpts setMainFirst:YES];
        }
        if ([appDict objectForKey:OPT_MAIN_LAST] != nil && [[appDict objectForKey:OPT_MAIN_LAST] boolValue]) {
          [appOpts setMainLast:YES];
        }
        if ([appDict objectForKey:OPT_SORT_TITLE] != nil && [[appDict objectForKey:OPT_SORT_TITLE] boolValue]) {
          [appOpts setSortTitle:YES];
        }
        if ([appDict objectForKey:OPT_TITLE_ORDER] != nil && [[appDict objectForKey:OPT_TITLE_ORDER] isKindOfClass:[NSArray class]]) {
          [appOpts setTitleOrder:[appDict objectForKey:OPT_TITLE_ORDER]];
        }
        if ([appDict objectForKey:OPT_TITLE_ORDER_REGEX] != nil && [[appDict objectForKey:OPT_TITLE_ORDER_REGEX] isKindOfClass:[NSArray class]]) {
          [appOpts setTitleOrderRegex:[appDict objectForKey:OPT_TITLE_ORDER_REGEX]];
        }
        [appOptions setObject:appOpts forKey:appName];
      }
    }
  }
  return self;
}

- (void)addWithString:(NSString *)layout {
  // layout <name> <app name> <op+params> (| <op+params>)*
  NSMutableArray *tokens = [[NSMutableArray alloc] initWithCapacity:10];
  [StringTokenizer tokenize:layout into:tokens maxTokens:4 quoteChars:[NSCharacterSet characterSetWithCharactersInString:QUOTES]];
  if ([tokens count] <=3) {
    @throw([NSException exceptionWithName:@"Unrecognized Layout" reason:layout userInfo:nil]);
  }

  [self setName:[tokens objectAtIndex:1]];

  NSArray *appNameAndOptions = [[tokens objectAtIndex:2] componentsSeparatedByString:COLON];
  NSString *appName = [appNameAndOptions objectAtIndex:0];
  if ([APP_NAME_BEFORE isEqualToString:appName]) {
    NSString *opsString = [tokens objectAtIndex:3];
    Operation *op = [Operation operationFromString:opsString];
    if (op != nil) {
      [before addObject:op];
    } else {
      SlateLogger(@"ERROR: Invalid Operation in before: '%@'", opsString);
      @throw([NSException exceptionWithName:@"Invalid Operation in before" reason:[NSString stringWithFormat:@"Invalid operation '%@' in chain.", opsString] userInfo:nil]);
    }
  } else if([APP_NAME_AFTER isEqualToString:appName]) {
    NSString *opsString = [tokens objectAtIndex:3];
    Operation *op = [Operation operationFromString:opsString];
    if (op != nil) {
      [after addObject:op];
    } else {
      SlateLogger(@"ERROR: Invalid Operation in after: '%@'", opsString);
      @throw([NSException exceptionWithName:@"Invalid Operation in after" reason:[NSString stringWithFormat:@"Invalid operation '%@' in chain.", opsString] userInfo:nil]);
    }
  } else {
    if ([appOptions objectForKey:appName] != nil) [appOrder removeObject:appName];
    [appOrder addObject:appName];

    if ([appNameAndOptions count] > 1) {
      NSString *options = [appNameAndOptions objectAtIndex:1];
      ApplicationOptions *appOpts = [[ApplicationOptions alloc] init];
      NSArray *optArr = [options componentsSeparatedByString:COMMA];
      for (NSInteger i = 0; i < [optArr count]; i++) {
        NSString *option = [optArr objectAtIndex:i];
        if ([option isEqualToString:IGNORE_FAIL]) {
          [appOpts setIgnoreFail:YES];
        } else if ([option isEqualToString:REPEAT]) {
          [appOpts setRepeat:YES];
        } else if ([option isEqualToString:REPEAT_LAST]) {
          [appOpts setRepeatLast:YES];
        } else if ([option isEqualToString:MAIN_FIRST]) {
          [appOpts setMainFirst:YES];
        } else if ([option isEqualToString:MAIN_LAST]) {
          [appOpts setMainLast:YES];
        } else if ([option isEqualToString:SORT_TITLE]) {
          [appOpts setSortTitle:YES];
        } else if ([option rangeOfString:TITLE_ORDER].length > 0) {
          [appOpts setTitleOrder:[[[option componentsSeparatedByString:EQUALS] objectAtIndex:1] componentsSeparatedByString:SEMICOLON]];
        } else if ([option rangeOfString:TITLE_ORDER_REGEX].length > 0) {
          [appOpts setTitleOrderRegex:[[[option componentsSeparatedByString:EQUALS] objectAtIndex:1] componentsSeparatedByString:SEMICOLON]];
        }
      }
      [appOptions setObject:appOpts forKey:appName];
    } else {
      [appOptions setObject:[[ApplicationOptions alloc] init] forKey:appName];
    }
    NSString *opsString = [tokens objectAtIndex:3];
    NSArray *ops = [opsString componentsSeparatedByString:PIPE_PADDED];
    NSMutableArray *opArray = [[NSMutableArray alloc] initWithCapacity:10];
    for (NSInteger i = 0; i < [ops count]; i++) {
      Operation *op = [Operation operationFromString:[ops objectAtIndex:i]];
      if (op != nil) {
        [opArray addObject:op];
      } else {
        SlateLogger(@"ERROR: Invalid Operation in Chain: '%@'", [ops objectAtIndex:i]);
        @throw([NSException exceptionWithName:@"Invalid Operation in Chain" reason:[NSString stringWithFormat:@"Invalid operation '%@' in chain.", [ops objectAtIndex:i]] userInfo:nil]);
      }
    }

    [[self appStates] setObject:opArray forKey:appName];
  }
}

@end
