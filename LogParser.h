#import <Cocoa/Cocoa.h>
#import "ErrorRecord.h"
#import "StringExtra.h"
#import "LogWindowItem.h"

@interface LogParser : NSObject <LogWindowItem>{
	//setting parameters
	NSString *logFilePath;
	NSString *logContents;
	NSArray *texFileExtensions;
	BOOL isReadFile;
	NSString *_jobName;
	
	//show results
	BOOL isNoError;
	BOOL isLabelsChanged;
	BOOL isDviOutput;	
	
	//internal use
	NSCharacterSet *newlineCharacterSet;
	NSCharacterSet *whitespaceCharSet;	
	unsigned int currentLineNumber;
	NSString *currentString;
	NSRange range, currentRange, nextRange;
	NSMutableArray *errorRecordTree;
	NSURL *_baseURL;
}

//puclic method
- (id)initWithContentsOfFile:(NSString *)path encodingName:(NSString *)aEncName;

- (id) initWithString:(NSString *)targetText;

- (NSMutableArray *) parseLog;

-(BOOL) isLabelsChanged;

//internal use
- (NSString *) skipHeader;

- (NSString *) parseBodyWith:(NSMutableArray *)currentList startText:(NSString *)targetText isWholeLine:(BOOL *)wholeLineFlag;

- (NSString *) parseLines:(NSString *)targetText withList:(NSMutableArray *)currentList;

- (void) parseFooterWith:(NSMutableArray *)currentList startText:(NSString *)targetText;

- (ErrorRecord *)findErrors:(id)logTree withEnumerator:(NSEnumerator *)enumerator;

- (void)parseLogTreeFirstLevel:(NSMutableArray *)logTree;

- (void)parseLogTree:(NSMutableArray *) logTree;

- (NSString *)getTargetFilePath:(NSEnumerator *) enumerator;
- (NSString *)checkTexFileExtensions:(NSString *)targetFile;

#pragma mark accessor methods
-(NSString *) logContents;
-(void) setLogContents:(NSString *)logText;
-(void) setLogFilePath:(NSString *)path;
-(void) setBaseURLWithPath:(NSString *)path;
-(NSMutableArray *) errorRecordTree;
-(BOOL) isDviOutput;
-(BOOL) isNoError;

@end
