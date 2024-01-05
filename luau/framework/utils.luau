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

function utils.timeSince(time: string): string
	local year, month, day, hour, minute, second =
		string.match(time, "(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")

	local now = os.time()
	local ago = os.time {
		year = year,
		month = month,
		day = day,
		hour = hour,
		min = minute,
		sec = second,
	}

	local diff = now - ago

	local function fd(y)
		-- no floor division operator in Lune 😒
		return math.floor(diff / y)
	end

	local m = 60
	local h = m * 60
	local d = h * 24
	local w = d * 7
	local mo = d * 30
	local y = d * 365

	return if diff < 5
		then "just now"
		elseif diff < m then `{diff} seconds ago`
		elseif diff < m * 2 then "a minute ago"
		elseif diff < h then `{fd(m)} minutes ago`
		elseif diff < h * 2 then "an hour ago"
		elseif diff < d then `{fd(h)} hours ago`
		elseif diff < d * 2 then "yesterday"
		elseif diff < w then `{fd(d)} days ago`
		elseif diff < w * 2 then "a week ago"
		elseif diff < mo then `{fd(w)} weeks ago`
		elseif diff < mo * 2 then "a month ago"
		elseif diff < y then `{fd(mo)} months ago`
		elseif diff < y * 2 then "a year ago"
		else `{fd(y)} years ago`
end

return utils
