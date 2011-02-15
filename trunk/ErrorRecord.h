#import <Cocoa/Cocoa.h>
#import "LogWindowItem.h"

@interface ErrorRecord : NSObject <LogWindowItem> {
	NSString *logContents;
	NSString *comment;
	NSNumber *paragraph;
	NSValue *textRange;
	id <LogWindowItem> _parent;
}

+(id) errorRecordWithString: (NSString*) errMsg paragraph:(NSNumber *) errpn;

#pragma mark accesor methods

-(void) setTextRange:(NSValue *) theRange;

-(NSRange) textRange;

-(NSString *) logContents;

-(void) setLogContents:(NSString *)string;

-(void) setComment:(NSString *)string;
-(id) comment;

-(void) setParagraph:(NSNumber *)lineNumber;
-(id) paragraph;

- (void)setParent:(id <LogWindowItem>)parent;

@end
