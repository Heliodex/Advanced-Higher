local net = require "@lune/net"
local redirect = require "../../framework/redirect"
local page = {}

page.actions = {
	default = function(request: net.ServeRequest): net.ServeResponse | string
		return redirect(302, "/home")
	end,
}

return page
