#import "AppController.h"
#import "CocoaLib/PaletteWindowController.h"
#import "CocoaLib/PathExtra.h"
#import "CocoaLib/WindowVisibilityController.h"
#import "DonationReminder/DonationReminder.h"
#import "SmartActivate.h"
#import "TeXDocument.h"
#import "NewRefPanelController.h"

#define useLog 0


@interface ASKScriptCache : NSObject
{
}
+ (ASKScriptCache *)sharedScriptCache;
- (OSAScript *)scriptWithName:(NSString *)name;
@end

id EditorClient;
static id sharedObj;

NSArray *orderdEncodingCandidates(NSString *firstCandidateName)
{
	NSMutableArray *encoding_table = [[[NSUserDefaults standardUserDefaults] 
											arrayForKey:@"EncodingTable"] mutableCopy];
	if (firstCandidateName) {
		NSPredicate *a_predicate = [NSPredicate predicateWithFormat:@"name == %@", firstCandidateName];
		NSDictionary *first_candidate = [[encoding_table filteredArrayUsingPredicate:a_predicate] lastObject];
		[encoding_table removeObject:first_candidate];
		[encoding_table insertObject:first_candidate atIndex:0];
	}
	return [encoding_table valueForKey:@"id"];
}

@implementation AppController

+ (void)initialize	// Early initialization
{		
	sharedObj = nil;
}

+ (id)sharedAppController
{
	if (sharedObj == nil) {
		sharedObj = [[self alloc] init];
	}
	return sharedObj;
}

- (id)init
{
	if (self = [super init]) {
		if (sharedObj == nil) {
			sharedObj = self;
		}
	}
	
	return self;
}


- (void)checkQuit:(NSTimer *)aTimer
{
	NSArray *appList = [[NSWorkspace sharedWorkspace] launchedApplications];
	NSEnumerator *enumerator = [appList objectEnumerator];
	
	id appDict;
	BOOL isMiLaunched = NO;
	while (appDict = [enumerator nextObject]) {
		NSString *appName = [appDict objectForKey:@"NSApplicationName"];
		if ([appName isEqualToString:@"mi"] ) {
			isMiLaunched = YES;
			break;
		}
	}
	
	if (! isMiLaunched) {
		[NSApp terminate:self];
	}
}

- (void)anApplicationIsTerminated:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"anApplicationIsTerminated");
#endif
	NSString *appName = [[aNotification userInfo] objectForKey:@"NSApplicationName"];
	if ([appName isEqualToString:@"mi"] ) [NSApp terminate:self];
}

- (void)revertToFactoryDefaultForKey:(NSString *)theKey
{
	id factorySetting = [factoryDefaults objectForKey:theKey];
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:factorySetting forKey:theKey];
}

- (id)factoryDefaultForKey:(NSString *)theKey
{
	return [factoryDefaults objectForKey:theKey];
}

- (int)judgeVisibilityForApp:(NSDictionary *)appDict
{
	/*
	result = -1 : can't judge in this routine
	0 : should hide	
	1: should show
	2: should not change
	*/
	if (! appDict) {
		return kShouldHide;
	}
	
	NSString *app_name = [appDict objectForKey:@"NSApplicationName"];

	if ([app_name isEqualToString:[EditorClient name]]) {
		NSString *theMode;
		@try{
			theMode = [EditorClient currentDocumentMode];
		}
		@catch(NSException *exception){
			#if useLog
			NSLog([exception description]);
			#endif
			 NSNumber *err = [[exception userInfo] objectForKey:@"result code"];
			 if ([err intValue] == -1704) {
				 // maybe menu is opened
				 return kShouldNotChange;
			 }
			 else {
				 // maybe no documents opened
				 return kShouldHide;
			 }	
		 }
		 #if useLog
		 NSLog([NSString stringWithFormat:@"current mode : %@", theMode]);
		 #endif
		 
		 if (!theMode) {
			// may AESendMessage time outed
			return kShouldNotChange;
		 }
		 
		 if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"SupportedModes"]
				containsObject:theMode]) {
			 return kShouldShow;
		 } else {
			 return kShouldHide;
		 }
	 }
	return kShouldPostController;
}

#pragma mark delegate of NSApplication
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"start applicationWillFinishLaunching");
#endif	
	/* regist FactorySettings into shared user defaults */
	NSString *defaultsPlistPath = [[NSBundle mainBundle] pathForResource:@"FactorySettings" 
																  ofType:@"plist"];
	factoryDefaults = [[NSDictionary dictionaryWithContentsOfFile:defaultsPlistPath] retain];
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults registerDefaults:factoryDefaults];
	
	/* checking checking UI Elements Scripting ... */
	if (!AXAPIEnabled())
    {
		[startupWindow close];
		[NSApp activateIgnoringOtherApps:YES];
		int ret = NSRunAlertPanel(NSLocalizedString(@"disableGUIScripting", ""), @"", 
							NSLocalizedString(@"Launch System Preferences", ""),
							NSLocalizedString(@"Cancel",""), @"");
		switch (ret)
        {
            case NSAlertDefaultReturn:
                [[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/UniversalAccessPref.prefPane"];
                break;
			default:
                break;
        }
        
		[NSApp terminate:self];
		return;
    }
	EditorClient = [miClient sharedClient];
	WindowVisibilityController *wvController = [[WindowVisibilityController alloc] init];
	[wvController setDelegate:self];
	[wvController setFocusWatchApplication:@"net.mimikaki.mi"];
	[PaletteWindowController setVisibilityController:[wvController autorelease]];
#if useLog
	NSLog(@"end applicationWillFinishLaunching");
#endif		
}

- (void)showToolPalette
{
	if (!toolPaletteController) {
		toolPaletteController = [[NewToolPaletteController alloc] 
									initWithWindowNibName:@"NewToolPalette"];
	}
	[toolPaletteController showWindow:self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"start applicationDidFinishLaunching");
#endif
	appQuitTimer = [NSTimer scheduledTimerWithTimeInterval:60*60 target:self 
												  selector:@selector(checkQuit:) 
												  userInfo:nil repeats:YES];
	[appQuitTimer retain];
	
	NSNotificationCenter *notifyCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
	[notifyCenter addObserver:self selector:@selector(anApplicationIsTerminated:) 
						 name:NSWorkspaceDidTerminateApplicationNotification object:nil];

	id reminderWindow = [DonationReminder remindDonation];
	if (reminderWindow != nil) [NSApp activateIgnoringOtherApps:YES];
	
	
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	toolPaletteController = nil;
	if ([user_defaults boolForKey:@"ShowToolPaletteWhenLaunched"] 
			||  [user_defaults boolForKey:@"IsOpenedToolPalette"]) {
		[self showToolPalette];
	}

	// Test Code
	/*
	NewRefPanelController *wc = [[NewRefPanelController alloc] initWithWindowNibName:@"NewReferencePalette"];
	[wc showWindow:self];
	 */

#if useLog
	NSLog(@"end applicationDidFinishLaunching");
#endif	
}

- (void)awakeFromNib
{
	script = [[ASKScriptCache sharedScriptCache] scriptWithName:@"TeXBridge"];
}

#pragma mark actions

- (IBAction)showSettingWindow:(id)sender
{
	if (!settingWindow) {
		settingWindow = [[SettingWindowController alloc] initWithWindowNibName:@"Setting"];
	}
	[settingWindow showWindow:self];
	[SmartActivate activateSelf];
}

- (IBAction)quickTypesetPreview:(id)sender
{
	NSDictionary *error_info = nil;
	[script executeHandlerWithName:@"perform_handler"
						 arguments:[NSArray arrayWithObject:@"quick_typeset_preview"]
							 error:&error_info];
}
- (IBAction)dviPreview:(id)sender
{
	NSDictionary *error_info = nil;
	[script executeHandlerWithName:@"perform_handler"
						 arguments:[NSArray arrayWithObject:@"preview_dvi"]
							 error:&error_info];
	
}
- (IBAction)dviToPDF:(id)sender
{
	NSDictionary *error_info = nil;
	[script executeHandlerWithName:@"perform_handler"
						 arguments:[NSArray arrayWithObject:@"dvi_to_pdf"]
							 error:&error_info];
	
}
- (IBAction)typesetPDFPreview:(id)sender
{
	NSDictionary *error_info = nil;
	[script executeHandlerWithName:@"perform_handler"
						 arguments:[NSArray arrayWithObject:@"typeset_preview_pdf"]
							 error:&error_info];
}

- (void)showStatusMessage:(NSString *)msg
{
	if (! toolPaletteController) return;
	if (! [toolPaletteController isOpened]) return;
	if ([toolPaletteController isCollapsed]) return;
	[toolPaletteController showStatusMessage:msg];
}

@end
