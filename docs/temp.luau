function()
	local _rendered = ""
	print "loading page..."
	_rendered ..= `You are {username}\n\n`
	for num = 1, 5 do
		_rendered ..= `{num}\n`
	end
	return _rendered
end
