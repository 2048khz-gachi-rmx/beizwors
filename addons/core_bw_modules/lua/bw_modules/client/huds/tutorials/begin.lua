do
	local tut = BaseWars.Tutorial
	local ptr = tut.AddStep(1, "The Basics")

	local col = Color(230, 230, 230)

	function ptr:PaintBegin(cury)
		self:CompletePoint(1, not not LocalPlayer():BW_GetBase())
		return self:PaintPoints(cury)
	end

	ptr:AddPaint(999, "PaintFrame", ptr)
	ptr:AddPaint(998, "PaintName", ptr)
	ptr:AddPaint(997, "PaintBegin", ptr)

	ptr:AddPoint(1, "Find a base")
	ptr:AddPoint(2, "Claim the core")

	ptr:On("Appear", "trk", function()
		ptr:CompletePoint(1, not not LocalPlayer():BW_GetBase())
		ptr:CompletePoint(2, not not LocalPlayer():GetBase())
	end)

	hook.Add("BaseClaimed", "TutorialTrack", function(base)
		if base:IsOwner(LocalPlayer()) then
			ptr:CompletePoint(2, true)
		end
	end)

	hook.Add("BaseUnclaimed", "TutorialTrack", function(base)
		if not LocalPlayer():GetBase() then
			ptr:CompletePoint(2, false)
		end
	end)
end

do
	local tut = BaseWars.Tutorial
	local ptr = tut.AddStep(2, "Purchases")

	local col = Color(230, 230, 230)

	function ptr:PaintBuy(cury)
		self:CompletePoint(1, not not spawnmenu.BaseWarsOpened)
		return self:PaintPoints(cury)
	end

	ptr:AddPaint(999, "PaintFrame", ptr)
	ptr:AddPaint(998, "PaintName", ptr)
	ptr:AddPaint(997, "PaintBuy", ptr)

	ptr:AddPoint(1, "Check the BaseWars tab in your spawnmenu")
	ptr:AddPoint(2, "Buy a Manual Generator from the Entities tab")
	ptr:AddPoint(3, "Buy a Manual Printer from the Printers tab")

	local function tryTrack(ent)
		if not ent:BW_IsOwner(LocalPlayer()) then return end

		if ent.IsManualGen then
			ptr:CompletePoint(2, true)
		elseif ent.IsManualPrinter then
			ptr:CompletePoint(3, true)
		end
	end

	hook.Add("EntityOwnershipChanged", "TrackBuyTutorial", function(ply, ent)
		if ply ~= LocalPlayer() then return end
		tryTrack(ent)
	end)

	ptr:On("Appear", "TryTrack", function()
		for k,ent in ipairs(ents.FindByClass("*bw_*")) do
			tryTrack(ent)
		end

		BaseWars.SpawnMenu.Highlight["bw_printer_manual"] = true
		BaseWars.SpawnMenu.Highlight["bw_gen_manual"] = true
	end)

	ptr:On("Completed", "RemoveHilite", function()
		BaseWars.SpawnMenu.Highlight["bw_printer_manual"] = nil
		BaseWars.SpawnMenu.Highlight["bw_gen_manual"] = nil
	end)
end