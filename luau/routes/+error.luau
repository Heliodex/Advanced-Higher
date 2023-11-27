local net = require "@lune/net"
local errorPage = {}

function errorPage:load(
	request: net.ServeRequest,
	status: number,
	error: string
): net.ServeResponse | string
	print("error:", typeof(error))
	return `An error occured: {status}\n{error}`
end

return errorPage
