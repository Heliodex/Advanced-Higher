-- Basic templating engine for Luau and HTML

type Node = {
	type: "string" | "block",
	value: string,
}
type Nodes = { Node }

local function parseTemplate(str)
	local list: Nodes = {}
	local currentString = ""
	local i = 0

	local function add(type)
		table.insert(
			list,
			{
				type = type,
				-- trim whitespace (trimming newlines messes up html sometimes)
				value = string.gsub(currentString, "^%s*(.-) *$", "%1"),
			} :: Node
		)
		currentString = ""
	end

	while i < #str do
		i += 1

		-- Start of a block (#{)
		if str[i] == "{" and str[i + 1] == "#" then
			if str[i - 2] == "\\" then
				currentString = string.sub(currentString, 1, -2) .. "{#"
				continue
			end

			i += 1

			-- End the last block
			add "string"

			-- Find the end of the block (#})
			while i < #str do
				i += 1

				local nextChars = ""
				for j = i, math.min(i + 1, #str) do
					nextChars ..= str[j]
				end

				if nextChars == "#}" then
					if str[i - 1] == "\\" then
						i += 1
						currentString = string.sub(currentString, 1, -2) .. "#}"
						continue
					end

					i += 2
					break
				end

				currentString ..= str[i]
			end

			-- Add the block to the list
			add "block"
		end

		currentString ..= str[i]
	end
	add "string"

	return list
end

local function renderTemplate(list: Nodes)
	local rendered = ""

	for _, node in list do
		-- escape newlines and backticks
		local value = node.value
		value = string.gsub(value, "\\\\{", "\\{")
		value = string.gsub(value, "`", "\\`")

		rendered ..= if node.type == "string"
			then `_rendered ..= \`{string.gsub(value, "\n", "\\n")}\`\n`
			else `{value} `
	end
	-- god please have mercy on my soul
	return `local _rendered = ""\n{rendered}\nreturn _rendered`
end

return function(temp)
	temp = string.gsub(temp, "\r\n", "\n")

	local chars = {}
	-- Split string to chars
	for i in string.gmatch(temp, ".") do
		table.insert(chars, i)
	end

	return renderTemplate(parseTemplate(chars))
end
