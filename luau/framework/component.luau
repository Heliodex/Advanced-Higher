local compile = require "compile"
local init = require "init"

type Data = init.Data

--[[
	Compiles and returns a component from the given path.
]]
return function(path: string)
	-- split at the final slash into (path, filename)
	local basepath, filename = string.match(path, "^(.*)/([^/]*)$")
	local compiledPath = compile(basepath, filename)

	if not compiledPath then
		error(`{path} is not a valid component`)
	end

	local ok, component: (args: Data) -> string =
		pcall(require, compiledPath)

	if not ok then
		error(component)
	end

	return component
end
