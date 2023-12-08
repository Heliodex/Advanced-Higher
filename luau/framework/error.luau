local net = require "@lune/net"

return function(
	status: number,
	message: string?,
	headers: { [string]: string }?
): net.ServeResponse
	return {
		_error = true,
		status = status,
		body = message or `Error ${status}`,
		headers = headers,
	}
end
