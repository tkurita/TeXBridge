#import "FileRecord.h"
#import "ErrorRecord.h"
#import "PathExtra.h"
#import "miClient.h"

extern id EditorClient;

@implementation FileRecord

@synthesize logContents;

#pragma mark initialize and dealloc
-(void) dealloc
{
	DisposeHandle((Handle)aliasHandle);
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
	
	return newInstance;
}

- (BOOL)setBaseURL:(NSURL *)baseURL
{
	if ([_targetFile isAbsolutePath]) {
		_targetURL = [NSURL fileURLWithPath:_targetFile];
		NSString *relPath = [_targetFile relativePathWithBase:[baseURL path]];
		[self setTargetFile: relPath];
	}
	else {
		_targetURL = [NSURL URLWithString:_targetFile relativeToURL:baseURL];
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
	errorRecords = array;
	
	NSEnumerator *enumerator = [array objectEnumerator];
	id object;
	while (object = [enumerator nextObject]) {
		[object setParent:self];
	}
	
}

-(void) setTargetFile: (NSString *)path
{
	_targetFile = path;
}

@end
