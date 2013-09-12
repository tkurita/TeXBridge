#import "PerformScriptCommand.h"
#import "AppController.h"

@implementation PerformScriptCommand

- (id)performDefaultImplementation
{
	// NSLog(@"%@", [self appleEvent]);
	NSAppleEventDescriptor *desc = [[self arguments] objectForKey:@"withScript"];
	[[[AppController sharedAppController] texBridgeController] performTask:desc];
	return nil;
}

@end
