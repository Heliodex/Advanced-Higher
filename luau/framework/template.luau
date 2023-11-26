local template = {}
template.__index = template

-- sum basic templating

local canBeSelfClosing = {
	area = true,
	base = true,
	br = true,
	col = true,
	embed = true,
	hr = true,
	img = true,
	input = true,
	link = true,
	meta = true,
	param = true,
	source = true,
	track = true,
	wbr = true,
}

-- You ain't seen 5am code like dis before
function genTag(name: string, attributes: any, content: any)
	local attributeString = ""
	local contentExists = content and #content > 0

	if type(attributes) == "function" then
		attributes = { attributes }
	end

	for key, value in pairs(attributes or {}) do
		if type(value) == "function" and not contentExists then
			-- whoops, this is actually content
			contentExists = true
			content = attributes
			attributes = {}
			break
		end
	end
	for key, value in pairs(attributes or {}) do
		if type(key) == "number" then
			-- does it start with a "#"?
			local firstChar = string.sub(value, 1, 1)
			if firstChar == "#" then
				key = "id"
				value = string.sub(value, 2)
			elseif firstChar == "." then
				key = "class"
				value = string.sub(value, 2)
			elseif #attributes == 1 then
				-- it's content bruh
				contentExists = true
				content = attributes
				attributes = {}
				break
			end
		end
		attributeString ..= ` {key}="{value}"`
	end

	if not contentExists then
		return if canBeSelfClosing[name]
			then `<{name}{attributeString} />`
			else `<{name}{attributeString}></{name}>`
	end

	if type(content) == "table" then
		for i, v in ipairs(content) do
			if type(v) == "function" then
				content[i] = v()
			end
		end
		content = table.concat(content)
	end

	return `<{name}{attributeString}>{content}</{name}>`
end

local tagsList = {
	"a",
	"abbr",
	"address",
	"area",
	"article",
	"aside",
	"audio",
	"b",
	"base",
	"bdi",
	"bdo",
	"blockquote",
	"body",
	"br",
	"button",
	"canvas",
	"caption",
	"cite",
	"code",
	"col",
	"colgroup",
	"data",
	"datalist",
	"dd",
	"del",
	"details",
	"dfn",
	"dialog",
	"div",
	"dl",
	"dt",
	"em",
	"embed",
	"fieldset",
	"figcaption",
	"figure",
	"footer",
	"form",
	"h1",
	"h2",
	"h3",
	"h4",
	"h5",
	"h6",
	"head",
	"header",
	"hgroup",
	"hr",
	"html",
	"i",
	"iframe",
	"img",
	"input",
	"ins",
	"kbd",
	"label",
	"legend",
	"li",
	"link",
	"main",
	"map",
	"mark",
	"meta",
	"meter",
	"nav",
	"noscript",
	"object",
	"ol",
	"optgroup",
	"option",
	"output",
	"p",
	"param",
	"picture",
	"pre",
	"progress",
	"q",
	"rb",
	"rp",
	"rt",
	"rtc",
	"ruby",
	"s",
	"samp",
	"script",
	"section",
	"select",
	"slot",
	"small",
	"source",
	"span",
	"strong",
	"style",
	"sub",
	"summary",
	"sup",
	"table",
	"tbody",
	"td",
	"template",
	"textarea",
	"tfoot",
	"th",
	"thead",
	"time",
	"title",
	"tr",
	"track",
	"u",
	"ul",
	"var",
	"video",
	"wbr",
}

for _, tag in ipairs(tagsList) do
	template[tag] = function(attributes: string | { [any]: any })
		if type(attributes) == "string" then
			return function(content: any)
				return genTag(tag, { attributes }, content)
			end
		end
		return function(content: any)
			return genTag(tag, attributes, content)
		end
	end
end

function template:BASE(tit: string, content: string)
	local b = template.html { lang = "en" } {
		template.head {
			template.meta { charset = "utf-8" },
			template.meta {
				name = "viewport",
				content = "width=device-width,initial-scale=1",
			},
			template.title(tit),
		},
		template.body(content),
	}
	return "<!DOCTYPE html>" .. b
end

return template
