local fs = require "@lune/fs"
local luau = require "@lune/luau"

local template = require "template"

type Data = { [string]: any }

return function(path: string, filetype: string): ((args: Data) -> string)?
	local filename = `{path}/{filetype}.ltmp`
	local ok, isFile = pcall(fs.isFile, filename)
	if not (ok and isFile) then
		return
	end

	local compiled = template(fs.readFile(filename), true)

	return function(args)
		return luau.load(compiled, {
			environment = args,
		})()
	end
end
