#import "TeXDocument.h"
#import "mi.h"
#import "PathExtra.h"

@implementation TeXDocument

@synthesize file;
@synthesize textEncoding;
@synthesize name;
@synthesize pathWithoutSuffix;
@synthesize hasMaster;

static NSArray *SUPPORTED_MODES = nil;

+ (void)initialize
{
	if (! SUPPORTED_MODES) {
		SUPPORTED_MODES = [[NSArray arrayWithObjects:@"TEX", @"TeX", @"LaTeX", nil] retain];
	}
}

+ (TeXDocument *)frontTexDocumentReturningError:(NSError **)error;
{	
	miDocument *front_doc = nil;
	TeXDocument *result = nil;
	miApplication *mi_app = [SBApplication applicationWithBundleIdentifier:@"net.mimikaki.mi"];
	if ([[[mi_app documents] objectAtIndex:0] exists]) {
		front_doc = [[mi_app documents] objectAtIndex:0];
	} else {
		NSString *reason = @"noDocument";
		*error = [NSError errorWithDomain:@"TeXBridgeErrorDomain" code:1240 
								 userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(reason, @"")
																	  forKey:NSLocalizedDescriptionKey]];
		goto bail;
	}
	NSString *mode = [front_doc mode];
	if (! [SUPPORTED_MODES containsObject:mode]) {
		NSString *localized_format = NSLocalizedString(@"The mode setting of '%@' is invalid", @"");
		NSString *reason = [NSString stringWithFormat:localized_format, [front_doc name]];
		*error = [NSError errorWithDomain:@"TeXBridgeErrorDomain" code:1205 
								 userInfo:[NSDictionary dictionaryWithObject:reason
																	  forKey:NSLocalizedDescriptionKey]];
		goto bail;
	}
	
	NSURL *url = [front_doc file];
	
	result = [TeXDocument new];
	if (url) {
		result.file = url;
		NSString *a_path = [url path];
		result.pathWithoutSuffix = [a_path stringByDeletingPathExtension];
		result.name = [a_path lastPathComponent];
	} else {
		result.name = [front_doc name];
	}
	
	result.textEncoding = [front_doc textEncoding];
	
bail:
	return result;
}

+ (TeXDocument *)texDocumentWithPath:(NSString *)pathname textEncoding:(NSString *)encodingName
{
	TeXDocument *tex_doc = [[TeXDocument new] autorelease];
	tex_doc.file = [NSURL fileURLWithPath:pathname];
	tex_doc.textEncoding = encodingName;
	tex_doc.pathWithoutSuffix = [pathname stringByDeletingPathExtension];
	tex_doc.name = [pathname lastPathComponent];
	return tex_doc;
}

- (TeXDocument *)resolveMasterFromEditorReturningError:(NSError **)error
{
	TeXDocument *result = self;
	miApplication *mi_app = [SBApplication applicationWithBundleIdentifier:@"net.mimikaki.mi"];
	miDocument *front_doc = [[mi_app documents] objectAtIndex:0];
	SBElementArray *lines = [front_doc paragraphs];
	NSString *line_content = nil;
	NSString *masterfile_command = @"%ParentFile";
	for (miParagraph *a_line in lines) {
		line_content = [a_line content];
		if (! [line_content hasPrefix:@"%"] ) goto bail;
		if ([line_content hasPrefix:masterfile_command]) break;
	}
	NSUInteger command_len = [masterfile_command length];
	NSUInteger line_length = [line_content length];
	if (line_length <= command_len+1) {
		NSString *localized_format = NSLocalizedString(@"ParentFile '%@' is invalid", @"");
		NSString *reason = [NSString stringWithFormat:localized_format, @""];
		*error = [NSError errorWithDomain:@"TeXBridgeErrorDomain" code:1230
								 userInfo:[NSDictionary dictionaryWithObject:reason
																	  forKey:NSLocalizedDescriptionKey]];
		goto bail;
	}
	
	NSRange range = NSMakeRange(command_len+1, line_length-command_len-2);
	NSString *masterfile_path = [line_content substringWithRange:range];
	masterfile_path = [masterfile_path stringByTrimmingCharactersInSet:
									[NSCharacterSet whitespaceCharacterSet]];
	if (![masterfile_path length]) {
		NSString *localized_format = NSLocalizedString(@"ParentFile '%@' is invalid", @"");
		NSString *reason = [NSString stringWithFormat:localized_format, @""];
		*error = [NSError errorWithDomain:@"TeXBridgeErrorDomain" code:1230
								 userInfo:[NSDictionary dictionaryWithObject:reason
																	  forKey:NSLocalizedDescriptionKey]];
		goto bail;
	}
	
	if ([masterfile_path hasPrefix:@":"]) { //relative HFS path
		NSString *hfs_base_path = [[[file path] stringByDeletingLastPathComponent] hfsPath];
		NSString *hfs_abs_path = [hfs_base_path stringByAppendingString:masterfile_path];
		masterfile_path = [hfs_abs_path posixPath];
		
	} else if (! [masterfile_path hasPrefix:@"/"]) { //relative POSIX Path
		masterfile_path = [[NSURL URLWithString:masterfile_path relativeToURL:file] path];
	}
	
	NSFileManager *fm = [NSFileManager defaultManager];
	if (![fm fileExistsAtPath:masterfile_path]) {
		NSString *localized_format = NSLocalizedString(@"ParentFile '%@' is not Found", @"");
		NSString *reason = [NSString stringWithFormat:localized_format, masterfile_path];
		*error = [NSError errorWithDomain:@"TeXBridgeErrorDomain" code:1220
								 userInfo:[NSDictionary dictionaryWithObject:reason
																	 forKey:NSLocalizedDescriptionKey]];
		goto bail;
	}
	NSDictionary *info = [fm attributesOfItemAtPath:masterfile_path error:error];
	if (!info) goto bail;
	NSString *file_type = [info objectForKey:NSFileType];
	if ([file_type isEqualToString:NSFileTypeSymbolicLink]) {
		masterfile_path = [fm destinationOfSymbolicLinkAtPath:masterfile_path error:error];
		if (!masterfile_path) goto bail;
		info = [fm attributesOfItemAtPath:masterfile_path error:error];
		if (!info) goto bail;
	}
	
	if (![[info objectForKey:NSFileType] isEqualToString:NSFileTypeRegular]) {
		NSString *localized_format = NSLocalizedString(@"ParentFile '%@' is invalid", @"");
		NSString *reason = [NSString stringWithFormat:localized_format, masterfile_path];
		*error = [NSError errorWithDomain:@"TeXBridgeErrorDomain" code:1230
								userInfo:[NSDictionary dictionaryWithObject:reason
																   forKey:NSLocalizedDescriptionKey]];
		goto bail;
	}
	
	result = [TeXDocument texDocumentWithPath:masterfile_path textEncoding:textEncoding];
	if (result) hasMaster = YES;
bail:	
	return result;
}

- (void)dealloc
{
	[file release];
	[textEncoding release];
	[name release];
	[pathWithoutSuffix release];
	[super dealloc];
}

@end
