local net = require "@lune/net"
local auth = require "../../auth"
local layout = {}

function layout:load(request: net.ServeRequest): net.ServeResponse
	local loggedOut = auth:loggedOut(request.headers.cookie)
	if loggedOut and loggedOut.redirect then
		return loggedOut.redirect
	end

	return {}
end

return layout
