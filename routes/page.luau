local auth = require "auth"
local algos = require "algos"
local query = require "db"

local fw = require "framework"
local Redirect = fw.redirect
local utils = fw.utils
local page: fw.Page = {}

type Post = {
	id: number,
	username: string,
	time: string,
	content: string,
}

function page.load(request): fw.Data
	local loggedIn = auth.loggedIn(request.headers.cookie)
	if loggedIn.redirect then
		return loggedIn.redirect
	end

	local posts: { Post }? = query [[
		SELECT post.id, post.time, post.content, user.username FROM post
		JOIN user ON post.username = user.username
		LIMIT 10]]

	if not posts then
		return {}
	end

	posts = algos.bubbleSortBy(posts, "id")
	posts = utils.reverse(posts)

	return {
		posts = posts,
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
			loggedIn.cookie :: string
		)

		return Redirect(302, "/")
	end,
}

return page
