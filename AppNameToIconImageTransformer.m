
#import "AppNameToIconImageTransformer.h"


@implementation AppNameToIconImageTransformer


+ (Class)transformedValueClass
	{
		return [NSImage class];
	}


+ (BOOL)allowsReverseTransformation
	{
		return NO;
	}


- (id)transformedValue:(id)appName
{
	NSLog(appName);
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	NSString *appPath = [workspace fullPathForApplication:appName];
	if (appPath == nil) {
		NSLog(@"can't find path of following app name");
		NSLog(appName);
		return nil;
	}
	NSImage *iconImage = [workspace iconForFile:appPath];
	if (iconImage == nil) {
		NSLog(@"can't icon of following app name");
		NSLog(appName);
		return nil;
	}
	
	NSArray * repArray = [iconImage representations];
	NSEnumerator *repEnum = [repArray objectEnumerator];
	NSImageRep *imageRep;
	NSSize Size16 = NSMakeSize(16, 16);
	BOOL hasSize16 = NO;
	while (imageRep = [repEnum nextObject]) {
		if (NSEqualSizes([imageRep size],Size16)) {
			hasSize16 = YES;
			break;
		}
	}
	if (hasSize16) {
		[iconImage setScalesWhenResized:NO];
		[iconImage setSize:NSMakeSize(16, 16)];
		NSLog(@"have size 16");
	}
	else {
		//[iconImage setScalesWhenResized:NO];
		[iconImage setSize:NSMakeSize(16, 16)];
		NSLog(@"not have size 16");
	}
	
	return iconImage;
}

@end
