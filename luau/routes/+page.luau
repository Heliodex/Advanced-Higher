local net = require "@lune/net"
local page = {}

function page:load(request: net.ServeRequest)
	return "Hello, world!"
end

return page
