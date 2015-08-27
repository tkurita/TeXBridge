#import "FileRecord.h"
#import "ErrorRecord.h"
#import "PathExtra.h"
#import "miClient.h"

extern id EditorClient;

@implementation FileRecord

#pragma mark initialize and dealloc
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
		self.targetURL = [NSURL fileURLWithPath:_targetFile];
		NSString *relPath = [_targetFile relativePathWithBase:[baseURL path]];
		[self setTargetFile: relPath];
	}
	else {
		_targetURL = [NSURL URLWithString:_targetFile relativeToURL:baseURL];
	}
	
    CFErrorRef error = NULL;
    self.bookmarkData =  CFBridgingRelease(CFURLCreateBookmarkData(kCFAllocatorDefault,
                                       (__bridge CFURLRef)_targetURL,
                                       0, NULL, NULL, &error));
    if (error) {
        NSLog(@"Failed to CFURLCreateBookmarkDataFromFile: %@", (__bridge NSError *)error);
        [NSApp presentError: (__bridge NSError *)error];
        CFRelease(error);
        return NO;
    }
    return YES;
}

- (NSURL *)URLResolvingAlias
{
    Boolean isState;
    CFErrorRef error = NULL;
    CFURLRef url = CFURLCreateByResolvingBookmarkData (kCFAllocatorDefault,
                                                      (__bridge CFDataRef)_bookmarkData,
                                                       0, NULL, NULL, &isState, &error);
    if (error) {
        NSLog(@"Failed to CFURLCreateByResolvingBookmarkData: %@", (__bridge NSError *)error);
        [NSApp presentError: (__bridge NSError *)error];
        CFRelease(error);
        return nil;
    }
    return CFBridgingRelease(url);
}

#pragma mark medhots for outlineview
- (id)jobRecord
{
	return [_parent jobRecord];
}

-(BOOL) jumpToFile
{
	return [EditorClient jumpToFileURL:_targetURL paragraph:nil];
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
