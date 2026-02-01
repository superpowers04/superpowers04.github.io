--[[
	Transpiles a "super_html" file to an html file, a really bad custom format I "designed" I use to make my life easier.
	Yes superhtml actually does exist but I'm bad at coming up with names, this is just the first part of my username(super) and html

	You can find an example of the format below. 
	Besides the syntax below, this shouldn't do anything else to a file. So this can be included with standard html
	If you don't want the automatic link icon stuff for headers, set SuperHTMLParser.global_defines.link_svg to ""
]]
local SuperHTMLParser = {}

local test_example=[[
	<shtml_include "path/to/included" />
	<shtml_define id="cool_define">Define text</define>

	You can escape things with \\ \
	Backslashes before a newline or 2 newlines will automatically add a \<br/\> \

	<d_centered>Div with centered class</d_centered>\
	<a.centered href="https://example.com">Link with centered class</a>\
	<f "strong i d_centered" Bold, Italic, Centered text f/>\

	<shtml_def cool_define />
	<shtml_def cool_define />

	<img "path/to/image.png"/>

	<https://example.com Link shorthand 2 a>\
	<"https://example.com" Link shorthand a>\
	<c_p Shorthand for any tag c/>\
	<c_p.centered Shorthand for any tag.class c/>\
	<c_p.centered#shorthand_example Shorthand for any tag.class#ID c/>\

	# Header with id
	<super_list>
	* List item 1
	* List item 2
	</super_list>
	<bp> List item without list

	<!LUA return "Preproccessed with ".. (_PVERSION or _VERSION) !>
]]
SuperHTMLParser.global_defines = {
	["link_svg"]=[[<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" class="svg octicon-link" width="16" height="16"><path d="m7.775 3.275 1.25-1.25a3.5 3.5 0 1 1 4.95 4.95l-2.5 2.5a3.5 3.5 0 0 1-4.95 0 .75.75 0 0 1 .018-1.042.75.75 0 0 1 1.042-.018 2 2 0 0 0 2.83 0l2.5-2.5a2.002 2.002 0 0 0-2.83-2.83l-1.25 1.25a.75.75 0 0 1-1.042-.018.75.75 0 0 1-.018-1.042m-4.69 9.64a2 2 0 0 0 2.83 0l1.25-1.25a.75.75 0 0 1 1.042.018.75.75 0 0 1 .018 1.042l-1.25 1.25a3.5 3.5 0 1 1-4.95-4.95l2.5-2.5a3.5 3.5 0 0 1 4.95 0 .75.75 0 0 1-.018 1.042.75.75 0 0 1-1.042.018 2 2 0 0 0-2.83 0l-2.5 2.5a2 2 0 0 0 0 2.83"></path></svg>]]
}
-- TODO - MOVE TO LOCAL FUNCTION
function string.format_num(str,...) 
	local a = { ... }
	str = str:gsub('%%(%d+)',function(i) return tostring(a[tonumber(i)]) end)
	return str
end

function SuperHTMLParser.example()
	print(SuperHTMLParser.markup(test_example))
end


function SuperHTMLParser.INFOF(str,...) print("["..os.date('%X').." INFO]",str:format_num(...)) end
function SuperHTMLParser.INFO (...) print("["..os.date('%X').." INFO]",...) end
function SuperHTMLParser.WARNF(str,...) print("["..os.date('%X').." WARN]",str:format_num(...)) end
function SuperHTMLParser.WARN (...) print("["..os.date('%X').." WARN]",...) end
function SuperHTMLParser.ERR  (...) print("["..os.date('%X').." ERROR]",...) os.exit(-1) end
function SuperHTMLParser.ERRF (str,...) print("["..os.date('%X').." ERROR]",str:format_num(...)) os.exit(-1) end

local INFOF, INFO, WARNF, WARN, ERR, ERRF = SuperHTMLParser.INFOF, SuperHTMLParser.INFO, SuperHTMLParser.WARNF, SuperHTMLParser.WARN, SuperHTMLParser.ERR, SuperHTMLParser.ERRF


function SuperHTMLParser.markup(contents)
	local defines = { }
	local function get_def(name)
		name=name:lower()
		local content = defines[name] or SuperHTMLParser.global_defines[name]
		if not content then 
			WARNF('Define %1 does not exist!',name)
			return "<s_def "..name.." />"
		end
		return content or "N/A"
	end
	local function to_id(str)
		return str:gsub('<.->',''):lower():gsub('[^a-z0-9_%-]','_'):gsub('__+','_'):gsub('_+$',''):gsub('^_+','')
	end
	return (contents
			-- Character replacements
			:gsub("\\\\", "&bsol;")
			:gsub("\\&", "&amp;")
			:gsub("\\<", "&lt;")
			:gsub("\\>", "&gt;")
			:gsub('\\"', "&quot;")
			:gsub('\\([^ \n])',function(a) return ('&#%i;'):format(a:byte()) end)
			:gsub("\\\n", "\n<br/>")

			:gsub("(\n%s*)(#+)%s*([^\n]+)", function(whitespace,header,text) -- # Header
				local name = to_id(text)

				return ('%1<h%2 id="%3"><a href="#%3"><s_def link_svg /></a>%4</h%2>'):format_num(whitespace,#header,name,text)
			end)

			-- Custom tags

			:gsub('<shtml_include ?"(.-)" ?/>',function(path) -- <shtml_include "PATH_TO_FILE" />
				local file = io.open(path,'r')
				if not file then

					WARNF('File does not exist! %1',path)
					return ""
				end
				local content = file:read('*a')
				file:close()
				return content
			end)
			:gsub('<shtml_define id="(.-)">(.-)</define>',function(name,content) -- <shtml_define id="ID"> CONTENT </define>
				defines[name:lower()] = content
				return ""
			end)
			:gsub('<shtml_define id="(.-)">(.-)</define>',function(name,content) -- <shtml_define id="ID"> CONTENT </define>
				defines[name:lower()] = content
				return ""
			end)
			:gsub('<s_def (.-) ?/>',get_def) -- <s_def ID />

			
			:gsub('<super_list>%s+(.-)%s+</super_list>',function(tag_contents) -- <super_list>\n* item </super_list>
				return ('<ul><li>%s</li></ul>'):format(tag_contents:gsub('%* ?',"</li><li>")):gsub("<li>%s*</li>",'')
			end)
			:gsub('<usuper_list>%s+(.-)%s+</usuper_list>',function(tag_contents) -- <usuper_list>\n* item </usuper_list>
				return ('<ul><li>%s</li></ul>'):format(tag_contents:gsub('%* ?',"</li><li>")):gsub("<li>%s*</li>",'')
			end)
			:gsub('<osuper_list>%s+(.-)%s+</osuper_list>',function(tag_contents) -- <osuper_list>\n* item </osuper_list>
				return ('<ol><li>%s</li></ol>'):format(tag_contents:gsub('%* ?',"</li><li>")):gsub("<li>%s*</li>",'')
			end)
			:gsub('<([uo]?)bp/?>(.-)\n',function(ordered,tag_contents) -- <bp/> Single Line bullet point
				ordered = ordered == "o" and "o" or "u"
				return ('<%sl><li>%s</li></%sl>'):format(
					ordered,
					tag_contents,
					ordered
				)
			end)


			:gsub('<c_?([^ ]+) (.-) c/?>',"<%1>%2</%1>") -- <c_TAG shorthand c/> 
			:gsub('<c_?([^ >]+)%.([^ >]+) (.-) c/?>',"<%1 class='%2'>%3</%1>") -- <c_TAG.CLASS shorthand c/> 
			:gsub('<a?(https?://.-) (.-) a/?>',"<a href='%1'>%2</a>") -- <https://example.com Funny link a> 
			:gsub('<a?"(https?://.-)" (.-) a/?>',"<a href='%1'>%2</a>") -- <"https://example.com" Funny link a> 
			:gsub('<a"(.-)" (.-) a/?>',"<a href='%1'>%2</a>") -- <a"/path/to/file" Link to file on webserver a> 

			:gsub('<f ?"(.-)" (.-) f/?>',function(tag_list,inner) -- <f "strong i d_CLASS" CLASS Bold Italic f>
				local tag_start,tag_end = {}, {}
				for tag in tag_list:gmatch('[^ ]+') do 
					table.insert(tag_start,('<%s>'):format(tag))
					table.insert(tag_end,1,('</%s>'):format(tag))
				end
				return table.concat(tag_start,'')..inner..table.concat(tag_end,'')
			end)
			:gsub('<img ?"(.-)"(.-)/?>', '<img src="%1"%2 />') -- <img "/path/to/image.png"/>
			:gsub('<img%.([^ >]+) ?"(.-)"(.-)/?>', '<img class="%1" src="%2"%3 />') -- <img.CLASS "/path/to/image.png"/>

			:gsub('<([^/ %.]+)%.([^ #>]+)#([^ >]+)>',function(tag,class,id) -- <TAG.CLASS#ID>
				return ("<%1 class='%2' id='%3'><a href='#%3'><s_def link_svg /></a>"):format_num(tag,to_id(id))
			end) 
			:gsub('<([^ %#]+)%#([^ >]+)>',function(tag,id)  -- </TAG#ID>
				return ("<%1 id='%2'><a href='#%2'><s_def link_svg /></a>"):format_num(tag,to_id(id))
			end)
			:gsub('<([^/ %.]+)%.([^ >]+)>',"<%1 class='%2'>") -- <TAG.CLASS>
			:gsub('<([^ %#]+)%#([^ >]+)(.-)>',function(tag,id,meta)  -- </TAG#ID ...>
				return ("<%1 id='%2' %3><a href='#%2'><s_def link_svg /></a>"):format_num(tag,to_id(id),meta)
			end)
			:gsub('<([^/ %.]+)%.([^ >]+)(.-)>',"<%1 class='%2'%3>") -- <TAG.CLASS ...>
			:gsub('</([^ %.]+)%.([^ >]+)>',"<%1>") -- </TAG.CLASS>
			:gsub('</([^ %#]+)%#([^ >]+)>',"<%1>") -- </TAG#ID>
			:gsub('<d_([^ >]+) (.-)>',"<div class='%1' %2>") -- <d_CLASS TAG_PROPERTIES>
			:gsub('<d_([^ >]+)>',"<div class='%1'>") -- <d_CLASS>
			:gsub('</d_([^ >]+)>',"</div>") -- </d_CLASS>
			:gsub('</d_([^ >]+)>',"</div>") -- </d_CLASS>

			-- Custom syntax
			:gsub("<!(LUAR?) (.-) !>", function(_type,code) -- <!LUA return "Parse time, code" !>
				if(_type=='LUAR') then code = 'return '..code end
				local succ
				local chunk,err = load(code)
				if chunk then 
					succ,err = pcall(chunk)
					if not succ then
						WARNF('Error with super_html code! %1',err)
						err = "An error occurred while running lua code: "..err
					end
				end
				return tostring(err)
			end)

			-- Doing this twice in case LUAR returns a def or something- also it's used for the link icon with <TAG#ID>
			:gsub('<s_def (.-) ?/>', get_def) -- <s_def ID />

			-- Newline stuff
			:gsub("[ \t]+\n", "\n")
			:gsub("\n\n", "<br/>\n")
	)
end
-- INFO('SUPER_HTML TEST',markup(test_example))
-- Automatically reformats a super_html file and outputs it as a html file
function SuperHTMLParser.markup_file(file)
	INFOF('Formatting %1',file)
	local super_file = io.open(file,'r')
	local shtml_content = super_file:read('*a')
	super_file:close()
	local file = io.open(file:gsub('%.([^%.]+)$','.html'),'w')
	file:write(SuperHTMLParser.markup(shtml_content))
	file:close()
end

return SuperHTMLParser