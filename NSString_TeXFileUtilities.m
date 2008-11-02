#import "NSString_TeXFileUtilities.h"
#import "PathExtra.h"

@implementation NSString (NSString_TeXFileUtilities)

static NSString *DVI_SOURCE_SPECIALS = @"DVISourceSpecials";

- (int)hasSourceSpecials
{
	NSData *data = [self extendedAttributeOfName:DVI_SOURCE_SPECIALS transverseLink:YES error:nil];
	if (!data) {
		return -1;
	}
	return [[NSString stringWithUTF8String:(char *)[data bytes]] intValue];
}

- (BOOL)setHasSourceSpecials:(BOOL)aFlag
{
	NSNumber *a_flag = [NSNumber numberWithBool:aFlag];
	NSData *data = [[a_flag stringValue] dataUsingEncoding:NSUTF8StringEncoding];
	return [self setExtendAttribute:data forName:DVI_SOURCE_SPECIALS
												transverseLink:YES error:nil];
}

@end
