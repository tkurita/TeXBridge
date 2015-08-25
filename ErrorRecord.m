#import "ErrorRecord.h"
#import "FileRecord.h"
#import "miClient.h"

extern id EditorClient;

@implementation ErrorRecord
@synthesize logContents;

- (BOOL)jumpToFile
{
	FSRef fileRef;
	[(FileRecord *)_parent getFSRef:&fileRef];
	return [EditorClient jumpToFile:&fileRef paragraph:paragraph];
}

#pragma mark initilize and dealloc
+(id) errorRecordWithString: (NSString*) errMsg paragraph:(NSNumber *) errpn
{
	id newInstance = [[[self class] alloc] init];
	[newInstance setComment:errMsg];
	[newInstance setParagraph:errpn];
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

-(id) comment
{
	return comment;
}

-(id) paragraph
{
	return paragraph;
}

-(BOOL) hasChild {
	return NO;
}

#pragma mark accesor methods

-(NSRange) textRange
{
	return [textRange rangeValue];
}

-(void) setTextRange:(NSValue *) theRange
{
	textRange = theRange;
}

-(void) setComment:(NSString *)string
{
	comment = string;
}

-(void) setParagraph:(NSNumber *)lineNumber
{
	paragraph = lineNumber;
}

- (void)setParent:(id <LogWindowItem>)parentItem
{
	_parent = parentItem;
}

@end
