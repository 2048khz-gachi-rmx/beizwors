
local function doEet()
	local GM = GM or GAMEMODE
	GM.RealOnUndo = GM.RealOnUndo or GM.OnUndo

	function GM:OnUndo( name, strCustomString )
		if math.random() < 0.005 then
			local str = "#Undone_" .. name
			local tran = language.GetPhrase(str):gsub("^Undone ", "")
			strCustomString = "You Can (Not) Redo " .. tran
		end

		return GM.RealOnUndo(self, name, strCustomString)
	end
end

if not GM and not GAMEMODE then
	hook.Add("PostGamemodeLoaded", "undo", function() doEet() end)
else
	doEet()
end
