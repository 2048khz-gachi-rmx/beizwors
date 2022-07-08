local cock = Agriculture.MetaCocaine

function cock:PostGenerateText(cloud, mup) end

function cock:GenerateText(cloud, mup)
	local efs = self:GetEffects()
	if not efs or table.IsEmpty(efs) then return end

	cloud.MinW = 230

	local w = 0
	--printf("gen text %p", mup)
	for id, str in pairs(efs) do
		local ef = Agriculture.CocaineTypes[id]

		local pc = mup:AddPiece()
			pc:SetAlignment(1)
			pc:SetFont("BSSB22")
			pc:AddText(("%s"):format(ef.Result))
			pc:SetColor(ef.TextColor or ef.Color)
			pc:SetTall(20)

		if ef.Markup or ef.Description then
			local dpc = mup:AddPiece()
			dpc:SetAlignment(1)
			dpc:SetFont("BS18")
			dpc:SetColor(Colors.LighterGray)

			if ef.Markup then
				ef.Markup(mup, dpc, str)
			else
				dpc:AddText(ef.Description)
			end
		end
	end

	mup:SetWide(cloud.MinW)
	mup:Recalculate()
end

function cock:GenerateOptions(mn)
	local inv = self:GetInventory()
	if inv ~= Inventory.GetTemporaryInventory(CachedLocalPlayer()) then return end

	local proc = self:GetProcessed()
	if not proc then return end

	local opt = mn:AddOption("Use")
	opt.HovMult = 1.15
	opt.Color = Colors.Sky:Copy()
	opt.DeleteFrac = 0
	opt.Description = "Use 1 charge to gain the listed effects"

	local item = self

	function opt:DoClick()
		local ns = Inventory.Networking.Netstack()
			ns:WriteInventory(inv)
			ns:WriteItem(item, true)
		Inventory.Networking.PerformAction(INV_ACTION_USE, ns)
	end
end