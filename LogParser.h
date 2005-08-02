#import <Cocoa/Cocoa.h>
#import "stringExtra.h"

@interface LogParser : NSObject {
	NSString *logFilePath;
	NSString *logContents, * currentString;
	NSRange range, currentRange, nextRange;
	unsigned int currentLineNumber;
	NSCharacterSet *newlineCharacterSet;
	NSCharacterSet *whitespaceCharSet;
	BOOL isNoError;
	BOOL isLabelsChanged;
	BOOL isDviOutput;
	NSMutableArray *errorRecordTree;
	NSArray *texFileExtensions;
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

- (NSMutableDictionary *) findErrors:(id)logTree withEnumerator:(NSEnumerator *)enumerator;

- (void) parseLogTreeFirstLevel:(NSMutableArray *)logTree;

- (void) parseLogTree:(NSMutableArray *) logTree;

- (NSString *) getTargetFilePath:(NSEnumerator *) enumerator;
- (NSString *) checkTexFileExtensions:(NSString *)targetFile;

//accessors
- (void)setLogContents:(NSString *)logText;
- (void)setLogFilePath:(NSString *)path;

@end
