local compile = require "compile"

--[[
	Compiles and returns a component from the given path.
]]
return function(path: string)
	-- split at the final slash into (path, filename)
	local component = compile("components", path)

	if not component then
		error(`{path} is not a valid component`, -1)
	end

	return component
end
