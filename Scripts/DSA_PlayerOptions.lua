if not DSA then DSA = setmetatable({}, {__index = _G, __call = function(self, a) setfenv(a, self) return a end}) end
setfenv(1, DSA)

ItemsStartX = 0
ItemsEndX = 9999

-- store playeroptions 
ActiveMods = {{}, {}}

Lines = {
	Default = {'SpeedModType', 'SpeedMod'},
}
LineNames = table.concat(Lines.Default, ',')

PlayerOptionsList = {
	SpeedModType = {
		Name = 'Speed Mod Type',
		Choices = {'X (Multiply)', 'C (Constant)', 'M (Maximum)'},
		Values = {'X', 'C', 'M'},
		LayoutType = 'ShowOneInRow',
		SaveSelections = function(self, list, pn)
			for i=1,#list do
				if list[i] then
					ActiveMods[pn + 1].SpeedModType = self.Values[i]
				end
			end
			PlayerOptionsList.SpeedMod.Refresh(pn + 1)
		end,
	},

	SpeedMod = {
		Name = 'Speed Mod',
		Pos = {1, 1},
		Choices = {' ', ' ', ' '},
		LayoutType = 'ShowOneInRow',
		LoadSelections = function(self, list, pn) self.Pos = {1, 1} list[1] = true return list end,
		SaveSelections = function(self, list, pn)
			local mods = ActiveMods[pn + 1]
			local speedtype = mods.SpeedModType or 'X'
			print(mods.SpeedMod, self.Pos)
			local speed = mods.SpeedMod or 100
			local inc = 5
			for i = 1, table.getn(list) do
				if list[i] then
					if self.Pos[pn + 1] == math.mod((i + 2), table.getn(list)) then speed = speed + inc end
					if self.Pos[pn + 1] == math.mod((i + 1), table.getn(list)) then speed = speed - inc end
					self.Pos[pn + 1] = math.mod(i, table.getn(list))
				end
			end
			mods.SpeedMod = speed
			self.Refresh(pn + 1)
			-- Set.Cursor('SpeedMod', pn + 1)
		end,
		Refresh = function(pn)
			if not ActiveMods[pn].SpeedMod then return end
			local rate = ActiveMods.Rate or 1
			local type = ActiveMods[pn].SpeedModType or 'X'
			local speed = ActiveMods[pn].SpeedMod / (type == 'X' and rate or 1)
			-- local bpm = SongInfo.BPM[1] or '...'
			-- if tonumber(bpm) then
				-- bpm = bpm * rate * speed / 100
				-- if tonumber(SongInfo.BPM[2]) then
					-- bpm = bpm .. ' - ' .. SongInfo.BPM[2] * rate * speed / 100
				-- end
			-- end
			speed = type == 'X' and string.format('%.2f', speed / 100) .. string.lower(type) or string.lower(type) .. speed
			Set.Text('SpeedMod', speed, pn)
		end,
	},
}

-- metatable magic
local OptionRowDefault = {
	__index = function(self, name)
		if not PlayerOptionsList[name] then return false end
		print('Initializing row:', name)
		self.Name = name

		if PlayerOptionsList[name].Values then
			if PlayerOptionsList[name].Choices then
				self.Choices = type(PlayerOptionsList[name].Choices) == 'function' and PlayerOptionsList[name].Choices() or PlayerOptionsList[name].Choices
			else
				self.Choices = {}
				for i, v in ipairs( (type(PlayerOptionsList[name].Values) == 'function' and PlayerOptionsList[name].Values() or PlayerOptionsList[name].Values) ) do
					self.Choices[i] = v
				end
			end
			self.Values = type(PlayerOptionsList[name].Values) == 'function' and PlayerOptionsList[name].Values() or PlayerOptionsList[name].Values
		else
			self.Choices = type(PlayerOptionsList[name].Choices) == 'function' and PlayerOptionsList[name].Choices() or PlayerOptionsList[name].Choices
		end

		self.LayoutType = PlayerOptionsList[name].LayoutType or 'ShowAllInRow'
		self.SelectType = PlayerOptionsList[name].SelectType or 'SelectOne'
		self.OneChoiceForAllPlayers = PlayerOptionsList[name].OneChoiceForAllPlayers or false
		self.ExportOnChange = PlayerOptionsList[name].ExportOnChange or true

		if self.SelectType == 'SelectOne' then
			self.LoadSelections = PlayerOptionsList[name].LoadSelections or function(subself, list, pn)
				local choice = ActiveMods[pn + 1][name] or self.Choices[1]
				local i = FindInTable(choice, (self.Values or self.Choices)) or 1
				list[i] = true
				return list
			end
			self.SaveSelections = PlayerOptionsList[name].SaveSelections or function(subself, list, pn)
				local vals = self.Values or self.Choices
				for i, val in ipairs(vals) do
					if list[i] then ActiveMods[pn + 1][name] = val break end
				end
			end
		else
			self.LoadSelections = PlayerOptionsList[name].LoadSelections or function(subself, list, pn)
				local vals = self.Values or self.Choices
				for i, mod in ipairs(vals) do
					list[i] = ActiveMods[pn + 1][mod] or false
				end
				return list
			end
			self.SaveSelections = PlayerOptionsList[name].SaveSelections or function(subself, list, pn)
				local vals = self.Values or self.Choices
				for i, mod in ipairs(vals) do
					ActiveMods[pn + 1][mod] = list[i]
				end
			end
		end

		-- make extra arguments accessible
		for arg, val in pairs(PlayerOptionsList[name]) do
			if not self[arg] then self[arg] = val end
		end

		-- required, but unused
		self.EnabledForPlayers = {PLAYER_1, PLAYER_2}
		self.ReloadRowMessages = {}

		return self
	end
}

function CustomOptionRow(name)
	local OptionRow = setmetatable({}, OptionRowDefault)
	return OptionRow[name]
end

Set = {
	Text = function(name, text, pn)
		if not Rows[name] then return end
		pn = pn or 1
		-- print(name, text, pn, Rows[name])
		Rows[name].Text[pn]:settext(text)
	end
}

Rows = {}

do
	-- use Simply Love's method of checking and storing actors for easy access, then we can get a proper set up
	local Actors = {
		Ignore = {},
		Row = {},
		Underline = {},
		Cursor = {Sprite = {}},
		Highlight = {},
		Text = {}
	}
	local index = 0
	local Screen = SCREENMAN
	function FrameOn(self)
		self:propagate(1)
		for i=1,3 do self:queuecommand('Capture') end
		self:queuecommand('Set')
	end

	function FrameCapture(self)
		if Screen():GetChild('Frame'):GetChild('Page') == self then
			index = index + 1
			return
		end
		for j,v in ipairs({'More','DisqualifiedP1','DisqualifiedP2'}) do
			if Screen():GetChild('Frame'):GetChild(v) == self then
				return
			end
		end
		for j,v in ipairs(Actors.Ignore) do
			if v == self then
				return true
			end
		end

		if index == 1 then -- option rows, cursors, and line highlights
			local row = {}
			if IsType(self,'ActorFrame') then
				if IsType(self:GetChild(''),'ActorFrame') then
					table.insert(Actors.Row, self:GetChild(''))
					self:propagate(1)
					self:GetChild(''):propagate(1)
				end
				if IsType(self:GetChild(''),'Sprite') then
					table.insert(Actors.Cursor, self)
					table.insert(Actors.Cursor.Sprite, {})
					self:propagate(1)
				end
			elseif IsType(self,'Sprite') then
				table.insert(Actors.Highlight, self)
			end
		 
		elseif index == 2 then -- cursor sprites, title and item text, and underlines
	 
			if IsType(self,'Sprite') then
				for j,v in ipairs(Actors.Cursor.Sprite) do
					if not v[3] then
						table.insert(v,self)
						table.insert(Actors.Ignore,self)
						return
					end
				end
				table.insert(Actors.Text, {}) -- This will be the Bullets, one per option row, and they come before the text.
			elseif IsType(self,'BitmapText') then -- First index is the row Title, the rest of the items.
				table.insert(Actors.Text[table.getn(Actors.Text)], self)
			elseif IsType(self,'ActorFrame') and self:GetNumChildren() == 3 then
				table.insert(Actors.Underline,{Row = table.getn(Actors.Text)})
				self:propagate(1)
			end
		 
		elseif index == 3 then  -- underline sprites
			Screen():GetChild('Frame'):propagate(0)
			for j,v in ipairs(Actors.Underline) do
				if not v[3] then
					table.insert(v,self)
					if v[3] then
						-- InitializeOptionRow(j)
					end
					return
				end
			end
		end

		table.insert(Actors.Ignore,self)
	end

	function FrameSet()
		local poa = Rows
		for i, v in ipairs(Actors.Text) do
			local name = table.remove(v, 1):GetText() 
			poa[name] = {Name = name, Text = v}
		end
	end
end

function CancellAll()
	print('CancelAll')
end