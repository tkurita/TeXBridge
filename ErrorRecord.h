#import <Cocoa/Cocoa.h>


@interface ErrorRecord : NSObject {
	NSString *logContents;
	NSString *comment;
	NSNumber *paragraph;
	NSValue *textRange;
	id _parent;
}

- (BOOL)jumpToFile;

+(id) errorRecordWithString: (NSString*) errMsg paragraph:(NSNumber *) errpn;

-(BOOL) hasChild;

-(id) objectForKey:(NSString *) theKey;

-(id) child;

#pragma mark accesor methods

-(void) setTextRange:(NSValue *) theRange;

-(NSRange) textRange;

-(NSString *) logContents;

-(void) setLogContents:(NSString *)string;

-(void) setComment:(NSString *)string;

-(void) setParagraph:(NSNumber *)lineNumber;

-(void)setParent:(id)parentItem;

@end
