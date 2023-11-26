local net = require "@lune/net"
local page = {}

function page:load(request: net.ServeRequest)
	return "Testing!"
end

return page
