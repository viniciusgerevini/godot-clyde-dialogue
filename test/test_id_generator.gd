extends "res://addons/gut/test.gd"

var IdGenerator = preload("res://addons/clyde/editor/tools/id_generator.gd")
var _id_generator = IdGenerator.new()

func test_add_id_to_simple_line():
	var clyde_doc = "This"
	var result = _id_generator.add_ids_to_content(clyde_doc)
	assert_match(result, "This \\$ID[0-9]+")


func test_keep_existing_ids():
	var clyde_doc = '''
This is the first line
This is the second line $existingId
This is the third line
'''
	var expected = '''
This is the first line \\$ID[0-9]+
This is the second line \\$existingId
This is the third line \\$ID[0-9]+
'''
	assert_match_doc_lines(clyde_doc, expected)


func test_keep_existing_ids_among_tags():
	var clyde_doc = '''
This is the first line #tag
This is the second line #some_tag $existingId #some_other_tag
'''
	var expected = '''
This is the first line \\$ID[0-9]+ #tag
This is the second line #some_tag \\$existingId #some_other_tag
'''
	assert_match_doc_lines(clyde_doc, expected)


func test_add_to_multiline():
	var clyde_doc = '''
This is the
	first multiline line
This is a
	multiline with id $some
speaker: this is a second $some
		mline with id
'''
	var expected = '''
This is the
	first multiline line \\$ID[0-9]+
This is a
	multiline with id \\$some
speaker: this is a second \\$some
		mline with id
'''
	assert_match_doc_lines(clyde_doc, expected)


func test_add_to_options():
	var clyde_doc = '''
does it work?
	* it should
	* it should with text
		maybe
	+ should sticky
		maybe
	+ should not sticky $123
	> should fallback
		maybe
	> should not fallback $123
	*= display option
'''
	var expected = '''
does it work\\? \\$ID[0-9]+
	\\* it should \\$ID[0-9]+
	\\* it should with text \\$ID[0-9]+
		maybe \\$ID[0-9]+
	\\+ should sticky \\$ID[0-9]+
		maybe \\$ID[0-9]+
	\\+ should not sticky \\$123
	\\> should fallback \\$ID[0-9]+
		maybe \\$ID[0-9]+
	\\> should not fallback \\$123
	\\*\\= display option \\$ID[0-9]+
'''
	assert_match_doc_lines(clyde_doc, expected)


func test_add_to_variations():
	var clyde_doc = '''
does it work?
(
	- Yes, it does
	- Yes, I guess
	- Probably
	- Does not on this one $123
	- but sure on this
		as much as possible
	-
		hello darkness my old friend
		I come to talk to you again
)
'''
	var expected = '''
does it work\\? \\$ID[0-9]+
\\(
	\\- Yes, it does \\$ID[0-9]+
	\\- Yes, I guess \\$ID[0-9]+
	\\- Probably \\$ID[0-9]+
	\\- Does not on this one \\$123
	\\- but sure on this
		as much as possible \\$ID[0-9]+
	\\-
		hello darkness my old friend \\$ID[0-9]+
		I come to talk to you again \\$ID[0-9]+
\\)
'''
	assert_match_doc_lines(clyde_doc, expected)


func test_add_to_quotted_test():
	var clyde_doc = '''
"this is a text"
"this is another text"
"this text doesn't need ids" $123
"this text has
line breaks"
'this uses simple quotes'
* "quotes with line
breaks for the win"
'''
	var expected = '''
"this is a text" \\$ID[0-9]+
"this is another text" \\$ID[0-9]+
"this text doesn't need ids" \\$123
"this text has
line breaks" \\$ID[0-9]+
'this uses simple quotes' \\$ID[0-9]+
\\* "quotes with line
breaks for the win" \\$ID[0-9]+
'''
	assert_match_doc_lines(clyde_doc, expected)


func test_ignore_logic_blocks():
	var clyde_doc = '''
Hello { set a = "we should totally ignore blocks" }
{ set a = "for realz" }
{ set a = "with line breaks \n" }
still counts
'''
	var expected_result = '''
Hello \\$ID[0-9]+ \\{ set a \\= "we should totally ignore blocks" \\}
\\{ set a \\= "for realz" \\}
\\{ set a \\= "with line breaks \n" \\}
still counts \\$ID[0-9]+
'''
	assert_match_doc_lines(clyde_doc, expected_result)


func test_ignore_comments():
	var clyde_doc = '''
Hello
-- do nothing with this line
-- or this
still counts
'''
	var expected_result = '''
Hello \\$ID[0-9]+
\\-\\- do nothing with this line
\\-\\- or this
still counts \\$ID[0-9]+
'''

	assert_match_doc_lines(clyde_doc, expected_result)


func test_handle_some_nasty_nasting():
	var clyde_doc = '''
* hello
	what are my options
		* don't know
		* don't care
+ some nesting
	(
		- yep
		  nope
		- yeah
		  nah
		-
		  yes
		  for sure
	)
	and normal text
	  with indent
'''
	var expected_result = '''
\\* hello \\$ID[0-9]+
	what are my options \\$ID[0-9]+
		\\* don't know \\$ID[0-9]+
		\\* don't care \\$ID[0-9]+
\\+ some nesting \\$ID[0-9]+
	\\(
		\\- yep
		  nope \\$ID[0-9]+
		\\- yeah
		  nah \\$ID[0-9]+
		\\-
		  yes \\$ID[0-9]+
		  for sure \\$ID[0-9]+
	\\)
	and normal text
	  with indent \\$ID[0-9]+
'''

	assert_match_doc_lines(clyde_doc, expected_result)


func assert_match(result: String, expected: String):
	var regex = RegEx.create_from_string(expected)
	assert_true(regex.search(result) != null, "Result does not match regex: \n received: %s\n expected: %s" % [result, expected])


func assert_match_doc_lines(doc: String, expected: String):
	var result = _id_generator.add_ids_to_content(doc)
	var lines = result.split("\n")
	var expected_lines = expected.split("\n")

	for i in range(expected_lines.size()):
		assert_match(lines[i], expected_lines[i])
