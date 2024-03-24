local auth = require "auth"
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
	local parsedCookie = auth.parseCookie(request.headers.cookie)

		if parsedCookie then
			query("DELETE FROM session WHERE id = ?", parsedCookie)
		end

		return Redirect(302, "/login")
	end,
}

return page
