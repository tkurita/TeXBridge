#import "ErrorRecord.h"
#import "LogWindowController.h"
#import "LogParser.h"

static id sharedLogManager;

@implementation LogWindowController

-(void) bringToFront
{
	[[self window] orderFront:self];
}

- (void)addLogRecords:(id <LogWindowItem>)logRecords
{
	[rootArray insertObject:logRecords atIndex:0];
	
	if ([rootArray count] > 21) {
		[rootArray removeLastObject];
	}
	
	[logOutline reloadData];
	
	NSEnumerator *enumerator = [rootArray objectEnumerator];
	id object;
	object = [enumerator nextObject];
	while (object = [enumerator nextObject]) {
		[logOutline collapseItem:object];
	}
	[logOutline expandItem:logRecords expandChildren:YES];
	
	[[self window] orderFront:self];
	
}

- (BOOL)jumpToFile:(id)sender
{
	int theRow = [logOutline selectedRow];
	id item = [logOutline itemAtRow:theRow];
	if ([item respondsToSelector:@selector(jumpToFile)]) {
		return [item jumpToFile];
	}
	return NO;
}

#pragma mark initialize and dealloc
- (void)dealloc
{
	[rootItem release];
	[rootArray release];
	[super dealloc];
}

+ (void)initialize
{
	sharedLogManager = nil;
}

+ (id)sharedLogManager
{
	if (sharedLogManager == nil) {
		sharedLogManager = [[self alloc] initWithWindowNibName:@"LogWindow"];
		[sharedLogManager showWindow:self];
	}
	return sharedLogManager;
}

#pragma mark delegate methos for NSWindow
- (BOOL)windowShouldClose:(id)sender
{
	/* To support AppleScript Studio of MacOS 10.4 */
	[[self window] orderOut:self];
	return NO;
}

- (void)awakeFromNib
{
	[[self window] center];
	[self setWindowFrameAutosaveName:@"LogWindow"];
	[self initRootItem];
	[logOutline setDoubleAction:@selector(jumpToFile:)];
}

#pragma mark Outline DataSource
/* itemが子を持つかどうか返します */
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if (!item) {
        //root
		return YES;
    }
	
	return [item hasChild];
}

/* itemの子の数を返します */
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (!item) {
        //root
		return [rootArray count];
    }
    
	return [[item child] count];
	
}

/* itemの、指定したインデックスの子アイテムを返します */
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
    if (!item) {
       return [rootArray objectAtIndex:index];;
    }
    return [[item child] objectAtIndex:index];
}

/* itemから、指定した列の値を返します */
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    id	identifier = [tableColumn identifier];
	
	return [item valueForKey:identifier];
}

#pragma mark delegate for outlineview
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	NSString *logContents = [item logContents];
	if (![[detailText string] isEqual: logContents]) {
		[detailText setString:[item logContents]];
	}

	if ([item respondsToSelector:@selector(textRange)]) {
		[detailText setSelectedRange:[item textRange]];
		[detailText scrollRangeToVisible:[item textRange]];
	}
	return YES;
}

#pragma mark delegate for splitview
- (BOOL)splitView:sender canCollapseSubview:(NSView *)subview
{
	BOOL result = ([subview isEqual:[[detailText superview] superview]]);
	return result;
}

#pragma mark accessor methods

- (void)initRootItem
{
	NSMutableArray *logArray = [NSMutableArray array];
	NSDictionary *logItem = [NSDictionary dictionaryWithObjectsAndKeys:logArray, @"child", nil];
	[self setRootArray:logArray];
	[self setRootItem:logItem];
}

- (void)setRootArray:(NSMutableArray *)logArray
{
	[logArray retain];
	[rootArray release];
	rootArray = logArray;
}

- (void)setRootItem:(NSDictionary *)logItem
{
	[logItem retain];
	[rootItem release];
	rootItem = logItem;
}

@end
