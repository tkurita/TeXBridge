#import <Cocoa/Cocoa.h>
#import "LogWindowItem.h"

@interface ErrorRecord : NSObject <LogWindowItem> {
}
@property (strong) NSString *comment;
@property (strong) NSString *logContents;
@property (strong) NSNumber *paragraph;
@property (strong) NSValue *textRange;
@property (strong) id <LogWindowItem> parent;

+(id) errorRecordWithString: (NSString*) errMsg paragraph:(NSNumber *) errpn;

@end
