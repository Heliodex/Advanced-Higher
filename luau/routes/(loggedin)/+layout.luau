local auth = require "auth"

local fw = require "framework"
local layout: fw.Layout = {}

function layout.load(request): fw.Data
	local loggedIn = auth:loggedIn(request.headers.cookie)
	if loggedIn.redirect then
		return loggedIn.redirect
	end

	return {}
end

return layout
