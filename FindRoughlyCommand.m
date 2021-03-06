#import "FindRoughlyCommand.h"
#import "PathExtra.h"
#import "miClient.h"

#define useLog 0
@implementation FindRoughlyCommand
#if useLog
void showAEDesc(const AppleEvent *ev)
{
	Handle result;
	OSStatus resultStatus;
	resultStatus = AEPrintDescToHandle(ev,&result);
	printf("%s\n",*result);
	DisposeHandle(result);
}
#endif
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
	NSString *dvi_path = [[self arguments][@"inDvi"] path];
	NSString *source_name = [self arguments][@"withSource"];
	NSNumber *start_pos = [self arguments][@"startLine"];

	NSString *tex_path;
	if (source_name) {
		tex_path = [[dvi_path stringByDeletingLastPathComponent] stringByAppendingPathComponent:source_name];
	} else {
		tex_path = [[dvi_path stringByDeletingPathExtension] stringByAppendingPathExtension:@"tex"];
	}
    
	if ([tex_path fileExists]) {
        id miclient = [miClient sharedClient];
        [miclient setUseBookmarkBeforeJump:YES];
        [miclient jumpToFileURL:[NSURL fileURLWithPath:tex_path] paragraph:start_pos];
    } else {
        NSLog(@"Can't find %@", tex_path);
    }
	return @0;
	//return [super performDefaultImplementation];
}

@end
