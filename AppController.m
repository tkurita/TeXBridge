#import "AppController.h"
#import "PaletteWindowController.h"
#import "WindowVisibilityController.h"
#import "PathExtra.h"
#import "DonationReminder.h"

#import "NTYImmutableToMutableArrayOfObjectsTransformer.h"

//#import "AppNameToIconImageTransformer.h"

#define useLog 0
id EditorClient;
static id sharedObj;

@implementation AppController

+ (void)initialize	// Early initialization
{	
	NSValueTransformer *transformer = [[[NTYImmutableToMutableArrayOfObjectsTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformer forName:@"NTYImmutableToMutableArrayOfObjects"];
	
	sharedObj = nil;
	/*
	NSValueTransformer *appNameTransformer = [[[AppNameToIconImageTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:appNameTransformer forName:@"AppNameToIconImage"];
	 */
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

#pragma mark delegate of NSApplication
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"start applicationWillFinishLaunching");
#endif
	/*
	NSString *thePath = @"/usr/local/bin/hello";
	NSString *basePath = @"/usr/local/bin/yo/";
	NSArray *pathComps = [basePath pathComponents];
	NSString *relPath = [thePath relativePathWithBase:basePath];
	*/
	
	/* regist FactorySettings into shared user defaults */
	NSString *defaultsPlistPath = [[NSBundle mainBundle] pathForResource:@"FactorySettings" ofType:@"plist"];
	factoryDefaults = [[NSDictionary dictionaryWithContentsOfFile:defaultsPlistPath] retain];
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults registerDefaults:factoryDefaults];
	
	/* checking checking UI Elements Scripting ... */
	if (!AXAPIEnabled())
    {
		[startupWindow close];
		[NSApp activateIgnoringOtherApps:YES];
		int ret = NSRunAlertPanel(NSLocalizedString(@"disableUIScripting", ""), @"", 
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
	EditorClient = [[miClient alloc] init];
	[PaletteWindowController setVisibilityController:[[[WindowVisibilityController alloc] init] autorelease]];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"start applicationDidFinishLaunching");
#endif
	appQuitTimer = [NSTimer scheduledTimerWithTimeInterval:60*60 target:self selector:@selector(checkQuit:) userInfo:nil repeats:YES];
	[appQuitTimer retain];
	
	NSNotificationCenter *notifyCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
	[notifyCenter addObserver:self selector:@selector(anApplicationIsTerminated:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];

	[DonationReminder remindDonation];
}

@end
