local algos = require "algos"
local query = require "db"
local net = require "@lune/net"

local fw = require "framework"
local page: fw.Page = {}

type Post = {
	id: number,
	username: string,
	time: string,
	content: string,
}

function page.load(request): fw.Data
	local search = request.query.q
	if not search then
		return {
			search = "",
		}
	end

	search = net.urlDecode(search)
	search = string.gsub(search, "+", " ")

	local posts: { Post } = query [[
		SELECT post.id, post.time, post.content, user.username FROM post
		JOIN user ON post.username = user.username]] or {}

	posts = algos.insertionSortBy(posts, "content")
	local position = algos.binarySearchBy(posts, "content", search)

	print(search, position, posts[4].content == search)

	return if position < 0
		then {
			search = search,
		}
		else {
			search = search,
			posts = { posts[position] },
		}
end

return page
