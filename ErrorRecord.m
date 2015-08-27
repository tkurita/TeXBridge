#import "ErrorRecord.h"
#import "FileRecord.h"
#import "miClient.h"

extern id EditorClient;

@implementation ErrorRecord

- (BOOL)jumpToFile
{
    NSURL *url = [(FileRecord *)_parent URLResolvingAlias];
    return [EditorClient jumpToFileURL:url paragraph:_paragraph];
}

#pragma mark initilize and dealloc
+(id) errorRecordWithString: (NSString*) errMsg paragraph:(NSNumber *) errpn
{
	ErrorRecord *newInstance = [[[self class] alloc] init];
	newInstance.comment = errMsg;
	newInstance.paragraph = errpn;
	return newInstance;
}

#pragma mark methods for outlineview
- (id)jobRecord
{
	return [_parent jobRecord];
}

-(id) child {
	return nil;
}


-(BOOL) hasChild {
	return NO;
}

@end
