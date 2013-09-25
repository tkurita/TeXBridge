#import "ActivateProcessCommand.h"
#import "SmartActivate.h"

@implementation ActivateProcessCommand
- (id)performDefaultImplementation
{
	BOOL result = NO;
	NSString *identifier = [self directParameter];
	if (identifier) {
		result = [SmartActivate activateAppOfIdentifier:identifier];
		goto bail;
	}
	identifier = [[self arguments] objectForKey:@"identifier"];
	if (identifier) {
		result = [SmartActivate activateAppOfIdentifier:identifier];
	}
bail:	
	return [NSAppleEventDescriptor descriptorWithBoolean:result];
}
@end
