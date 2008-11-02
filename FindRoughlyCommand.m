#import "FindRoughlyCommand.h"
#import "miClient.h"

#define useLog 0
@implementation FindRoughlyCommand
- (id)performDefaultImplementation
{
#if useLog
	NSLog(@"FindRoughlyCommand");
	NSLog([[self arguments] description]);
	NSLog([[self directParameter] description]);
	NSLog([[self evaluatedArguments] description]);
	NSLog([[self evaluatedReceivers] description]);
	NSLog(@"with source : %@", [[self arguments] objectForKey:@"withSource"]);
#endif	
	NSString *dvi_path = [[self arguments] objectForKey:@"inDvi"];
	NSString *source_name = [[self arguments] objectForKey:@"withSource"];
	NSNumber *start_pos = [[self arguments] objectForKey:@"startLine"];
	
	NSString *tex_path;
	if (source_name) {
		tex_path = [[dvi_path stringByDeletingLastPathComponent] stringByAppendingPathComponent:source_name];
	} else {
		tex_path = [[dvi_path stringByDeletingPathExtension] stringByAppendingPathExtension:@"tex"];
	}
	
	FSRef ref;
	OSStatus status = FSPathMakeRef((UInt8 *)[tex_path fileSystemRepresentation], &ref, NULL);
	if (status == noErr) {
		id miclient = [[[miClient alloc] init] autorelease];
		[miclient setUseBookmarkBeforeJump:YES];
		[miclient jumpToFile:&ref paragraph:start_pos];
	}
	
	return [super performDefaultImplementation];
}

@end
