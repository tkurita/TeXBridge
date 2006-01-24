#import "FileRecord.h"
#import "ErrorRecord.h"
//#include <CoreFoundation/CoreFoundation.h>

@implementation FileRecord

#pragma mark initialize and dealloc
-(void) dealloc
{
	[targetFile release];
	[errorRecords release];
	[targetURL release];
	[logContents release];
	DisposeHandle((Handle)aliasHandle);
	[super dealloc];
}

+ (id)fileRecordForPath: (NSString*)path errorRecords:(NSArray *)array
{
	id newInstance = [[[self class] alloc] init];
	[newInstance setTargetFile:path];
	[newInstance setErrorRecords:array];
	return [newInstance autorelease];
}

- (BOOL)setBaseURL:(NSURL *)baseURL
{
	[targetURL release];
	targetURL = [[NSURL URLWithString:targetFile relativeToURL:baseURL] retain];
	
	OSErr theError = noErr;
	FSRef theReference;
	CFURLGetFSRef((CFURLRef)targetURL, &theReference);
	theError = FSNewAliasMinimal( &theReference, &aliasHandle );
	
	return theError == noErr;
}

- (BOOL)getFSRef:(FSRef *)theRef
{
	OSErr theError = noErr;
	Boolean wasChanged;
	
	theError = FSResolveAlias(NULL, aliasHandle, theRef, &wasChanged);
	return theError == noErr;
}

#pragma mark medhots for outlineview
-(id) child {
	return errorRecords;
}

-(id) objectForKey:(NSString *) theKey
{
	id result = nil;
	if ([theKey isEqualToString:@"first"]) {
		result = targetFile;
	}
	
	if ([theKey isEqualToString:@"paragraph"]) {
		result = nil;
	}
	
	return result;
}

-(BOOL) hasChild {
	return errorRecords!=nil;
}

#pragma mark accesor methods

-(void) setErrorRecords:(NSArray *)array
{
	[array retain];
	[errorRecords release];
	errorRecords = array;
	
	NSEnumerator *enumerator = [array objectEnumerator];
	id object;
	while (object = [enumerator nextObject]) {
		[object setParent:self];
	}
	
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

-(void) setTargetFile: (NSString *)path
{
	[path retain];
	[targetFile release];
	targetFile = path;
}

@end
