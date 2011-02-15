#import <Cocoa/Cocoa.h>
#import "LogWindowItem.h"

@interface FileRecord : NSObject <LogWindowItem>{
	NSString *_targetFile;
	NSArray *errorRecords;
	NSURL *_targetURL;
	AliasHandle aliasHandle;
	NSString *logContents;
	id <LogWindowItem> _parent;
}

-(BOOL) getFSRef:(FSRef *)theRef;
+ (id)fileRecordForPath:(NSString*)path errorRecords:(NSArray *)array parent:(id <LogWindowItem>)parent;
+ (id)fileRecordForPath: (NSString*)path errorRecords:(NSArray *)array;
-(void) setLogContents:(NSString *)string;
-(BOOL) setBaseURL:(NSURL *)baseURL;

#pragma mark accesor methods
- (NSString *)logContents;
- (void)setErrorRecords:(NSArray *)array;
- (void)setLogContents:(NSString *)string;
- (void)setTargetFile: (NSString *)path;
- (void)setParent:(id <LogWindowItem>)parent;
@end
