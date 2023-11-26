local net = require "@lune/net"
local errorPage = {}

function errorPage:load(request: net.ServeRequest, status: number)
	return `An error occured: {status}`
end

return errorPage
