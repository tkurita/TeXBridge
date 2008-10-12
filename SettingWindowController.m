#import "SettingWindowController.h"
#import "Terminal.h"
#import "AppController.h"
#import "DefaultToNilTransformer.h"

#define useLog 0

@class ASKScriptCache;
@class ASKScript;

@implementation SettingWindowController

+ (void)initialize
{	
	NSValueTransformer *transformer = [[[DefaultToNilTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformer forName:@"DefaultToNil"];
}

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
		NSEnumerator *enumerator = [[sheet filenames] objectEnumerator];
		NSString *app_path;
		NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
		NSArray *app_name_list = [[appArrayController arrangedObjects] valueForKey:@"appName"];
		NSArray *identifier_list = [[appArrayController arrangedObjects] valueForKey:@"identifier"];
		while(app_path = [enumerator nextObject]) {
			NSString *app_name = nil;
			NSString *app_identifier = nil;
			if ([workspace isFilePackageAtPath:app_path]) {
				NSBundle *appBundle = [NSBundle bundleWithPath:app_path];
				NSDictionary *loc_info_dict = [appBundle localizedInfoDictionary];
				NSDictionary *info_dict = [appBundle infoDictionary];
				app_name = [loc_info_dict objectForKey:@"CFBundleName"];				
				if (app_name == nil)
					app_name = [info_dict objectForKey:@"CFBundleName"];
				if (app_name == nil)
					app_name = [info_dict objectForKey:@"CFBundleExecutable"];
				
				app_identifier = [info_dict objectForKey:@"CFBundleIdentifier"];
			}
			
			if (app_name == nil)
				app_name = [[app_path lastPathComponent] stringByDeletingPathExtension];
			
			if ((app_identifier != nil) && ([identifier_list containsObject:app_identifier]))
				return;
			
			if (![app_name_list containsObject:app_name]) {
				NSImage *app_icon = [self convertToSize16Image:[workspace iconForFile:app_path]];
				NSData *icon_data = [NSArchiver archivedDataWithRootObject:app_icon];
				NSMutableDictionary *new_entry = [NSMutableDictionary dictionaryWithCapacity:3];
				[new_entry setObject:app_name forKey:@"appName"];
				[new_entry setObject:icon_data forKey:@"appIcon"];
				if (app_identifier != nil) [new_entry setObject:app_identifier forKey:@"identifier"];
				[appArrayController addObject:new_entry];
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
	NSString *tab_name = [[tabView selectedTabViewItem] identifier];
#if useLog
	NSLog(tabName);
#endif
	NSHelpManager *help_manager = [NSHelpManager sharedHelpManager];
	NSBundle *main_bundle = [NSBundle mainBundle];
	NSDictionary *info_dict = [main_bundle localizedInfoDictionary];
	NSString *book_name = [info_dict objectForKey:@"CFBundleHelpBookName"];
	if (book_name == nil)
		book_name = [[main_bundle infoDictionary] objectForKey:@"CFBundleHelpBookName"];
	
	[help_manager openHelpAnchor:tab_name inBook:book_name];
}

- (IBAction)reloadSettingsMenu:(id)sender
{
	TerminalApplication *termapp = [SBApplication applicationWithBundleIdentifier:@"com.apple.Terminal"];
	NSArray *names = [[termapp settingsSets] arrayByApplyingSelector:@selector(name)];
	
	NSString *selected_title = [[settingMenu selectedItem] title];
	NSUInteger nitems = [[settingMenu itemArray] count];
	for (int n = nitems-1; n > 1; n--) {
		[settingMenu removeItemAtIndex:n];
	}
	[settingMenu addItemsWithTitles:names];	
	[settingMenu selectItemWithTitle:selected_title];
}

- (IBAction)revertToFactoryDefaults:(id)sender
{
	NSString *identifier = [[tabView selectedTabViewItem] identifier];
	AppController* app_controller = [AppController sharedAppController];
	if ([identifier isEqualToString:@"TerminalSettings"]) {
		[app_controller revertToFactoryDefaultForKey:@"ExecutionString"];
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SettingsSetName"];
	}
	else if ([identifier isEqualToString:@"CommandsAndProcesses"]) {
		[app_controller revertToFactoryDefaultForKey:@"CleanCommands"];
		[app_controller revertToFactoryDefaultForKey:@"ModeDefaults"];
	}
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	//NSLog([tabViewItem identifier]);
	if ([[tabViewItem identifier] isEqualToString:@"TerminalSettings"]) {
		[self reloadSettingsMenu:self];
	} else {
		NSDictionary *errorInfo = nil;
		ASKScript *a_script = [[ASKScriptCache sharedScriptCache] 
							   scriptWithName:@"TeXBridge"];
		[a_script executeHandlerWithName:@"updated_selected_tab_view_item" 
					arguments:nil error:&errorInfo];
	}
}

- (IBAction)showWindow:(id)sender
{
	[super showWindow:sender];
	if ([[[tabView selectedTabViewItem] identifier] isEqualToString:@"TerminalSettings"]) {
		[self reloadSettingsMenu:self];
	}
}

- (BOOL)windowShouldClose:(id)sender
{
	/* To support AppleScript Studio of MacOS 10.4 */
	[[self window] orderOut:self];
	return NO;
}

- (void)awakeFromNib
{
	[[self window] center];
	[self setWindowFrameAutosaveName:@"SettingWindow"];
}
@end
