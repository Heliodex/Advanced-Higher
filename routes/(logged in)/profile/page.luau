local algos = require "algos"
local query = require "db"

local fw = require "framework"
local Error = fw.error
local utils = fw.utils
local page: fw.Page = {}

type Post = {
	id: number,
	username: string,
	time: string,
	content: string,
}

function page.load(request): fw.Data
	local username = request.query.user
	if not username then
		return Error(400, "No user specified")
	end

	local posts: { Post } = query(
		[[
			SELECT post.id, post.time, post.content, user.username FROM post
			JOIN user ON post.username = user.username
			WHERE user.username = ?
			LIMIT 10]],
		username
	) or {}

	posts = algos.bubbleSortBy(posts, "id")
	posts = utils.reverse(posts)

	return {
		username = username,
		posts = posts,
	}
end

return page
