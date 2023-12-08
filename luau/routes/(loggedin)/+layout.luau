local net = require "@lune/net"
local auth = require "../../auth"
local layout = {}

function layout:load(request: net.ServeRequest): net.ServeResponse
	local loggedIn = auth:loggedIn(request.headers.cookie)
	if loggedIn.redirect then
		return loggedIn.redirect
	end

	return {}
end

return layout
