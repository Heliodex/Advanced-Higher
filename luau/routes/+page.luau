local net = require "@lune/net"
local page = {}

function page:load(request: net.ServeRequest): net.ServeResponse | string
	return "Hello, world!"
end

return page
