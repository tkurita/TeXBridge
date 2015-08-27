#import "ActivateProcessCommand.h"

@implementation ActivateProcessCommand
- (id)performDefaultImplementation
{
	BOOL result = NO;
	NSString *identifier = [self directParameter];
    if (!identifier) {
        identifier = [[self arguments] objectForKey:@"identifier"];
    }
    if (identifier) {
        result = [[[NSRunningApplication runningApplicationsWithBundleIdentifier:identifier]
                        lastObject] activateWithOptions:NSApplicationActivateIgnoringOtherApps];
    }
    	
	return [NSAppleEventDescriptor descriptorWithBoolean:result];
}
@end
