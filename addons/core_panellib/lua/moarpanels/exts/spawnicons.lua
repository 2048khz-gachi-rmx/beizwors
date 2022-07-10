
local surface_DrawTexturedRect = surface.DrawTexturedRect
local surface_SetMaterial = surface.SetMaterial

local mdls = {}

if IsValid(MoarPanelsSpawnIcon) then MoarPanelsSpawnIcon:Remove() end

local function GetSpawnIcon()

	if not IsValid(MoarPanelsSpawnIcon) then
		MoarPanelsSpawnIcon = vgui.Create("SpawnIcon")
		local spic = MoarPanelsSpawnIcon
		spic:SetSize(64, 64)
		spic:SetAlpha(1)
	end

	return MoarPanelsSpawnIcon
end


local upscale = function(w, h)
	return bit.lshift(1, math.Clamp(math.ceil(math.log(w, 2)), 6, 9)),
		bit.lshift(1, math.Clamp(math.ceil(math.log(h, 2)), 6, 9))
end

function draw.DrawOrRender(pnl, mdl, x, y, w, h)

	local icname = mdl

	icname = icname:gsub("%.mdl", "")

	if not icname:find("%.png") then
		icname = icname .. ".png"
	end

	if not mdls[mdl] then

		mdls[mdl] = Material("spawnicons/" .. icname)

		if mdls[mdl]:IsError() then
			local spic = GetSpawnIcon()

			spic:SetSize(upscale(w, h))
			spic:SetModel(mdl)
			spic:RebuildSpawnIcon()
			mdls[mdl] = true

			local hkName = mdl

			hook.Add("SpawniconGenerated", hkName, function(mdl2, ic, amt)
				if mdl == mdl2 then hook.Remove("SpawniconGenerated", hkName) end
				--mdls[mdl] = Material(ic)
				if amt == 1 and IsValid(spic) then spic:Remove() end
			end)
			return
		end

		draw.DrawLoading(pnl, x + w/2, y + h/2, w, h)
	elseif isbool(mdls[mdl]) then
		draw.DrawLoading(pnl, x + w/2, y + h/2, w, h)
		return
	end

	surface_SetMaterial(mdls[mdl])
	surface_DrawTexturedRect(x, y, w, h)

end

local queue = {}
local rendering = 0

local function queueNext(spic)
	local mdl, cur = next(queue)
	if not cur then
		hook.Remove("SpawniconGenerated", "IconRenderQueue")
		spic:Remove()
		return
	end

	local sz = cur[#cur]
	if not sz then
		print("how is this possible - no cur?", mdl)
		return
	end

	rendering = rendering + 1

	cur[#cur] = nil

	spic:SetModel(mdl)
	spic:SetSize(upscale(sz, sz))
	spic:RebuildSpawnIcon()

	if #cur == 0 then
		queue[mdl] = nil
	end
end

function draw.ForceRenderSpawnicon(mdl, sz)
	local kickstart = table.IsEmpty(queue) and rendering == 0

	queue[mdl] = queue[mdl] or {}
	table.insert(queue[mdl], sz)

	if kickstart then
		local spic = GetSpawnIcon()

		hook.Add("SpawniconGenerated", "IconRenderQueue", function(mdl2, ic, amt)
			rendering = rendering - 1
			timer.Simple(0.05, function()
				queueNext(spic)
			end)
		end)

		queueNext(spic)
	end
end

