#import "SettingWindowController.h"
#import "Terminal.h"
#import "AppController.h"
#import "DefaultToNilTransformer.h"
#import "ReplaceInputData.h"

#define useLog 0

@implementation SettingWindowController

+ (void)initialize
{	
	DefaultToNilTransformer *transformer = [[DefaultToNilTransformer alloc] init];
	[transformer setNilWord:@"Default"];
	[NSValueTransformer setValueTransformer:transformer forName:@"DefaultToNil"];
}


#pragma mark binding

- (NSMutableArray *)arrangedInternalReplaceInputDict
{
	if (_arrangedInternalReplaceInputDict_) {
		return _arrangedInternalReplaceInputDict_;
	}
	
	NSDictionary *a_dict = [ReplaceInputData internalReplaceDict];
	self.arrangedInternalReplaceInputDict_ = [NSMutableArray array];
	for (id category_name in a_dict ) {
		id replace_dict = a_dict[category_name];
		NSMutableArray *replace_array = [NSMutableArray array];
		for (id keytext in replace_dict) {
			[replace_array addObject:@{@"key": keytext,
									  @"value": replace_dict[keytext]}];
		}
		NSString *localized_category_name = NSLocalizedString(category_name, nil);
		[_arrangedInternalReplaceInputDict_ addObject:
			@{@"key": localized_category_name,
				@"children": replace_array}];
	}
	return _arrangedInternalReplaceInputDict_;
}

#pragma mark actions
/*
- (IBAction)setMiClient:(id)sender
{
	//NSString *miclient_path = [[NSBundle mainBundle] pathForResource:@"miclient" ofType:nil];
	NSString *mi_path = [[NSWorkspace sharedWorkspace] 
							absolutePathForAppBundleWithIdentifier:@"net.mimikaki.mi"];
	NSString *editor_setting = [NSString stringWithFormat:@"open %@ -n --args '%%f' +%%l",
								mi_path];
	[self setMxdviEditor:editor_setting];
}
*/

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

- (void)appChooserDidEnd:(NSOpenPanel *)openPanel withResult:(NSUInteger)result
{
	if(result == NSFileHandlingPanelCancelButton) {
        return;
    }
    else if(result == NSFileHandlingPanelOKButton) {
		NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
		NSArray *app_name_list = [[appArrayController arrangedObjects] valueForKey:@"appName"];
		NSArray *identifier_list = [[appArrayController arrangedObjects] valueForKey:@"identifier"];
		
        for (NSURL *app_url in [openPanel URLs]) {
            NSString *app_path = [app_url path];
			NSString *app_name = nil;
			NSString *app_identifier = nil;
			if ([workspace isFilePackageAtPath:app_path]) {
				NSBundle *appBundle = [NSBundle bundleWithPath:app_path];
				NSDictionary *loc_info_dict = [appBundle localizedInfoDictionary];
				NSDictionary *info_dict = [appBundle infoDictionary];
				app_name = loc_info_dict[@"CFBundleName"];
				if (app_name == nil)
					app_name = info_dict[@"CFBundleName"];
				if (app_name == nil)
					app_name = info_dict[@"CFBundleExecutable"];
				
				app_identifier = info_dict[@"CFBundleIdentifier"];
			}
			
			if (app_name == nil)
				app_name = [[app_path lastPathComponent] stringByDeletingPathExtension];
			
			if ((app_identifier != nil) && ([identifier_list containsObject:app_identifier]))
				return;
			
			if (![app_name_list containsObject:app_name]) {
				NSImage *app_icon = [self convertToSize16Image:[workspace iconForFile:app_path]];
				NSData *icon_data = [NSArchiver archivedDataWithRootObject:app_icon];
				NSMutableDictionary *new_entry = [NSMutableDictionary dictionaryWithCapacity:3];
				new_entry[@"appName"] = app_name;
				new_entry[@"appIcon"] = icon_data;
				if (app_identifier != nil) new_entry[@"identifier"] = app_identifier;
				[appArrayController addObject:new_entry];
			}
		}
    }
}

- (IBAction)addApp:(id)sender
{
	NSOpenPanel *open_panel = [NSOpenPanel openPanel];
	NSArray *fileTypes = @[@"app",NSFileTypeForHFSTypeCode('APPL')];
	[open_panel setAllowedFileTypes:fileTypes];
    [open_panel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        [self appChooserDidEnd:open_panel withResult:result];
    }];
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
	NSString *book_name = info_dict[@"CFBundleHelpBookName"];
	if (book_name == nil)
		book_name = [main_bundle infoDictionary][@"CFBundleHelpBookName"];
	
	[help_manager openHelpAnchor:tab_name inBook:book_name];
}

- (IBAction)reloadSettingsMenu:(id)sender
{
	TerminalApplication *termapp = [SBApplication applicationWithBundleIdentifier:@"com.apple.Terminal"];
	NSArray *names = [[termapp settingsSets] arrayByApplyingSelector:@selector(name)];
	names = [names sortedArrayUsingSelector:@selector(localizedCompare:)];
	
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
		[app_controller revertToFactoryDefaultForKey:@"ActivateTerminal"];
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SettingsSetName"];
	}
	else if ([identifier isEqualToString:@"TeXCommands"]) {
		[app_controller revertToFactoryDefaultForKey:@"typesetCommand"];
		[app_controller revertToFactoryDefaultForKey:@"dvipdfCommand"];
		[app_controller revertToFactoryDefaultForKey:@"dvipsCommand"];
		[app_controller revertToFactoryDefaultForKey:@"ebbCommand"];
		[app_controller revertToFactoryDefaultForKey:@"bibtexCommand"];
		[app_controller revertToFactoryDefaultForKey:@"mendexCommand"];
	}
	else if ([identifier isEqualToString:@"PreviewSettings"]) {
		[app_controller revertToFactoryDefaultForKey:@"dviViewCommand"];
		[app_controller revertToFactoryDefaultForKey:@"DVIPreviewMode"];
        [app_controller revertToFactoryDefaultForKey:@"DVIPreviewCommand"];
		[app_controller revertToFactoryDefaultForKey:@"PDFPreviewMode"];
        [app_controller revertToFactoryDefaultForKey:@"PDFPreviewCommand"];
	}
	else if ([identifier isEqualToString:@"TheOtherSettings"]) {
		[app_controller revertToFactoryDefaultForKey:@"AutoMultiTypeset"];
		[app_controller revertToFactoryDefaultForKey:@"ShowToolPaletteWhenLaunched"];
		[app_controller revertToFactoryDefaultForKey:@"ShowRefPaletteWhenLaunched"];
		[app_controller revertToFactoryDefaultForKey:@"ToolPaletteApplicationsFloatingOn"];
	}
}

- (IBAction)changeDVIPreviewer:(id)sender
{
	[[[AppController sharedAppController] texBridgeController] changeDVIPreviewer:sender];
}

- (IBAction)changePDFPreviewer:(id)sender
{
	[[[AppController sharedAppController] texBridgeController] changePDFPreviewer:sender];
}

#pragma mark delegate methods
- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	if ([[tabViewItem identifier] isEqualToString:@"TerminalSettings"]) {
		[self reloadSettingsMenu:self];
	}
}

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView
{
	id current_item= [[userRIDictController selectedObjects] lastObject];
	if (!current_item) return YES;
	NSString *msg = nil;
	if (![current_item value]) {
		msg = NSLocalizedString(@"replaceIsBlank", nil);
	}
	else if (![current_item key] ) {
		msg = NSLocalizedString(@"keywordiIsBlank", nil);
	}
	
	if (msg) {
		NSAlert *alert = [NSAlert alertWithMessageText:msg 
										 defaultButton:@"OK" alternateButton:nil otherButton:nil
							 informativeTextWithFormat:@""];
		[alert setAlertStyle: NSWarningAlertStyle];
		[alert beginSheetModalForWindow:[self window] modalDelegate:nil
						 didEndSelector:nil contextInfo:nil];
		return NO;
	}
	return YES;
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
