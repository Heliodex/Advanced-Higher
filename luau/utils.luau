local utils = {}

function utils.randomString(length: number): string
	local str = ""
	for _ = 1, length do
		str ..= string.char(
			if math.random(1, 2) == 1
				then math.random(65, 90)
				else math.random(97, 122)
		)
	end
	return str
end

return utils
