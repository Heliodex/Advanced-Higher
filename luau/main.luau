-- local framework = require "framework"

local template = require "framework/template"

print(template.parse([[
	testing \{
	template
	lel 
	{# block time \#}y #}
		more string {i}
		{ heh \}y }
	{# end #}
]]))

-- framework
-- 	:new({
-- 		verbose = true,
-- 	})
-- 	:public()
-- 	:routes()
-- 	:listen(3590)
