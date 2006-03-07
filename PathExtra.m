#import "PathExtra.h"
#include <sys/param.h>
#include <unistd.h>;

@implementation NSString (PathExtra)

- (NSString *)relativePathWithBase:(NSString *)inBase {
	if (![inBase hasPrefix:@"/"])		{
		return nil	;
	}
	
	if (![self hasPrefix:@"/"]) {
		return nil;
	}
	
	NSArray *targetComps = [[self stringByStandardizingPath] pathComponents];
	
	NSString *selealizedBase = [inBase stringByStandardizingPath];
	NSArray *baseComps;
	if ([inBase hasSuffix:@"/"]) {
		selealizedBase = [selealizedBase stringByAppendingString:@"/"];
	}
	baseComps = [selealizedBase pathComponents];
	
	NSEnumerator *targetEnum = [targetComps objectEnumerator];
	NSEnumerator *baseEnum = [baseComps objectEnumerator];
	
	NSString *baseElement;
	NSString *targetElement;

	BOOL hasRest = NO;
	BOOL hasTargetRest = YES;
	while( baseElement = [baseEnum nextObject]) {
		if (targetElement = [targetEnum nextObject]) {
			if (![baseElement isEqualToString:targetElement]) {
				hasRest = YES;
				break;
			}
		}
		else {
			hasTargetRest = NO;
			break;
		}
	}
	
	NSMutableArray *resultComps = [NSMutableArray array];
	if (hasRest) {
		while([baseEnum nextObject]) {
			[resultComps addObject:@".."];
		}
	}
	
	[resultComps addObject:targetElement];
	if (hasTargetRest) {
		while(targetElement = [targetEnum nextObject]) {
			[resultComps addObject:targetElement];
		}
	}
	
	return [resultComps componentsJoinedByString:@"/"];
}

@end
