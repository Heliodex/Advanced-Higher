local net = require "@lune/net"
local errorPage = {}

function errorPage:load(
	request: net.ServeRequest,
	status: number,
	error: string
): net.ServeResponse | string
	return `An error occured in /testing: {status}\n{error}`
end

return errorPage
