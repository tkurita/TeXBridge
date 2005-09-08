//
//  NTYImmutableToMutableArrayOfObjectsTransformer.m
//
//  Created by Uli Zappe on 20.03.04.
//  Copyright 2004 Uli Zappe <uli@ritual.org>. All rights reserved.
//

#import "NTYImmutableToMutableArrayOfObjectsTransformer.h"


@implementation NTYImmutableToMutableArrayOfObjectsTransformer


+ (Class)transformedValueClass
	{
		return [NSMutableArray class];
	}


+ (BOOL)allowsReverseTransformation
	{
		return YES;
	}


- (id)transformedValue:(id)value
	{
		id array, enumerator, object;
		
		if (value == nil) return nil;
		
		array = [NSMutableArray arrayWithCapacity:[value count]];
		enumerator = [value objectEnumerator];

		while (object = [enumerator nextObject]) [array addObject:[[object mutableCopy] autorelease]];
		
		return array;
	}


- (id)reverseTransformedValue:(id)value
	{
		return value;
	}

@end
