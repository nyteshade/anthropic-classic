//
//  NSObject+Associations.h
//  anthropic-classic
//
//  Created by Brielle Harrison on 10/4/25.
//  Copyright 2025 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSObject (MyAssociations)
- (void)setAssociatedValue:(id)value forKey:(NSString *)key;
- (id)associatedValueForKey:(NSString *)key;
@end
