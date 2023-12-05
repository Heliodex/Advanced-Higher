local fs = require "@lune/fs"

local template = require "template"

local function createFile(path, contents)
	-- create each directory in the path if it doesn't exist
	local currentPath = ""
	for dir in string.gmatch(path, "[^/]+") do
		-- don't create the last part of the path
		if dir == string.match(path, "^.*/([^/]*)$") then
			break
		end
		currentPath ..= `{dir}/`
		if not fs.isDir(currentPath) then
			fs.writeDir(currentPath)
		end
	end

	fs.writeFile(`{path}.luau`, contents)
end

return function(path: string, filetype: string): string?
	local filename = `{path}/{filetype}.ltmp`
	local ok, isFile = pcall(fs.isFile, filename)
	if not (ok and isFile) then
		return
	end

	local compiledPath = `.compiled{filename}/{filetype}`

	createFile(compiledPath, template(fs.readFile(filename), true))

	return compiledPath
end
