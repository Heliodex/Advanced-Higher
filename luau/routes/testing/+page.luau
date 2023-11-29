local net = require "@lune/net"
local page = {}

function page:load(request: net.ServeRequest): { [string]: any }
	return {
		thing = "hello",
		place = "world",
	}
end

return page
