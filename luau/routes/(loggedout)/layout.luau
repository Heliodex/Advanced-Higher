local auth = require "auth"

local fw = require "framework"
local layout: fw.Layout = {}

function layout.load(request): fw.Data
	local loggedOut = auth.loggedOut(request.headers.cookie)
	return if loggedOut and loggedOut.redirect then loggedOut.redirect else {}
end

return layout
