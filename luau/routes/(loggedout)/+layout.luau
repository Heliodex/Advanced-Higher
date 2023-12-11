local auth = require "auth"

local fw = require "framework"
local layout: fw.Layout = {}

function layout.load(request): fw.Data
	local loggedOut = auth:loggedOut(request.headers.cookie)
	if loggedOut and loggedOut.redirect then
		return loggedOut.redirect
	end

	return {}
end

return layout
