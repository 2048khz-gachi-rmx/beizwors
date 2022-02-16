local PLAYER = debug.getregistry().Player



Raids = Raids or {}

local raid = Raids

raid.Cooldowns = raid.Cooldowns or {}
raid.OngoingRaids = raid.OngoingRaids or {}

RaidCoolDown = 900 --15 min
RaidDuration = 360 --6 min

include("raid_meta_ext_cl.lua")

local function Valid()
	return Raids.Frame and IsValid(Raids.Frame)
end

function Raids.CallRaid(what, fac)
	local pr

	if fac then
		pr = net.StartPromise("Raid")
			net.WriteUInt(2, 4) --fac vs fac
			net.WriteUInt(IsFaction(what) and what:GetID() or what, 24)
		net.SendToServer()
	else
		if not IsPlayer(what) then return end
		pr = net.StartPromise("Raid")
			net.WriteUInt(1, 4) --ply vs ply
			net.WriteEntity(what)
		net.SendToServer()
	end

	return pr
end

function Raids.ConcedeRaid()
	pr = net.StartPromise("Raid")
		net.WriteUInt(3, 4) -- concede
	net.SendToServer()

	return pr
end

function PLAYER:IsRaider() --localplayer's raid only

	if not raid.MyRaid then return false end

	if raid.MyRaid then
		if raid.MyRaid.Raided and (raid.MyRaid.Raided.id == self:Team() or raid.MyRaid.Raided == self) then return false end
		if raid.MyRaid.Raider and (raid.MyRaid.Raider.id == self:Team() or raid.MyRaid.Raider == self) then return true end
		return false --?
	else
		return false
	end
end

function PLAYER:IsEnemy()
	if not raid.MyRaid then return false end

	local rd = raid.MyRaid

	local my = rd:GetSide(LocalPlayer())
	local their = rd:GetSide(self)

	if my == 0 or their == 0 then return false end

	return my ~= their
end

function PLAYER:IsRaidable()
	if not self:IsValid() then return end

	local can, err = raid.CanGenerallyRaid(self, true)
	if can == false then
		return can, err
	end

	can, err = raid.CanRaidPlayer(LocalPlayer(), self)
	if can == false then
		return can, err
	end

	return true
end

function raid.IsParticipant(obj)
	return raid.Participants[obj]
end

net.Receive("Raid", function()
	local hasReply = net.ReadBool()
	local rep

	if hasReply then
		local promise, ok = net.ReadPromise()
		rep = promise

		if ok == false then return end
	end

	local mode = net.ReadUInt(4)
	--1 = start ply vs ply
	--2 = start fac vs fac
	--3 = end
	--4 = err

	if mode == 1 then
		-- ply on ply
		local rder = net.ReadUInt(24)
		local rded = net.ReadUInt(24)

		local start = net.ReadFloat()
		local id = net.ReadUInt(16)

		if IsPlayer(Player(rder)) then rder = Player(rder) end
		if IsPlayer(Player(rded)) then rded = Player(rded) end

		local r = raid.RaidMeta:new(rder, rded, start, id, false)
		raid.OngoingRaids[id] = r

		CreateRaidButton(id, r)

		return
	elseif mode == 2 then
		-- fac on fac
		local rder = net.ReadUInt(24)
		local rded = net.ReadUInt(24)

		local start = net.ReadFloat()
		local id = net.ReadUInt(16)

		local rderfac = Factions.FactionIDs[rder]
		local rdedfac = Factions.FactionIDs[rded]

		local r = raid.RaidMeta:new(rderfac, rdedfac, start, id, true)
		raid.OngoingRaids[id] = r

		CreateRaidButton(id, r)

		return
	elseif mode==3 then
		-- stop the raid
		local id = net.ReadUInt(16)
		print("Stopping raid, ID:" .. id)

		if not raid.OngoingRaids[id] then
			errorf("Attempted to stop a non-existent raid with ID: %d.", id)
			return
		end

		if raid.MyRaid == raid.OngoingRaids[id] then raid.MyRaid = nil end
		raid.OngoingRaids[id]:Stop()

		if Valid() and Raids.Frame.Raids[id] and IsValid(Raids.Frame.Raids[id]) then
			Raids.Frame.Raids[id]:PopOut()
			Raids.Frame.Raids[id] = nil
		end

		hook.Run("OnRaidStop", id)
		return
	end


end)

local wasopen = false

function CreateRaidFrame(noanim)

	local f
	if IsValid(Raids.Frame) then return end

	if IsValid(g_ContextMenu) then
		f = vgui.Create("FFrame", g_ContextMenu)
	else
		return
	end

	if not f then return false end --?


	local sw = ScrW()
	local sh = ScrH()

	local scale = sw / 1920

	f:SetSize(scale*600, 192)
	f:Hide()	-- !!!!!!!!!! DISABLED !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	f:SetPos(ScrW()/2 - scale*300, 36)

	f.Label = "Raids"
	if not noanim then
		f:PopIn(0.1, 1, function(_,s)
			s:PopOut(nil, 2, function() end)
		end)
	end

	f.scr = vgui.Create("FScrollPanel", f)
	f.scr:Dock(FILL)

	f.Raids = {}

	if noanim then
		f:SetAlpha(0)
	else
		timer.Simple(1.5, function()
			if IsValid(f) and not wasopen then
				f:PopOut(nil, nil, function() end) --dont remove
			end
		end)
	end

	Raids.Frame = f
	function Raids.Frame:PostPaint(w,h)

	end

	return f
end
function CreateRaidButton(id, v)
	local scale = ScrW()/1920
	if not Valid() then CreateRaidFrame(true):SetAlpha(0) end

	if Valid() and not Raids.Frame.Raids[id] and Raids.Frame.scr then
		local f = vgui.Create("FButton", Raids.Frame.scr )
		f:Dock(TOP)
		f:DockMargin(16, 8, 16, 8)



		f.DrawShadow = false

		f.VSFac = v.VSFac
		f:SetTall((v.VSFac and 48) or 32)
		f.Raider = v.Raider
		f.Raided = v.Raided

		f.Start = v.Start
		f.PartOf = v:IsParticipant(LocalPlayer())

		f.Font = "EXM20"

		if raid.MyRaid and raid.MyRaid.Panel and IsValid(raid.MyRaid.Panel) then
			raid.MyRaid.Panel:Remove()
			raid.MyRaid.Panel = nil
		end

		if f.PartOf then
			f:Dock(NODOCK)
			f:SetParent(vgui.GetWorldPanel())

			f:SetPos(2, 24)
			f:SetSize(scale * 800, 50)
			f:CenterHorizontal()
			f.Font = "OSB32"
			raid.MyRaid.Panel = f
		end
		local lkname1 = ""
		local lkname2 = ""

		local parCol = Color(50, 150, 250)
		local nonparCol = Color(40, 90, 120)

		function f:PostPaint(w, h)
			local frac = v:GetLeft() / RaidDuration

			if frac <= 0.01 or not raid.MyRaid then
				self:PopOut()
				if Valid() then Raids.Frame.Raids[id] = nil end
				if f.PartOf and raid.MyRaid and raid.MyRaid.Panel == self then raid.MyRaid.Panel = nil end
			end

			local col = (self.PartOf and parCol) or nonparCol

			local t = math.max(math.Round(v:GetLeft(), 1), 0)


			if (v.VSFac and v.Raider.name) or IsPlayer(v.Raider) then
				lkname1 = (v.VSFac and v.Raider.name) or (v.Raider.Nick and v.Raider:Nick()) or "???"
			end

			if (v.VSFac and v.Raided.name) or IsPlayer(v.Raided) then
				lkname2 = (v.VSFac and v.Raided.name) or (v.Raided.Nick and v.Raided:Nick()) or "???"
			end

			local name1, name2 = lkname1, lkname2

			if utf8.len(name1) > 16 then
				name1 = utf8.sub(name1, 1, 13) .. "..."
			end

			if utf8.len(name2) > 16 then
				name2 = utf8.sub(name2, 1, 13) .. "..."
			end

			draw.RoundedBox(8, 0, 0, w*frac, h, col)
			draw.SimpleText(name1, "OS24", 8, h/2, color_white, 0, 1)
			draw.SimpleText(name2, "OS24", w - 8, h/2, color_white, 2, 1)

			draw.SimpleText(t .. "s. remaining", self.Font, w/2, h/2, color_white, 1, 1)

		end

		Raids.Frame.Raids[id] = f
	end

end


hook.Add("CalcView", "RaidOnLoad", function()
	CreateRaidFrame()

	for id,v in pairs(raid.OngoingRaids) do
		CreateRaidButton(id, v)
	end

	hook.Remove("CalcView", "RaidOnLoad")
end)


hook.Add("OnContextMenuOpen", "RaidOpen", function()
	if not IsValid(Raids.Frame) then CreateRaidFrame(true) end

	wasopen = true

	Raids.Frame:PopIn(nil, nil, function(_,s) if not Raids.Frame.PoppingOut and IsValid(s) then s:MakePopup() s:SetKeyBoardInputEnabled(false) else print('no') end end)
	Raids.Frame.PoppingOut = false
end)

hook.Add("OnContextMenuClose", "RaidClose", function()
	if not IsValid(Raids.Frame) then return end

	Raids.Frame.PoppingOut = true

	Raids.Frame:SetKeyBoardInputEnabled(false)
	Raids.Frame:SetMouseInputEnabled(false)

	Raids.Frame:PopOut(nil, nil, function() end)

end)

function Raids.CanBlowtorch(ply, ent, wep)

	local ow = ent:BW_GetOwner()

	if not IsPlayerInfo(ow) then
		return false
	end

	if ow == GetPlayerInfo(ply) then
		return true
	end

	if not ow:IsValid() then return false end -- see raid.CanDealDamage
	if ent.AlwaysRaidable then return false end

	if ow:IsEnemy(ply) then
		local can = hook.Run("BW_CanBlowtorch", ply, ent, wep) ~= false
		return can -- raider -> raided allowed
	else
		return hook.Run("BW_CanBlowtorchRaidless", ply, ent, wep)
	end
end

local function alert(rded)
	system.FlashWindow()
	if rded then
		surface.PlaySound("npc/attack_helicopter/aheli_damaged_alarm1.wav")
	else
		surface.PlaySound("mvm/mvm_warning.wav")
	end
end

hook.NHAdd("RaidStart", "NotifySound", function(rd, rder, rded, fac)
	-- npc/attack_helicopter/aheli_damaged_alarm1.wav
	-- NPC_AttackHelicopter.BadlyDamagedAlert
	if rd:IsRaider(LocalPlayer()) then
		alert(false)
	elseif rd:IsRaided(LocalPlayer()) then
		alert(true)
	end
end)