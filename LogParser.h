#import <Cocoa/Cocoa.h>
#import "ErrorRecord.h"
#import "stringExtra.h"

@interface LogParser : NSObject {
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
- (id) initWithContentsOfFile:(NSString *)path;

- (id) initWithString:(NSString *)targetText;

- (NSMutableArray *) parseLog;

- (BOOL) isDviOutput;

-(BOOL) isLabelsChanged;

//internal use
- (NSString *) skipHeader;

- (NSString *) parseBodyWith:(NSMutableArray *)currentList startText:(NSString *)targetText isWholeLine:(BOOL *)wholeLineFlag;

- (NSString *) parseLines:(NSString *)targetText withList:(NSMutableArray *)currentList;

- (void) parseFooterWith:(NSMutableArray *)currentList startText:(NSString *)targetText;

- (ErrorRecord *) findErrors:(id)logTree withEnumerator:(NSEnumerator *)enumerator;

- (void) parseLogTreeFirstLevel:(NSMutableArray *)logTree;

- (void) parseLogTree:(NSMutableArray *) logTree;

- (NSString *) getTargetFilePath:(NSEnumerator *) enumerator;
- (NSString *) checkTexFileExtensions:(NSString *)targetFile;

#pragma mark methos for outlineview
-(id)child;

-(id) objectForKey:(NSString *)theKey;

-(BOOL)hasChild;

#pragma mark accessor methods
- (NSString *)logContents;

- (void)setLogContents:(NSString *)logText;

- (void)setLogFilePath:(NSString *)path;

- (void)setBaseURLWithPath:(NSString *)path;

- (NSMutableArray *)errorRecordTree;

@end
