#import <Cocoa/Cocoa.h>
#import "LogWindowItem.h"

@interface FileRecord : NSObject <LogWindowItem>

@property NSString *targetFile;
@property NSString *logContents;
@property NSData *bookmarkData;
@property NSURL *targetURL;
@property id <LogWindowItem> parent;
@property (readonly) NSArray *errorRecords;

- (NSURL *)URLResolvingAlias;
+ (id)fileRecordForPath:(NSString*)path errorRecords:(NSArray *)array parent:(id <LogWindowItem>)parent;
+ (id)fileRecordForPath: (NSString*)path errorRecords:(NSArray *)array;
-(BOOL) setBaseURL:(NSURL *)baseURL;
-(void) setErrorRecords:(NSArray *)array;

@end
