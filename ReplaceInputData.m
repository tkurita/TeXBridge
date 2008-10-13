#import "ReplaceInputData.h"

static NSDictionary *INTERNAL_REPLACE_DICT = nil;

@implementation ReplaceInputData
+ (void)initialize
{
	NSString *a_file = [[NSBundle mainBundle] pathForResource:@"ReplaceDictionary" ofType:@"plist"];
	INTERNAL_REPLACE_DICT = [NSDictionary dictionaryWithContentsOfFile:a_file];
}
+ (NSDictionary *)internalReplaceDict {
	return INTERNAL_REPLACE_DICT;
}

+ (NSString	*)findTextForKey:(NSString *)aKey
{
	NSString *a_result = nil;
	NSDictionary *user_dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"UserReplaceInputDict"];
	if (user_dict) {
		a_result = [user_dict objectForKey:aKey];
	}
	
	if (a_result) {
		return a_result;
	}
	
	for (NSString *categoly_name in INTERNAL_REPLACE_DICT) {
		a_result = [[INTERNAL_REPLACE_DICT objectForKey:categoly_name] objectForKey:aKey];
		if (a_result) break;
	}
	return a_result;
}

@end
