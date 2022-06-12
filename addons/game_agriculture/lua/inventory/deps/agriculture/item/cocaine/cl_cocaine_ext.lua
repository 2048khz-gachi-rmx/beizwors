local cock = Agriculture.MetaCocaine

function cock:PostGenerateText(cloud, mup) end

function cock:GenerateText(cloud, mup)
	local efs = self:GetEffects()
	if not efs or table.IsEmpty(efs) then return end

	cloud.MinW = 250

	for id, str in pairs(efs) do
		local ef = Agriculture.CocaineTypes[id]

		local pc = mup:AddPiece()
			pc:SetAlignment(1)
			pc:SetFont("BSSB24")
			pc:AddText(([[%s]]):format(ef.Result))
			pc:SetColor(ef.TextColor or ef.Color)

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

	mup:Timer(1, 0, 1, function() print(mup:GetTall()) end)
end
