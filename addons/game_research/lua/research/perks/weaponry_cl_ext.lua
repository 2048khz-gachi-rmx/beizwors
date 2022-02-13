--

hook.Add("ArcCW_CL_AttAllowed", "Research_Lock", function(attId)
	if not attId or attId == "" then return end

	if not Research.AttAllowed(CachedLocalPlayer(), attId) then
		return false, true
	end

	-- return false, true
end)

local fnt = "EX32"
local bfnt = Fonts.GenerateBlur(fnt, 3)

hook.Add("ArcCW_CL_GenAttInfo", "Research_Info", function(pnl, att, attName, wep, i)
	local slot = wep.Attachments[i]
	local slotName = slot.Slot

	local can, needLv = Research.AttAllowed(CachedLocalPlayer(), attName, true)

	if not can then
		local tx = vgui.Create("DPanel", pnl)
		tx:Dock(TOP)
		tx:SetTall(draw.GetFontHeight(fnt))

		if not needLv then
			needLv = -1
		end

		local lv = Research.ACW_AttPerk:GetLevel(needLv)
		local name = lv and lv:GetName() or "...some research? Lv. " .. needLv

		function tx:Paint(w, h)
			local tx = "Requires research (" .. name .. ")"

			for i=1, 2 do
				draw.SimpleText2(tx, bfnt, w / 2, 0, color_black, 1)
			end
			draw.SimpleText2(tx, fnt, w / 2, 0, Colors.Red, 1)
		end
	end
end)