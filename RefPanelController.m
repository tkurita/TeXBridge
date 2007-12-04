#import "AppController.h"
#import "RefPanelController.h"
#import "miClient.h"
#import <CoreServices/CoreServices.h>

#define useLog 0

extern id EditorClient;

const ItemCount		kMaxErrors= 10;
const ItemCount		kMaxFeatures= 100;

static NSDictionary *EncodingDict = nil;

@implementation RefPanelController

- (void)pushReloadButton:(NSTimer *)theTimer
{
	if ([[self window] isVisible] && ![self isCollapsed]) {
		[reloadButton performClick:self];
	}
}

- (void)restartReloadTimer
{
	if (isWorkedReloadTimer) {
		[self setReloadTimer];
	}
}

- (void)temporaryStopReloadTimer
{
	if (reloadTimer != nil) {
		[reloadTimer invalidate];
		[reloadTimer release];
		reloadTimer = nil;		
		isWorkedReloadTimer = YES;
	}
	else {
		isWorkedReloadTimer = NO;
	}
}

- (void)setReloadTimer
{
#if useLog
	NSLog(@"setReloadTimer");
#endif
	if (reloadTimer == nil) {
		reloadTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(pushReloadButton:) userInfo:nil repeats:YES];
		[reloadTimer retain];

	} 
	else if (![reloadTimer isValid]) {
		[reloadTimer invalidate];
		[reloadTimer release];
		reloadTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(pushReloadButton:) userInfo:nil repeats:YES];
		[reloadTimer retain];
	}
}

- (IBAction)showWindow:(id)sender
{
	[super showWindow:self];
	[self setReloadTimer];
}

- (void)awakeFromNib
{
	[self setFrameName:@"ReferencePalettePalette"];
	[self setApplicationsFloatingOnFromDefaultName:@"ReferencePaletteApplicationsFloatingOn"];
	[self useFloating];
	[self useWindowCollapse];
	
	if (!EncodingDict) {
		EncodingDict = [[NSDictionary alloc] initWithObjectsAndKeys:
						[NSNumber numberWithInt: NSShiftJISStringEncoding],@"Shift_JIS",
						[NSNumber numberWithInt: NSUTF8StringEncoding],@"UTF-8",
						[NSNumber numberWithInt: NSJapaneseEUCStringEncoding],@"EUC-JP",
						[NSNumber numberWithInt: NSISO2022JPStringEncoding], @"ISO-2022-JP", nil];
	}
}

- (BOOL)windowShouldClose:(id)sender
{

	if (reloadTimer != nil) {
		[reloadTimer invalidate];
		[reloadTimer release];
		reloadTimer = nil;
	}

	[super windowShouldClose:sender];
	
	/* To support AppleScript Studio of MacOS 10.4 */
	[[self window] orderOut:self];
	return NO;
}

NSString *try_encodings(NSData *aData, NSArray *encodings)
{
	NSEnumerator *enumerator = [encodings objectEnumerator];
	NSNumber *encoding_packed;
	NSString *a_string;
	while(encoding_packed = [enumerator nextObject]) {
		a_string = [[[NSString alloc] initWithData:aData 
									encoding:[encoding_packed unsignedIntValue]] autorelease];
		if (a_string) break;
	}
	
	return a_string;	
}

- (NSString *)sniffRead:(NSString *)aPath encodingCandidate:(NSString *)encodingName
{
	NSData *a_data = [[NSFileHandle fileHandleForReadingAtPath:aPath] readDataToEndOfFile];
	if (!encodingName) {
		encodingName = @"UTF-8";
	}
	
	NSNumber *encoding_packed = [EncodingDict objectForKey:encodingName];
	NSStringEncoding an_encoding = [encoding_packed unsignedIntValue];
	
	//an_encoding = NSUTF8StringEncoding;
	NSString *a_string = [[[NSString alloc] initWithData:a_data encoding:an_encoding] autorelease];
	if (!a_string) {
		NSMutableArray *encodings = [[EncodingDict allValues] mutableCopy];
		[encodings removeObject:encoding_packed];
		a_string = try_encodings(a_data, encodings);
	}
	
	return a_string;
	/*
	TextEncoding te_SJIS = CreateTextEncoding(kTextEncodingMacJapanese,
			kMacJapaneseStandardVariant, kTextEncodingDefaultFormat );

	TextEncoding te_JIS = CreateTextEncoding(kTextEncodingISO_2022_JP_2,
			kMacJapaneseStandardVariant, kTextEncodingDefaultFormat );

	TextEncoding te_EUC = CreateTextEncoding(kTextEncodingEUC_JP,
				kTextEncodingDefaultVariant, kTextEncodingDefaultFormat);
				
//	TextEncoding te_UTF8 = CreateTextEncoding(kTextEncodingUnicodeDefault,
//				kTextEncodingDefaultVariant, kUnicodeUTF8Format );

	ItemCount num_encodings = 3;
	TextEncoding text_encodings[3] = {te_SJIS, te_EUC, te_JIS};
//	ItemCount num_encodings = 1;
//	TextEncoding text_encodings[1] = {te_UTF8};

	NSLog([NSString stringWithFormat:@"first sniffed encoding hex %x", text_encodings[0]]);
	NSLog([NSString stringWithFormat:@"first sniffed encoding decimal %u", text_encodings[0]]);

	TECSnifferObjectRef encodingSniffer;

	OSStatus status = TECCreateSniffer(&encodingSniffer,
										text_encodings, num_encodings);
	if (status != noErr ) {
		[NSException raise:@"TECError" format:@"Faile to TECCreateSniffer with %i", status];
	}
	ItemCount *errors= (ItemCount *)malloc(sizeof(ItemCount)*num_encodings);
    ItemCount *features = (ItemCount *)malloc(sizeof(ItemCount)*num_encodings);
	
	status = TECSniffTextEncoding(encodingSniffer,[a_data bytes], [a_data length],
									text_encodings, 4,
									errors,
									kMaxErrors,
									features,
									kMaxFeatures);
	if (status != noErr ) {
		[NSException raise:@"TECError" format:@"Faile to TECSniffTextEncoding with %i", status];
	}

	NSLog([NSString stringWithFormat:@"sfiffed encoding %u", text_encodings[0]]);
	//NSStringEncoding an_encoding = CFStringConvertEncodingToNSStringEncoding(text_encodings[0]);
	NSStringEncoding an_encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF8);
	
	NSLog([NSString stringWithFormat:@"aux encoding %u", an_encoding]);

	if(encodingSniffer) TECDisposeSniffer(encodingSniffer);
    if(errors) free(errors);
    if(features) free(features);

	return [[[NSString alloc] initWithData:a_data encoding:an_encoding] autorelease];
	*/
}
@end

