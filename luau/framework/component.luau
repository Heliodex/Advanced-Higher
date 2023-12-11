local compile = require "compile"

type Data = { [string]: any }

--[[
	Compiles and returns a component from the given path.
]]
return function(path: string)
	-- split at the final slash into (path, filename)
	local basepath, filename = string.match(path, "^(.*)/([^/]*)$")
	local component = compile(basepath, filename)

	if not component then
		error(`{path} is not a valid component`)
	end

	return component
end
