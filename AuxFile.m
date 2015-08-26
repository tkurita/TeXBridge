#import "AuxFile.h"
#import "PathExtra.h"
#import "StringExtra.h"
#import "AppController.h"
#import "LabelDatum.h"
#import "miClient.h"

@implementation AuxFile
@synthesize basename;
@synthesize texDocument;
@synthesize auxFilePath;
@synthesize labelsFromAux;
@synthesize labelsFromEditor;
@synthesize checkedTime;
@synthesize texDocumentSize;

#define useLog 0

static NSMutableArray *ALL_AUX_FILES = nil;

+ (void)initialize{
	if (!ALL_AUX_FILES) {
		ALL_AUX_FILES = [NSMutableArray new];
	}
}

- (NSImage *)nodeIcon
{
	static NSImage *nodeIcon = nil;
	if (!nodeIcon) nodeIcon = [NSImage imageNamed:@"mi-document.icns"];
	return nodeIcon;
}

AuxFile *findAuxFileWithKey(NSString* keyPath)
{
	AuxFile *result = nil;
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pathWithoutSuffix LIKE %@", keyPath];
	NSArray *filterd_array = [ALL_AUX_FILES filteredArrayUsingPredicate:predicate];
	if (filterd_array && [filterd_array count]) {
		result = [filterd_array lastObject];
	}
	return result;	
}

+ (AuxFile *)auxFileWithTexDocument:(TeXDocument *)texDoc
{
	AuxFile *result = nil;
	if (texDoc.file) {
		NSString *a_key = [texDoc pathWithoutSuffix];
		result = findAuxFileWithKey(a_key);
		if (result) {
			result.texDocument = texDoc;
			[result checkAuxFile];
			goto bail;
		}
	}

	result = [AuxFile new];
	result.basename = [texDoc.name stringByDeletingPathExtension];
	result.texDocument = texDoc;
	result.labelsFromEditor = [NSMutableArray array];
	result.labelsFromEditor = [NSMutableArray array];
	if (texDoc.file) {
		[result checkAuxFile];
	}
	[ALL_AUX_FILES addObject:result];
bail:
	return result;
}

// check existance of path before calling this method.
+ (AuxFile *)auxFileWithPath:(NSString *)anAuxFilePath textEncoding:(NSString *)encodingName
{
	
	AuxFile *result = nil;
	NSString *key_path = [anAuxFilePath stringByDeletingPathExtension];
	NSString *tex_doc_path = [key_path 
							  stringByAppendingPathExtension:@"tex"];
	TeXDocument *tex_doc = [TeXDocument texDocumentWithPath:tex_doc_path 
											   textEncoding:encodingName];	
	result = findAuxFileWithKey(key_path);
	if (!result) {
		result = [AuxFile new];
		result.basename = [tex_doc.name stringByDeletingPathExtension];
		result.auxFilePath = anAuxFilePath;
		//result.labelsFromAux = [NSMutableArray array];
		result.labelsFromEditor = [NSMutableArray array];
		[ALL_AUX_FILES addObject:result];
	}
	result.texDocument = tex_doc;
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

- (void)clearLabelsFromEditorRecursively:(BOOL)recursively
{
#if useLog
	NSLog(@"start clearLabelsFromEditorRecursively");
#endif
	if (![self hasTreeNode]) return;
	NSTreeNode *current_node = [self treeNode];
	NSMutableArray *child_nodes = [current_node mutableChildNodes];
	NSArray *array = [NSArray arrayWithArray:labelsFromEditor];
	for (id label_item in array) {
		NSTreeNode *a_node = [label_item treeNode];
		[child_nodes removeObject:a_node];
		[labelsFromEditor removeObject:label_item];
	}
	
	if (recursively) {
		for (id label_item in labelsFromAux) {
			if ([label_item isKindOfClass:[AuxFile class]]) {
				[label_item clearLabelsFromEditorRecursively:YES];
			}
		}
	}
#if useLog	
	NSLog(@"end clearLabelsFromEditorRecursively");
#endif	
}

- (BOOL)findLabelsFromEditorWithForceUpdate:(BOOL)forceUpdate
{
    
    static NSRegularExpression *label_regexp = nil;
    if (!label_regexp) {
        NSError *error = nil;
        label_regexp = [NSRegularExpression regularExpressionWithPattern:@"\\\\label\\{([^{}]+)\\}"
                                                options:0 error:&error];
        if (error) {
            NSLog(@"Error : %@", [error localizedDescription]);
            return NO;
        }
    }
    
	miClient *editor_client = [miClient sharedClient];
	NSString *content = [editor_client currentDocumentContent];
	if (! content) return NO;
	NSArray *paragraphs = [content paragraphs];
	NSUInteger current_doc_size = [content length];
	if ((!forceUpdate) && (![self isTexFileUpdated])) {
		if (texDocumentSize == current_doc_size) return NO;
	}
	
	[self clearLabelsFromEditorRecursively:NO];
	NSCharacterSet *spaces_set = [NSCharacterSet whitespaceCharacterSet];
	NSString *scaned_string;
	for (NSString *a_line in paragraphs ) {
#if useLog
		NSLog(@"findLabelsFromEditor : %@", a_line);
#endif
        NSString *trimmed_line = [a_line stringByTrimmingCharactersInSet:spaces_set];
		if (! [trimmed_line length] ) continue;
		if ([trimmed_line hasPrefix:@"%"]) continue;
		
		// remove comment
		NSScanner *scanner = [NSScanner scannerWithString:trimmed_line];
		NSMutableString *clean_line = [NSMutableString stringWithCapacity:[trimmed_line length]];
		while (![scanner isAtEnd]) {
			if ([scanner scanUpToString:@"%" intoString:&scaned_string]) {
				[clean_line appendString:scaned_string];
				if (! [scaned_string hasSuffix:@"\\"]) break;
				[clean_line appendString:@"%"];
				[scanner setScanLocation:[scanner scanLocation]+1];
			}
		}
		
		// find label command
        NSArray *match_results = [label_regexp matchesInString:clean_line options:0
                                                   range:NSMakeRange(0, clean_line.length)];
        for (NSTextCheckingResult *chk_result in match_results ){
            NSString *label_name = [clean_line substringWithRange:[chk_result rangeAtIndex:1]];
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

- (void)updateLabelsFromEditor
{
#if useLog
	NSLog(@"start updateLabelsFromEditor");
#endif	
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
#if useLog
	NSLog(@"end updateLabelsFromEditor");
#endif	
}

- (void)updateChildren
{
#if useLog
	NSLog(@"start updateChildren");
#endif	
	NSMutableArray *child_nodes = [treeNode mutableChildNodes];
	NSUInteger pre_children_count = [child_nodes count];
	
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
#if useLog	
	NSLog(@"end updateChildren");
#endif	
}

- (BOOL)parseAuxFile
{
    static NSRegularExpression *newlabel_regexp = nil;
    if (!newlabel_regexp) {
        NSError *error = nil;
        newlabel_regexp = [NSRegularExpression
                               regularExpressionWithPattern:@"\\\\newlabel\\{([^{}]+)\\}\\{((\\{[^{}]*\\})+)\\}"
                           options:0 error:&error];
        if (error) {
            NSLog(@"Error : %@", [error localizedDescription]);
            return NO;
        }
    }
    static NSRegularExpression *input_regexp = nil;
    if (!input_regexp) {
        NSError *error = nil;
        input_regexp = [NSRegularExpression
                            regularExpressionWithPattern:@"\\\\@input\\{([^{}]+)\\}"
                        options:0 error:&error];
        if (error) {
            NSLog(@"Error : %@", [error localizedDescription]);
            return NO;
        }
    }
    static NSRegularExpression *refname_regexp = nil;
    if (!refname_regexp) {
        NSError *error = nil;
        refname_regexp = [NSRegularExpression
                            regularExpressionWithPattern:@"\\{([^{}]*)\\}"
                          options:0 error:&error];
        if (error) {
            NSLog(@"Error : %@", [error localizedDescription]);
            return NO;
        }
    }
    
	self.labelsFromAux = [NSMutableArray array];
	NSError *error = nil;
	NSString *aux_text = [self readAuxFileReturningError:&error];
	if (! aux_text) {
		NSLog(@"Error in parseAuxFile : %@", error);
		return NO;
	}
	
	NSArray *paragraphs = [aux_text paragraphs];
	
	for (NSString *a_line in paragraphs) {
#if useLog
		NSLog(@"a line in aux : %@", a_line);
#endif
		// pickup newlabel commands
        NSTextCheckingResult *a_match = [newlabel_regexp firstMatchInString:a_line
                                                                  options:0
                                                                    range:NSMakeRange(0, a_line.length)];
        if (a_match.numberOfRanges > 2) {
            NSString *label_name = [a_line substringWithRange:[a_match rangeAtIndex:1]];
            NSString *label_args = [a_line substringWithRange:[a_match rangeAtIndex:2]];
            NSArray *matches = [refname_regexp matchesInString:label_args
                                                       options:0 range:NSMakeRange(0, label_args.length)];
            NSString *ref_name = nil;
            NSUInteger second_matches_count = [matches count];
            if ( second_matches_count > 3) { // hyperref
				ref_name = [label_args substringWithRange:
                            [[matches objectAtIndex:second_matches_count-2] rangeAtIndex:1]];
			} else {
				ref_name = [label_args substringWithRange:[[matches objectAtIndex:0] rangeAtIndex:1]];
			}
			
			if ( [label_name length] || ![label_name hasPrefix:@"SC@"]) {
				[self addLabelFromAux:label_name referenceName:ref_name];
			}
			continue;
        }
        

        a_match = [input_regexp firstMatchInString:a_line options:0
                                                        range:NSMakeRange(0, a_line.length)];
        if (a_match.numberOfRanges > 1) {
            NSString *input_file = [a_line substringWithRange:[a_match rangeAtIndex:1]];
            NSURL *input_aux_url = [[NSURL URLWithString:input_file relativeToURL:[texDocument file]]
									absoluteURL];
            NSString *input_aux_path = [input_aux_url path];
			if ([input_aux_path fileExists]) {
				AuxFile *child_aux_file = [AuxFile auxFileWithPath:input_aux_path
													  textEncoding:texDocument.textEncoding];
				
				if (!treeNode && [child_aux_file hasTreeNode]) { //child item has already exists before its parent.
					NSMutableArray *nodes = [child_aux_file.treeNode mutableChildNodes];
					NSArray* nodes_copy = [NSArray arrayWithArray:nodes];
					for (id a_node in nodes_copy) {
						[nodes removeLastObject];
					}
				}
				if ([child_aux_file parseAuxFile]) {
					[self addChildAuxFile:child_aux_file];
				}
				
			}
			continue;
        }
	}
	return YES;
}

- (void)remove
{
	[ALL_AUX_FILES removeObject:self];
	for (id a_child in labelsFromAux) {
		if ([a_child isKindOfClass:[AuxFile class]]) {
			[a_child remove];
		}
	}
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
