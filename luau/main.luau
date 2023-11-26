local framework = require "framework"
local t = require "framework/template"

local BASE = t.BASE
local div = t.div
local span = t.span
local p = t.p
local h1 = t.h1

framework
	:new({
		verbose = true,
	})
	-- :mount("/public", "/test")
	:get("/", function()
		return BASE(
			"test page",
			div {
				h1 "Hello, world!",
				"This is my web page!",
				span ".test" "I'm a span!",
				p ".test" "I'm a paragraph!",
			}
		)
	end)
	:get("/test", function()
		return h1 "hi"
	end)
	:post("/form", function()
		return "lel ok"
	end)
	:listen(3590)
