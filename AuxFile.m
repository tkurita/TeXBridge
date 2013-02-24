#import "AuxFile.h"
#import "PathExtra.h"
#import "StringExtra.h"
#import "AppController.h"
#import "LabelDatum.h"
#import "miClient.h"
#import "RegexKitLite.h"

@implementation AuxFile
@synthesize basename;
@synthesize texDocument;
@synthesize auxFilePath;
@synthesize labelsFromAux;
@synthesize labelsFromEditor;
@synthesize checkedTime;
@synthesize texDocumentSize;

#define useLog 0

- (NSImage *)nodeIcon
{
	static NSImage *nodeIcon = nil;
	if (!nodeIcon) nodeIcon = [NSImage imageNamed:@"mi-document.icns"];
	return nodeIcon;
}

- (void)dealloc
{
	[basename release];
	[texDocument release];
	[auxFilePath release];
	[labelsFromAux release];
	[labelsFromEditor release];
	[checkedTime release];
	[super dealloc];
}

+ (AuxFile *)auxFileWithTexDocument:(TeXDocument *)aTeXDocument
{
	AuxFile *result = [[AuxFile new] autorelease];
	result.basename = [aTeXDocument.name stringByDeletingPathExtension];
	result.texDocument = aTeXDocument;
	//result.labelsFromAux = [NSMutableArray array];
	result.labelsFromEditor = [NSMutableArray array];
	if (aTeXDocument.file) {
		[result checkAuxFile];
	}
	
	return result;
}

// check existance of path before calling this method.
+ (AuxFile *)auxFileWithPath:(NSString *)path textEncoding:(NSString *)encodingName
{
	AuxFile *result = [[AuxFile new] autorelease];
	NSString *tex_doc_path = [[path stringByDeletingPathExtension] 
							  stringByAppendingPathExtension:@"tex"];
	TeXDocument *tex_doc = [TeXDocument texDocumentWithPath:tex_doc_path 
											   textEncoding:encodingName];
	result.texDocument = tex_doc;
	result.basename = [tex_doc.name stringByDeletingPathExtension];
	result.auxFilePath = path;
	//result.labelsFromAux = [NSMutableArray array];
	result.labelsFromEditor = [NSMutableArray array];

	return result;
}

- (NSTreeNode *)treeNode
{
	if (! treeNode) {
		treeNode = [NSTreeNode treeNodeWithRepresentedObject:self];
	}
	return treeNode;
}

- (BOOL)hasTreeNode
{
	return (treeNode != nil);
}

- (BOOL)hasMaster
{
	return [texDocument hasMaster];
}

- (BOOL)checkAuxFile
{
	if (! auxFilePath) {
		NSString *aux_file_path = [[[texDocument.file path] stringByDeletingPathExtension]
								   stringByAppendingPathExtension:@"aux"];
		if ([aux_file_path fileExists]) {
			self.auxFilePath = aux_file_path;
			return YES;
		}
	} else {
		return YES;
	}
	return NO;
}

- (NSString *)readAuxFileReturningError:(NSError **)error
{
	NSData *data = [NSData dataWithContentsOfFile:auxFilePath options:0 error:error];
	if (! data) return nil;
	NSArray *encodings = orderdEncodingCandidates(texDocument.textEncoding);
	return [NSString stringWithData:data encodingCandidates:encodings];
}

- (void)addLabelFromAux:(NSString *)labelName referenceName:(NSString *)refName
{
	[labelsFromAux addObject:
		[LabelDatum labelDatumWithName:labelName referenceName:refName]];
}

- (void)addLabelFromEditor:(NSString *)labelNamel
{
	[labelsFromEditor addObject:
	 [LabelDatum labelDatumWithName:labelNamel referenceName:@"--"]];
}

- (void)addChildAuxFile:(AuxFile *)childAuxFile
{
	[labelsFromAux addObject:childAuxFile];
}

- (BOOL)hasLabel:(NSString *)labelName
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name LIKE %@", labelName];
	NSArray *array = [labelsFromAux filteredArrayUsingPredicate:predicate];
	return ([array count] > 0);
}

- (void)updateCheckTime
{
	self.checkedTime = [NSDate date];
}

- (BOOL)isTexFileUpdated
{
	if (!texDocument.file) return NO;
	
	NSError *error = nil;
	NSDictionary *dict = [[NSFileManager defaultManager] attributesOfItemAtPath:[texDocument.file path]
																		  error:&error];
	if (! dict) return NO; // unknown error
	
	NSDate *mod_date = [dict fileModificationDate];
	
	return ([mod_date compare:checkedTime] == NSOrderedDescending);
}

- (void)clearLabelsFromEditor
{
	self.labelsFromEditor = [NSMutableArray array];
}

- (BOOL)findLabelsFromEditorWithForceUpdate:(BOOL)forceUpdate
{
	miClient *editor_client = [miClient sharedClient];
	NSString *content = [editor_client currentDocumentContent];
	if (! content) return NO;
	NSArray *paragraphs = [content paragraphs];
	NSUInteger current_doc_size = [content length];
	if ((!forceUpdate) && (![self isTexFileUpdated])) {
		if (texDocumentSize == current_doc_size) return NO;
	}
	
	[self clearLabelsFromEditor];
	NSCharacterSet *spaces_set = [NSCharacterSet whitespaceCharacterSet];
	NSString *scaned_string;	
	for (NSString *a_line in paragraphs ) {
#if useLog
		NSLog(@"findLabelsFromEditor : %@", a_line);
#endif		
		a_line = [a_line stringByTrimmingCharactersInSet:spaces_set];		
		if (! [a_line length] ) continue;
		if ([a_line hasPrefix:@"%"]) continue;
		
		// remove comment
		NSScanner *scanner = [NSScanner scannerWithString:a_line];
		NSMutableString *clean_line = [NSMutableString stringWithCapacity:[a_line length]];
		while (![scanner isAtEnd]) {
			if ([scanner scanUpToString:@"%" intoString:&scaned_string]) {
				[clean_line appendString:scaned_string];
				if (! [scaned_string hasSuffix:@"\\"]) break;
				[clean_line appendString:@"%"];
				[scanner setScanLocation:[scanner scanLocation]+1];
			}
		}
		
		// find label command
		NSArray *captures = [clean_line arrayOfCaptureComponentsMatchedByRegex:@"\\\\label\\{([^{}]+)\\}"];
		if (! [captures count]) continue;
		for (NSArray *a_capture in captures) {
			NSString *label_name = [a_capture objectAtIndex:1];
			if (![self hasLabel:label_name]) {
				[self addLabelFromEditor:label_name];
			}
		}
#if useLog
		NSLog(@"%@", captures);
#endif				
	}
	[self updateCheckTime];
	texDocumentSize = current_doc_size;
	return YES;
}

- (void)insertIntoTree:(NSTreeController *)treeController atIndexPath:(NSIndexPath *)indexPath // may not used
{
	[treeController insertObject:[self treeNode] atArrangedObjectIndexPath:indexPath];
	NSMutableArray *child_nodes = [treeNode mutableChildNodes];
	for (id child_item in labelsFromAux) {
		NSTreeNode *child_node = [child_item treeNode];
		[child_nodes addObject:child_node];
	}
}

- (void)updateLabelsFromEditor
{
	NSMutableArray *child_nodes = [treeNode mutableChildNodes];
	NSUInteger n_labels_from_editor = [labelsFromEditor count];
	NSUInteger lab_count = 0;
	
	for (NSUInteger n=[labelsFromAux count]; n < [child_nodes count]; n++) {
		if (lab_count < n_labels_from_editor) {
			[child_nodes replaceObjectAtIndex:n 
						   withObject:[[labelsFromEditor objectAtIndex:lab_count] treeNode]];
		} else {
			[child_nodes removeObjectAtIndex:n];
		}
		lab_count++;
	}

	for (NSUInteger n=lab_count; n < n_labels_from_editor; n++) {
		[child_nodes addObject:[[labelsFromEditor objectAtIndex:n] treeNode]];
	}
}

- (void)updateChildren
{
	NSMutableArray *child_nodes = [treeNode mutableChildNodes];
	NSUInteger pre_children_count = [child_nodes count];
	
	//NSUInteger new_children_count = [labelsFromAux count]+[labelsFromEditor count];
	NSUInteger update_index = 0;
	NSArray *array_of_labels[] = {labelsFromAux, labelsFromEditor};

	for (int n = 0; n < 2; n++) {
		NSArray *labels = array_of_labels[n];
		for (id an_item in labels) {
			NSTreeNode *new_node = [an_item treeNode];
			if (update_index < pre_children_count) {
				NSTreeNode *old_node = [child_nodes objectAtIndex:update_index];
				if (![old_node isEqual:new_node]) {
					[child_nodes replaceObjectAtIndex:update_index withObject:new_node];
				}
			} else {
				[child_nodes addObject:new_node];
			}
			if ([an_item isKindOfClass:[AuxFile class]]) {
				[an_item updateChildren];
			} 
			
			update_index++;
		}
	}
	for (NSUInteger n = update_index; n < pre_children_count; n++) {
		[child_nodes removeLastObject];
	}
}

- (BOOL)parseAuxFile
{
	self.labelsFromAux = [NSMutableArray array];
	NSError *error = nil;
	NSString *aux_text = [self readAuxFileReturningError:&error];
	// ToDo : error processing
	
	NSArray *paragraphs = [aux_text paragraphs];
	
	for (NSString *a_line in paragraphs) {
#if useLog
		NSLog(@"a line in aux : %@", a_line);
#endif
		// pickup newlabel commands
		NSArray *captures = [a_line captureComponentsMatchedByRegex:@"\\\\newlabel\\{([^{}]+)\\}\\{((\\{[^{}]*\\})+)\\}"];
#if useLog
		NSLog(@"%@", captures);
#endif		
		if ([captures count] > 2) {
			NSString *label_name = [captures objectAtIndex:1];
			NSArray *second_captures = [[captures objectAtIndex:2] 
										arrayOfCaptureComponentsMatchedByRegex:@"\\{([^{}]*)\\}"];
#if useLog
			NSLog(@"%@", second_captures);
#endif
			NSString *ref_name = nil;
			NSUInteger second_captures_count = [second_captures count];
			if ( second_captures_count > 3) { // hyperref
				ref_name = [[second_captures objectAtIndex:second_captures_count-2] lastObject];
			} else {
				ref_name = [[second_captures objectAtIndex:1] lastObject];
			}
			
			if ( [label_name length] || ![label_name hasPrefix:@"SC@"]) {
				[self addLabelFromAux:label_name referenceName:ref_name];
			}
			continue;
		}
		// pickup input commands
		captures = [a_line captureComponentsMatchedByRegex:@"\\\\@input\\{([^{}]+)\\}"];
#if useLo
		NSLog(@"%@", captures);
#endif
		if ([captures count] > 1) {
			NSString *input_file = [captures objectAtIndex:1];
			NSURL *input_aux_url = [[NSURL URLWithString:input_file relativeToURL:[texDocument file]] 
									absoluteURL];
#if useLog
			NSLog(@"%@", input_aux_url);
#endif			
			NSString *input_aux_path = [input_aux_url path];
			if ([input_aux_path fileExists]) {
				AuxFile *child_aux_file = [AuxFile auxFileWithPath:input_aux_path
													  textEncoding:texDocument.textEncoding];
				if ([child_aux_file parseAuxFile]) {
					[self addChildAuxFile:child_aux_file];
				}
				
			}
			continue;
		}
	}
	return YES;
}

- (NSString *)name
{
	return basename;
}

- (NSString *)referenceName
{
	return @"";
}

- (NSString *)pathWithoutSuffix
{
	return texDocument.pathWithoutSuffix;
}
@end
