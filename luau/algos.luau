local algos = {}

function algos.bubbleSort(list: { number })
	local swapped = true
	local n = #list
	while swapped do
		swapped = false
		for i = 1, n - 1 do
			if list[i] > list[i + 1] then
				list[i], list[i + 1] = list[i + 1], list[i]
				swapped = true
			end
		end
		n -= 1
	end
	return list
end

function algos.insertionSort(list: { number })
	local value = 0
	local index = 0
	for i = 2, #list do
		value = list[i]
		index = i
		while index > 0 and value < list[index - 1] do
			list[index] = list[index - 1]
			index -= 1
		end
		list[index] = value
	end
	return list
end

return algos
