#import "ActivateProcessCommand.h"
#import "NSRunningApplication+SmartActivate.h"

@implementation ActivateProcessCommand
- (id)performDefaultImplementation
{
	BOOL result = NO;
	NSString *identifier = [self directParameter];
    if (!identifier) {
        identifier = [self arguments][@"identifier"];
    }
    if (identifier) {
        result = [NSRunningApplication activateAppOfIdentifier:identifier];
    }
    	
	return [NSAppleEventDescriptor descriptorWithBoolean:result];
}
@end
