//
//  NSObject+Associations.m
//  anthropic-classic
//
//  Created by Brielle Harrison on 10/4/25.
//  Copyright 2025 __MyCompanyName__. All rights reserved.
//

#import "NSObject+Associations.h"

@implementation NSObject (MyAssociations)

static NSMutableDictionary *_associationMap = nil;

+ (void)initialize {
	if (self == [NSObject class]) {
		_associationMap = [[NSMutableDictionary alloc] init];
	}
}

- (NSMutableDictionary *)_associationDictionary {
	@synchronized(_associationMap) {
		NSValue *key = [NSValue valueWithPointer:self];
		NSMutableDictionary *dict = [_associationMap objectForKey:key];
		if (!dict) {
			dict = [NSMutableDictionary dictionary];
			[_associationMap setObject:dict forKey:key];
		}
		return dict;
	}
}

- (void)setAssociatedValue:(id)value forKey:(NSString *)key {
	@synchronized(_associationMap) {
		NSMutableDictionary *dict = [self _associationDictionary];
		if (value) {
			[dict setObject:value forKey:key];
		} else {
			[dict removeObjectForKey:key];
			// Clean up if empty
			if ([dict count] == 0) {
				NSValue *ptrKey = [NSValue valueWithPointer:self];
				[_associationMap removeObjectForKey:ptrKey];
			}
		}
	}
}

- (id)associatedValueForKey:(NSString *)key {
	@synchronized(_associationMap) {
		NSValue *ptrKey = [NSValue valueWithPointer:self];
		NSMutableDictionary *dict = [_associationMap objectForKey:ptrKey];
		return [dict objectForKey:key];
	}
}

@end
