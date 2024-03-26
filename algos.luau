local algos = {}

function algos.bubbleSort<T>(l: { T })
	local list = (l :: unknown) :: { string | number }
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
	return (list :: unknown) :: { T }
end

function algos.bubbleSortBy<T>(l: { T }, key: string)
	local list = (l :: unknown) :: { { [string]: string | number } }
	local swapped = true
	local n = #list
	while swapped do
		swapped = false
		for i = 1, n - 1 do
			if list[i][key] > list[i + 1][key] then
				list[i], list[i + 1] = list[i + 1], list[i]
				swapped = true
			end
		end
		n -= 1
	end
	return (list :: unknown) :: { T }
end

function algos.insertionSort<T>(l: { T })
	local list = (l :: unknown) :: { string | number }
	for i = 2, #list do
		local value = list[i]
		local index = i
		while index > 1 and value < list[index - 1] do
			list[index] = list[index - 1]
			index -= 1
		end
		list[index] = value
	end
	return (list :: unknown) :: { T }
end

function algos.insertionSortBy<T>(l: { T }, key: string)
	local list = (l :: unknown) :: { { [string]: string | number } }
	for i = 2, #list do
		local value = list[i]
		local index = i
		while index > 1 and value[key] < list[index - 1][key] do
			list[index] = list[index - 1]
			index -= 1
		end
		list[index] = value
	end
	return (list :: unknown) :: { T }
end

function algos.binarySearch<T>(l: { T }, v: T)
	local list = (l :: unknown) :: { string | number }
	local value = (v :: unknown) :: string | number

	local left = 1
	local right = #list
	while left <= right do
		local mid = (left + right) // 2
		if list[mid] == value then
			return mid
		elseif list[mid] < value then
			left = mid + 1
		else
			right = mid - 1
		end
	end
	return -1
end

function algos.binarySearchBy(
	list: { any },
	key: string,
	value: string | number
)
	local left = 1
	local right = #list
	while left <= right do
		local mid = (left + right) // 2
		if list[mid][key] == value then
			return mid
		elseif list[mid][key] < value then
			left = mid + 1
		else
			right = mid - 1
		end
	end
	return -1
end

return algos
