#import "FindRoughlyCommand.h"
#import "miClient.h"

#define useLog 0
@implementation FindRoughlyCommand

void showAEDesc(const AppleEvent *ev)
{
	Handle result;
	OSStatus resultStatus;
	resultStatus = AEPrintDescToHandle(ev,&result);
	printf("%s\n",*result);
	DisposeHandle(result);
}

- (id)performDefaultImplementation
{
#if useLog
	NSLog(@"FindRoughlyCommand");
	showAEDesc([[self appleEvent] aeDesc]);
	showAEDesc([[[self appleEvent] paramDescriptorForKeyword:'At  '] aeDesc]);
	//NSLog([[self appleEvent] description]);
	
	OSErr err;
	DescType typeCode;
	DescType returnedType;
    Size actualSize;
	Size dataSize;
	
	//AppleEvent* ev = [[[self appleEvent] paramDescriptorForKeyword:'At  '] aeDesc];
	AppleEvent* ev = [[self appleEvent] aeDesc];
	AEKeyword theKey = 'At  ';
	err = AESizeOfParam(ev, theKey, &typeCode, &dataSize);
	UInt8 *dataPtr = malloc(dataSize);
	err = AEGetParamPtr (ev, theKey, typeCode, &returnedType, dataPtr, dataSize, &actualSize);
	printf("dataSize : %d\n", dataSize);
	for (int n =0; n < dataSize; n++) {
		printf("%02x", *(dataPtr+n));
	}
	printf("\n");
	CFStringRef outStr = CFStringCreateWithBytes(NULL, dataPtr, dataSize, kCFStringEncodingUnicode, true);
	NSLog(@"outStr %@", (NSString *)outStr);
	
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
	} else {
		NSLog(@"Can't find %@", tex_path);
	}
	
	return [super performDefaultImplementation];
}

@end
