#import "ErrorRecord.h"
#import "FileRecord.h"
#import "EditorClient.h"

@implementation ErrorRecord

- (BOOL)jumpToFile
{
	FSRef fileRef;
	[_parent getFSRef:&fileRef];
	return [EditorClient jumpToFile:&fileRef paragraph:paragraph];
}

#pragma mark initilize and dealloc
-(void) dealloc
{
	[logContents release];
	[comment release];
	[paragraph release];
	[_parent release];
	[super dealloc];
}


+(id) errorRecordWithString: (NSString*) errMsg paragraph:(NSNumber *) errpn
{
	id newInstance = [[[self class] alloc] init];
	[newInstance setComment:errMsg];
	[newInstance setParagraph:errpn];
	return [newInstance autorelease];
}

#pragma mark methods for outlineview
-(id) child {
	return nil;
}

-(id) objectForKey:(NSString *) theKey
{
	id result = nil;
	
	if ([theKey isEqualToString:@"first"]) {
		result = comment;
	}

	if ([theKey isEqualToString:@"paragraph"]) {
		result = paragraph;
	}
	
	return result;
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
	[theRange retain];
	[textRange release];
	textRange = theRange;
}

-(NSString *) logContents
{
	return logContents;
}

-(void) setLogContents:(NSString *)string
{
	[string retain];
	[logContents release];
	logContents = string;
}

-(void) setComment:(NSString *)string
{
	[string retain];
	[comment release];
	comment = string;
}

-(void) setParagraph:(NSNumber *)lineNumber
{
	[lineNumber retain];
	[paragraph release];
	paragraph = lineNumber;
}

- (void)setParent:(id)parentItem
{
	[parentItem retain];
	[_parent release];
	_parent = parentItem;
}

@end
