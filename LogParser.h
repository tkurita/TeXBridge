#import <Cocoa/Cocoa.h>
#import "ErrorRecord.h"
#import "StringExtra.h"
#import "LogWindowItem.h"

@interface LogParser : NSObject <LogWindowItem>{	
	//internal use
	BOOL isReadFile;
	NSArray *texFileExtensions;
	NSCharacterSet *newlineCharacterSet;
	NSCharacterSet *whitespaceCharSet;	
	unsigned int currentLineNumber;
	NSRange range, currentRange, nextRange;
}
#pragma mark public
@property NSString *errorMessage;
@property NSString *logContents;
@property NSString *logFilePath;
@property NSURL *baseURL;
@property NSMutableArray *errorRecordTree;
@property NSString *jobName;
@property BOOL isDviOutput;
@property BOOL isNoError;
@property BOOL isLabelsChanged;


- (id)initWithContentsOfFile:(NSString *)path encodingName:(NSString *)aEncName;
- (id) initWithString:(NSString *)targetText;
- (NSMutableArray *) parseLog;
-(void) setBaseURLWithPath:(NSString *)path;
- (void)setupJobName:(NSString *)jobName;

#pragma mark private
@property NSString *currentString;

- (NSString *) skipHeader;
- (NSString *) parseBodyWith:(NSMutableArray *)currentList startText:(NSString *)targetText isWholeLine:(BOOL *)wholeLineFlag;

- (NSString *) parseLines:(NSString *)targetText withList:(NSMutableArray *)currentList;

- (void) parseFooterWith:(NSMutableArray *)currentList startText:(NSString *)targetText;

- (ErrorRecord *)findErrors:(id)logTree withEnumerator:(NSEnumerator *)enumerator;

- (void)parseLogTreeFirstLevel:(NSMutableArray *)logTree;

- (void)parseLogTree:(NSMutableArray *) logTree;

- (NSString *)getTargetFilePath:(NSEnumerator *) enumerator;
- (NSString *)checkTexFileExtensions:(NSString *)targetFile;





@end
