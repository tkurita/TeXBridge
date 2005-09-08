#import "SettingWindowController.h"

#define useLog 0

@implementation SettingWindowController

- (NSImage *)convertToSize16Image:(NSImage *)iconImage
{
	NSArray * repArray = [iconImage representations];
	NSEnumerator *repEnum = [repArray objectEnumerator];
	NSImageRep *imageRep;
	NSSize Size16 = NSMakeSize(16, 16);
	BOOL hasSize16 = NO;
	while (imageRep = [repEnum nextObject]) {
		if (NSEqualSizes([imageRep size],Size16)) {
			hasSize16 = YES;
			break;
		}
	}
	if (hasSize16) {
		[iconImage setScalesWhenResized:NO];
		[iconImage setSize:NSMakeSize(16, 16)];
#if useLog
		NSLog(@"have size 16");
#endif
	}
	else {
		//[iconImage setScalesWhenResized:NO];
		[iconImage setSize:NSMakeSize(16, 16)];
#if useLog
		NSLog(@"not have size 16");
#endif
	}
	return iconImage;
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if(returnCode == NSCancelButton) {
        return;
    }
    else if(returnCode == NSOKButton) {
		NSEnumerator *appEnumerator = [[sheet filenames] objectEnumerator];
		NSString *appPath;
		NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
		NSArray *appNameList = [[appArrayController arrangedObjects] valueForKey:@"appName"];
		while(appPath = [appEnumerator nextObject]) {
			NSString *appName = nil;
			if ([workspace isFilePackageAtPath:appPath]) {
				NSBundle *appBundle = [NSBundle bundleWithPath:appPath];
				NSDictionary *infoDict = [appBundle infoDictionary];
				appName = [infoDict objectForKey:@"CFBundleName"];
				if (appName == nil) {
					appName = [infoDict objectForKey:@"CFBundleExecutable"];
				}
			}
			
			if (appName == nil) {
				appName = [[appPath lastPathComponent] stringByDeletingPathExtension];
			}
			if (![appNameList containsObject:appName]) {
				NSImage *appIcon = [self convertToSize16Image:[workspace iconForFile:appPath]];
				NSData *iconData = [NSArchiver archivedDataWithRootObject:appIcon];
				[appArrayController addObject:
					[NSMutableDictionary dictionaryWithObjectsAndKeys:appName,@"appName",iconData,@"appIcon",nil]];
				//[appArrayController addObject:
					//[NSMutableDictionary dictionaryWithObjectsAndKeys:appName,@"appName",nil]];
			}
		}
    }
}

- (IBAction)addApp:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	NSArray *fileTypes = [NSArray arrayWithObjects: @"app",NSFileTypeForHFSTypeCode('APPL'), nil];
	
	[openPanel beginSheetForDirectory:nil file:nil types:fileTypes modalForWindow:[self window]
						modalDelegate:self didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
						  contextInfo:nil];
}

- (IBAction)showSettingHelp:(id)sender
{
#if useLog
	NSLog(@"start showSettingHelp");
#endif
	NSString *tabName = [[tabView selectedTabViewItem] identifier];
#if useLog
	NSLog(tabName);
#endif
	NSHelpManager *helpManager = [NSHelpManager sharedHelpManager];
	NSDictionary *theDict = [[NSBundle mainBundle] infoDictionary];
	NSString *bookName = [theDict objectForKey:@"CFBundleHelpBookName"];
	
	[helpManager openHelpAnchor:tabName inBook:bookName];
}

- (void)awakeFromNib
{
	[[self window] center];
	[self setWindowFrameAutosaveName:@"SettingWindow"];
}
@end
