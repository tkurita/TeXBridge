#import "DefaultsForKeyCommand.h"
#import "AppleEventExtra.h"

@implementation DefaultsForKeyCommand

- (id)performDefaultImplementation
{
	/*
	NSLog(@"apple event : %@", [self appleEvent]);
	NSLog(@"direct parameter : %@", [self directParameter]);
	 */
	id result = [[NSUserDefaults standardUserDefaults] objectForKey:[self directParameter]];
	
	return [result appleEventDescriptor];
}

@end
