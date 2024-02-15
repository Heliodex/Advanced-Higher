local net = require "@lune/net"
local utils = require "utils"

return function(
	status: number,
	path: string,
	headers: { [string]: string }?
): net.ServeResponse
	return {
		_raw = true,
		status = status,
		headers = utils.merge({
			Location = path,
		}, headers or {}),
	}
end
