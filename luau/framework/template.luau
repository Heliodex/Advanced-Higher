-- templating engine for luau and html iguess
-- like etlua and penlight.template
-- not similar to lux or jsx or (sadly) htmlx

local template = {}
template.__index = template

type Node = {
	type: "string" | "block" | "interpolation",
	value: string,
}
type Nodes = { Node }

local function parseTemplate(str)
	local list: Nodes = {}
	local currentString = ""
	local i = 0

	local function next(n)
		local nextChars = ""
		for j = i, math.min(i + n - 1, #str) do
			nextChars ..= str[j]
		end
		return nextChars
	end

	while i < #str do
		i += 1

		-- Start of a block (#{)
		if str[i] == "{" and str[i + 1] == "#" then
			if str[i - 2] == "\\" then
				currentString = string.sub(currentString, 1, -2)
				currentString ..= "{#"
				continue
			end

			i += 1

			-- End the last block
			table.insert(list, {
				type = "string",
				value = currentString,
			} :: Node)
			currentString = ""

			-- Find the end of the block (#})
			while i < #str do
				i += 1

				if next(2) == "#}" then
					if str[i - 1] == "\\" then
						i += 1
						currentString = string.sub(currentString, 1, -2)
						currentString ..= "#}"
						continue
					end

					i += 2
					break
				end

				currentString ..= str[i]
			end

			-- Add the block to the list
			table.insert(list, {
				type = "block",
				value = currentString,
			} :: Node)
			currentString = ""

			-- Start of an interpolation ({)
			--[[ elseif str[i] == "{" and str[i + 1] ~= "#" then
			if str[i - 1] == "\\" then
				currentString = string.sub(currentString, 1, -2)
				currentString ..= "{"
				continue
			end

			-- End the last interpolationi
			table.insert(list, {
				type = "string",
				value = currentString,
			} :: Node)
			currentString = ""

			-- Find the end of the interpolationi (})
			while i < #str do
				i += 1

				if str[i] == "}" then
					if str[i - 1] == "\\" then
						currentString = string.sub(currentString, 1, -2)
						currentString ..= "}"
						continue
					end

					i += 1
					break
				end

				currentString ..= str[i]
			end

			-- Add the interpolation to the list
			table.insert(list, {
				type = "interpolation",
				value = currentString,
			} :: Node)
			currentString = "" ]]
		end

		currentString ..= str[i]
	end
	table.insert(list, {
		type = "string",
		value = currentString,
	} :: Node)

	return list
end

local function renderTemplate(list: Nodes)
	local rendered = ""

	for _, node in list do
		if node.type == "string" then
			rendered ..= node.value
		end
	end

	rendered = `return function()`

	return rendered
end

function template.parse(temp)
	local chars = {}
	-- Split string to chars
	for i, _ in string.gmatch(temp, ".") do
		table.insert(chars, i)
	end

	return renderTemplate(parseTemplate(chars))
end

return template
