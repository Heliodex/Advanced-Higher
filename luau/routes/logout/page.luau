local query = require "db"

local fw = require "framework"
local Error = fw.error
local Redirect = fw.redirect
local page: fw.Page = {}

function page.load()
	return Error(404, "Not Found")
end

page.actions = {
	default = function(request): fw.Response
		local cookie = request.headers.cookie
		cookie = cookie and string.match(cookie, "session=([^;]+)")

		query("DELETE FROM session WHERE id = ?", cookie)

		return Redirect(302, "/")
	end,
}

return page
