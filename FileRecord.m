#import "FileRecord.h"
#import "ErrorRecord.h"
#import "PathExtra.h"
#import "miClient.h"

extern id EditorClient;

@implementation FileRecord

#pragma mark initialize and dealloc
-(void) dealloc
{
	[_targetFile release];
	[errorRecords release];
	[_targetURL release];
	[logContents release];
	DisposeHandle((Handle)aliasHandle);
	[super dealloc];
}

+ (id)fileRecordForPath:(NSString*)path errorRecords:(NSArray *)array parent:(id <LogWindowItem>)parent
{
	id newInstance = [[self class] fileRecordForPath:path errorRecords:array];
	[newInstance setParent:parent];
	return newInstance;
}

+ (id)fileRecordForPath:(NSString*)path errorRecords:(NSArray *)array
{
	id newInstance = [[[self class] alloc] init];
	[newInstance setErrorRecords:array];
	[newInstance setTargetFile:path];
	
	return [newInstance autorelease];
}

- (BOOL)setBaseURL:(NSURL *)baseURL
{
	[_targetURL release];
	if ([_targetFile isAbsolutePath]) {
		_targetURL = [[NSURL fileURLWithPath:_targetFile] retain];
		NSString *relPath = [_targetFile relativePathWithBase:[baseURL path]];
		[self setTargetFile: relPath];
	}
	else {
		_targetURL = [[NSURL URLWithString:_targetFile relativeToURL:baseURL] retain];
	}
	
	OSErr theError = noErr;
	FSRef theReference;
	CFURLGetFSRef((CFURLRef)_targetURL, &theReference);
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
- (id)jobRecord
{
	return [_parent jobRecord];
}

-(BOOL) jumpToFile {
	//return NO;
	FSRef fileRef;
	[self getFSRef:&fileRef];
	return [EditorClient jumpToFile:&fileRef paragraph:nil];
}

-(id) child {
	return errorRecords;
}

-(id) comment
{
	return _targetFile;
}

-(id) paragraph
{
	return nil;
}

-(BOOL) hasChild {
	return errorRecords!=nil;
}

#pragma mark accesor methods

- (void)setParent:(id <LogWindowItem>)parent
{
	_parent = parent;
}

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
	[_targetFile release];
	_targetFile = path;
}

@end
