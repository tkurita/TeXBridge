#import <Cocoa/Cocoa.h>
#import "LogWindowItem.h"

@interface LogWindowController : NSWindowController
{
    IBOutlet id detailText;
    IBOutlet id logOutline;
    IBOutlet id logSplitView;
}
@property NSDictionary *rootItem;
@property NSMutableArray *rootArray;
@property id detailTextOwner;

+ (id)sharedLogManager;
- (void)addLogRecords:(id <LogWindowItem>)logRecords;
- (BOOL)jumpToFile:(id)sender;
-(void) bringToFront;

#pragma mark accessor methods
- (void)initRootItem;

@end

