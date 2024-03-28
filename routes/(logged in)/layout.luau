-- All requests to pages that require a user to be logged in should go through this layout

local auth = require "auth"

local fw = require "framework"
local layout: fw.Layout = {}

function layout.load(request): fw.Data
	local loggedIn = auth.loggedIn(request.headers.cookie)
	return loggedIn.redirect or {}
end

return layout
