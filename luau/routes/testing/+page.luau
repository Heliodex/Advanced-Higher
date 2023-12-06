local net = require "@lune/net"
local db = require "../../db"
local page = {}

function page:load(request: net.ServeRequest): { [string]: any }
	local query = db:query "SELECT 'hello world' AS 'message'"
	return query[1]
end

return page
