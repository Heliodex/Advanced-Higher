local auth = require "auth"
local query = require "db"

local fw = require "framework"
local Redirect = fw.redirect
local utils = fw.utils
local page: fw.Page = {}

function page.load(request): fw.Data
	local loggedIn = auth.loggedIn(request.headers.cookie)
	if loggedIn.redirect then
		return loggedIn.redirect
	end

	return {
		posts = query [[
			SELECT post.id, post.time, post.content, user.username FROM post
			JOIN user ON post.username = user.username
			ORDER BY post.time DESC
			LIMIT 10]],
	}
end

page.actions = {
	default = function(request): fw.Response
		local loggedIn = auth.loggedIn(request.headers.cookie)
		if loggedIn.redirect then
			return loggedIn.redirect
		end

		local content = utils.parseBody(request.body).content

		query(
			[[
				INSERT INTO post (content, username)
				SELECT ?, user.username
				FROM user
				JOIN session ON user.username = session.username
				WHERE session.id = ?]],
			content,
			loggedIn.cookie
		)

		return Redirect(302, "/")
	end,
}

return page
