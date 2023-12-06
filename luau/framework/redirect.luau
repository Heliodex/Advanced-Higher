local net = require "@lune/net"

local function merge(t1: { [string]: any }, t2: { [string]: any })
	local t3 = {}

	for k, v in t1 do
		t3[k] = v
	end
	for k, v in t2 do
		t3[k] = v
	end

	return t3
end

return function(
	status: number,
	path: string,
	headers: { [string]: string }?
): net.ServeResponse
	return {
		_raw = true,
		status = status,
		headers = merge({
			Location = path,
		}, headers or {}),
	}
end
