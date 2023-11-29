local net = require "@lune/net"
local page = {}

function page:load(request: net.ServeRequest): { [string]: any }
	return {
		text = "Hello, world!",
	}
end

return page
