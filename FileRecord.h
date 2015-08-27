#import <Cocoa/Cocoa.h>
#import "LogWindowItem.h"

@interface FileRecord : NSObject <LogWindowItem>{
	NSArray *errorRecords;
	id <LogWindowItem> _parent;
}
@property (strong) NSString *targetFile;
@property (strong) NSString *logContents;
@property (strong) NSData *bookmarkData;
@property (strong) NSURL *targetURL;

- (NSURL *)URLResolvingAlias;
+ (id)fileRecordForPath:(NSString*)path errorRecords:(NSArray *)array parent:(id <LogWindowItem>)parent;
+ (id)fileRecordForPath: (NSString*)path errorRecords:(NSArray *)array;
-(void) setLogContents:(NSString *)string;
-(BOOL) setBaseURL:(NSURL *)baseURL;

#pragma mark accesor methods
- (void)setErrorRecords:(NSArray *)array;
- (void)setLogContents:(NSString *)string;
- (void)setParent:(id <LogWindowItem>)parent;
@end
