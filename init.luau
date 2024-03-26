-- This file is the entry point for the application.

local framework = require "framework"

framework
	:new({
		verbose = true,
	})
	:public() -- Serves content from the /public directory
	:routes() -- Shows pages from the /routes directory
	:listen(3590) -- http://localhost:3590/
