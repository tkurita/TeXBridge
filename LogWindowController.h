#import <Cocoa/Cocoa.h>
#import "LogWindowItem.h"

@interface LogWindowController : NSWindowController
{
    IBOutlet id detailText;
    IBOutlet id logOutline;
    IBOutlet id logSplitView;
	
	NSDictionary *rootItem;
	NSMutableArray *rootArray;
}

+ (id)sharedLogManager;
- (void)addLogRecords:(id <LogWindowItem>)logRecords;
- (BOOL)jumpToFile:(id)sender;
-(void) bringToFront;

#pragma mark accessor methods

- (void)initRootItem;
- (void)setRootArray:(NSMutableArray *)logArray;
- (void)setRootItem:(NSDictionary *)logItem;

@end

