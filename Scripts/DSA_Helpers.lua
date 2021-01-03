if not DSA then DSA = setmetatable({}, {__index = _G, __call = function(self, a) setfenv(a, self) return a end}) end
setfenv(1, DSA)

do
	function table_scrape(table, prefix, depth)
		depth = depth or 0
		if depth >= 50 then return end
		local old_prefix = prefix
		local string = depth == 0 and '\n##\t' .. tostring(table) or ''
		for key, value in pairs(table) do
			prefix = depth == 0 and ('##\t-\t' .. key) or (old_prefix .. ' -> ' .. key)
			string = string .. '\n' .. prefix .. ' = ' .. tostring(value)
			if type(value) == 'table' or type(value) == 'userdata' then
				string = string .. DSA[type(value) .. '_scrape'](value, prefix, depth + 1)
			end
		end
		return string .. (depth == 0 and '\n' or '')
	end

	local function actor_has_children(actor) actor:GetNumChildren() end

	function userdata_scrape(actor, prefix, depth)
		depth = depth or 0
		if depth >= 50 then return end
		local old_prefix = prefix
		local string = depth == 0 and '\n##    ' .. tostring(actor) or ''
		if pcall(actor_has_children, actor) then
			for index = 0, actor:GetNumChildren() - 1 do
				local child = actor:GetChildAt(index)
				prefix = depth == 0 and ('##    -    ' .. index) or (old_prefix .. (' -> Ch ' .. index .. (child:GetName() ~= '' and (' (' .. child:GetName() .. ')') or '')))
				string = string .. '\n' .. prefix .. ' = ' .. tostring(child)
				if type(child) == 'table' or type(child) == 'userdata' then
					string = string .. DSA[type(child) .. '_scrape'](child, prefix, depth + 1)
				end
			end
		end
		return string .. (depth == 0 and '\n' or '')
	end

	function print(...)
		local string = ''
		for i = 1, arg.n do
			if type(arg[i]) == 'table' or type(arg[i]) == 'userdata' then
				string = string .. DSA[type(arg[i]) .. '_scrape'](arg[i])
				string = string .. '##'
			else
				string = string .. (i == 1 and '' or '    ') .. tostring(arg[i])
			end
		end
		_G.print('##', string)
		return string
	end
end

function FindInTable(needle, haystack)
	for i = 1, table.getn(haystack) do
		if needle == haystack[i] then
			return i
		end
	end
	return nil
end

function IsType(a,t) return string.find(tostring(a), t) end