#import <Cocoa/Cocoa.h>


@interface FileRecord : NSObject {
	NSString *_targetFile;
	NSArray *errorRecords;
	NSURL *_targetURL;
	AliasHandle aliasHandle;
	NSString *logContents;
}

- (BOOL)getFSRef:(FSRef *)theRef;

+(id) fileRecordForPath: (NSString*)path errorRecords:(NSArray *)array;

-(BOOL) hasChild ;

-(void) setLogContents:(NSString *)string;

-(id) child;

- (id)objectForKey:(NSString *) theKey;

- (BOOL)setBaseURL:(NSURL *)baseURL;

#pragma mark accesor methods

-(NSString *) logContents;

-(void) setErrorRecords:(NSArray *)array;

-(void) setLogContents:(NSString *)string;

-(void) setTargetFile: (NSString *)path;

@end
