local framework = require "framework"

framework
	:new({
		verbose = true,
	})
	:public()
	:routes()
	:listen(3590)
