if not DSA then DSA = setmetatable({}, {__index = _G, __call = function(self, a) setfenv(a, self) return a end}) end
setfenv(1, DSA)

function RestoreDefaults(pn)
	for i, v in pairs(Defaults) do
		ActiveMods[pn].i = v
	end
end

Defaults = {}
setfenv(1, Defaults)

SpeedModType = 'X'
SpeedModSpeed = 100
Perspective = 'Overhead'
NoteSkin = 'cel'
JudgementFont = 'DSA'
