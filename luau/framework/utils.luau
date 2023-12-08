local net = require "@lune/net"
local utils = {}

function utils.randomString(length: number): string
	local str = ""
	for _ = 1, length do
		str ..= string.char(
			if math.random(1, 2) == 1
				then math.random(65, 90)
				else math.random(97, 122)
		)
	end
	return str
end

function utils.merge(t1: { [string]: any }, t2: { [string]: any })
	local t3 = {}

	for k, v in t1 do
		t3[k] = v
	end
	for k, v in t2 do
		t3[k] = v
	end

	return t3
end

function utils.parseBody(body: string): { [string]: string }
	local t = {}
	for k, v in string.gmatch(body, "([^&=]+)=([^&=]+)") do
		v = string.gsub(v, "+", " ")
		t[k] = net.urlDecode(v)
	end

	return t
end

return utils
