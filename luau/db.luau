local net = require "@lune/net"
local db = {}

-- URL of a proxy to the database server (see db.ts)
local url = "http://localhost:3307"

function db:query(query: string, params: { (string | number) }?)
	local res = net.request {
		url = url,
		method = "POST",
		body = net.jsonEncode {
			query = query,
			params = params,
		},
	}

	local body = net.jsonDecode(res.body)

	return if body.rows then body.rows else body
end

db:query "CREATE DATABASE IF NOT EXISTS main"
db:query "USE main"
db:query [[
	CREATE TABLE IF NOT EXISTS user (
		username VARCHAR(255) NOT NULL PRIMARY KEY,
		password VARCHAR(255) NOT NULL
	)]]
db:query [[
	CREATE TABLE IF NOT EXISTS session (
		id VARCHAR(255) NOT NULL PRIMARY KEY,
		username VARCHAR(255) NOT NULL,
		FOREIGN KEY (username) REFERENCES user(username)
	)]]
db:query [[
	CREATE TABLE IF NOT EXISTS post (
		id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
		time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
		content TEXT NOT NULL,
		username VARCHAR(255) NOT NULL,
		FOREIGN KEY (username) REFERENCES user(username)
	)]]

return db
