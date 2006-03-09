#import <Cocoa/Cocoa.h>
#import "LogWindowItem.h"

@interface ErrorRecord : NSObject <LogWindowItem> {
	NSString *logContents;
	NSString *comment;
	NSNumber *paragraph;
	NSValue *textRange;
	id _parent;
}

-(BOOL) jumpToFile;

+(id) errorRecordWithString: (NSString*) errMsg paragraph:(NSNumber *) errpn;

-(BOOL) hasChild;

-(id) child;

#pragma mark accesor methods

-(void) setTextRange:(NSValue *) theRange;

-(NSRange) textRange;

-(NSString *) logContents;

-(void) setLogContents:(NSString *)string;

-(void) setComment:(NSString *)string;
-(id) comment;

-(void) setParagraph:(NSNumber *)lineNumber;
-(id) paragraph;

-(void)setParent:(id)parentItem;

@end
