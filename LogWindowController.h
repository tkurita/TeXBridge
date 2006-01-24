/* LogWindowController */

#import <Cocoa/Cocoa.h>

@interface LogWindowController : NSWindowController
{
    IBOutlet id detailText;
    IBOutlet id logOutline;
    IBOutlet id logSplitView;
	
	NSDictionary *rootItem;
	NSMutableArray *rootArray;
}

+ (id)sharedLogManager;
- (void)addLogRecords:(id)logRecords;
- (BOOL)jumpToFile:(id)sender;

#pragma mark accessor methods

- (void)initRootItem;
- (void)setRootArray:(NSMutableArray *)logArray;
- (void)setRootItem:(NSDictionary *)logItem;

@end

