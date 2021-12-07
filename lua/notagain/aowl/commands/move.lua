local t = {start=nil,endpos=nil,mask=MASK_PLAYERSOLID,filter=nil}
local function IsStuck(ply)

	t.start = ply:GetPos()
	t.endpos = t.start
	t.filter = ply

	return util.TraceEntity(t,ply).StartSolid

end

-- helper
local function SendPlayer( from, to )
	local ok, reason = hook.Run("CanPlyGotoPly", from, to)
	if ok == false then
		return "HOOK", reason or ""
	end

	if not to:IsInWorld() then
		return false
	end


	local times=16

	local anginc=360/times


	local ang=to:GetVelocity():Length2DSqr()<1 and (to:IsPlayer() and to:GetAimVector() or to:GetForward()) or -to:GetVelocity()
	ang.z=0
	ang:Normalize()
	ang=ang:Angle()

	local pos=to:GetPos()
	local frompos=from:GetPos()


	if from:IsPlayer() and from:InVehicle() then
		from:ExitVehicle()
	end

	local origy=ang.y

	for i=0,times do
		ang.y=origy+(-1)^i*(i/times)*180

		from:SetPos(pos+ang:Forward()*64+Vector(0,0,10))
		if not IsStuck(from) then return true end
	end



	from:SetPos(frompos)
	return false

end

local function Goto(ply,line,target)
	local current_map = game.GetMap()

	-- check if it's a server-change semi-location

	for k,v in pairs(aowl.GotoLocations) do
		if istable(v) then
			if isstring(v.server) then
				local loc, map = k:match("(.*)@(.*)")
				if line == k or (line and map and loc:lower():Trim():find(line,1,true) and string.find(current_map, map,1,true)==1) then
					ply:Cexec("connect " .. v.server:gsub("[^%w.:]",""))
					return
				end
			end
		end
	end

	-- proceed with real goto

	local ok, reason = hook.Run("CanPlyGoto", ply)
	if ok == false then
		return false, reason or ""
	end

	if not ply:Alive() then ply:Spawn() end
	if not line then return end
	local x,y,z = line:match("(%-?%d+%.*%d*)[,%s]%s-(%-?%d+%.*%d*)[,%s]%s-(%-?%d+%.*%d*)")

	if x and y and z and ply:CheckUserGroupLevel("moderators") then
		ply:SetPos(Vector(tonumber(x),tonumber(y),tonumber(z)))
		return
	end

	for k,v in pairs(aowl.GotoLocations) do
		local loc, map = k:match("(.*)@(.*)")
		if target == k or (target and map and loc:lower():Trim():find(target,1,true) and string.find(current_map, map,1,true)==1) then
			if isvector(v) then
				if ply:InVehicle() then
					ply:ExitVehicle()
				end
				ply:SetPos(v)
				return
			elseif isfunction(v) then
				-- let's do this in either case
				if ply:InVehicle() then
					ply:ExitVehicle()
				end

				return v(ply)
			end
		end
	end

	local ent = easylua.FindEntity(target)

	if target=="#somewhere" or  target=="#rnode" then
		local vec_16_16 = Vector(16,16,0)
		local ng = game.GetMapNodegraph and game.GetMapNodegraph() or Nodegraph()
		for k,v in RandomPairs(ng and ng:GetNodes() or {}) do
			pos = v.pos
			if pos and v.type==2 and util.IsInWorld(pos) and util.IsInWorld(pos+vec_16_16) and util.IsInWorld(pos-vec_16_16) then
				ent = ents.Create'info_target'
					ent:Spawn()
					ent:Activate()
					SafeRemoveEntityDelayed(ent,1)
					ent:SetPos(v.pos)
				break
			end
		end
	end

	if not ent:IsValid() then
		return false, aowl.TargetNotFound(target)
	end

	if ent:GetParent():IsValid() and ent:GetParent():IsPlayer() then
		ent=ent:GetParent()
	end

	if ent == ply then
		return false, aowl.TargetNotFound(target)
	end

	local dir = ent:GetAngles(); dir.p = 0; dir.r = 0; dir = (dir:Forward() * -100)

	if ply.LookAt and ent:GetPos():DistToSqr(ply:GetPos())< 256*256 and (not ply.IsStuck or not ply:IsStuck()) then
		ply:LookAt(ent,0.35,.01)
		return
	end

	local oldpos = ply:GetPos() + Vector(0,0,32)
	if not ply:GetNWBool("Cloaked", false) then 
		sound.Play("npc/dog/dog_footstep"..math.random(1,4)..".wav",oldpos)
	end
	local idk, reason = SendPlayer(ply, ent)
	if idk == "HOOK" then
		return false, reason
	end

	if not SendPlayer(ply,ent) then
		if ply:InVehicle() then
			ply:ExitVehicle()
		end
		ply:SetPos(ent:GetPos() + dir)
		ply:DropToFloor()
	end

	-- aowlMsg("goto", tostring(ply) .." -> ".. tostring(ent))

	if ply.UnStuck then
		timer.Create(tostring(pl)..'unstuck',1,1,function()
			if IsValid(ply) then
				ply:UnStuck()
			end
		end)
	end

	ply:SetEyeAngles((ent:EyePos() - ply:EyePos()):Angle())
	if not ply:GetNWBool("Cloaked", false) then 
		ply:EmitSound("buttons/button15.wav")
	end
	--ply:EmitSound("npc/dog/dog_footstep_run"..math.random(1,8)..".wav")
	ply:SetVelocity(-ply:GetVelocity())

	hook.Run("AowlTargetCommand", ply, "goto", ent)


end


local function aowl_goto(ply, line, target)
	if ply.IsBanned and ply:IsBanned() then return false, "access denied" end
	ply.aowl_tpprevious = ply:GetPos()

	return Goto(ply,line,target)
end
aowl.AddCommand({"goto","warp","go", "owo"}, aowl_goto, "mods")


aowl.AddCommand("tp", function(pl,line,target,...)
	if target and #target>1 and (HnS and HnS.Ingame and not HnS.InGame(pl)) then
		return aowl_goto(pl,line,target,...)
	end

	local ok, reason = hook.Run("CanPlyTeleport", pl)
	if ok == false then
		return false, reason or "Something is preventing teleporting"
	end

	local start = pl:GetPos()+Vector(0,0,1)
	local pltrdat = util.GetPlayerTrace( pl )
	pltrdat.mask = bit.bor(CONTENTS_PLAYERCLIP,MASK_PLAYERSOLID_BRUSHONLY,MASK_SHOT_HULL)
	local pltr = util.TraceLine( pltrdat )

	local endpos = pltr.HitPos
	local wasinworld=util.IsInWorld(start)

	local diff=start-endpos
	local len=diff:Length()
	len=len>100 and 100 or len
	diff:Normalize()
	diff=diff*len
	--start=endpos+diff

	if not wasinworld and util.IsInWorld(endpos-pltr.HitNormal*120) then
		pltr.HitNormal=-pltr.HitNormal
	end
	start=endpos+pltr.HitNormal*120

	if math.abs(endpos.z-start.z)<2 then
		endpos.z=start.z
		--print"spooky match?"
	end

	local tracedata = {start=start,endpos=endpos}

	tracedata.filter = pl
	tracedata.mins = Vector( -16, -16, 0 )
	tracedata.maxs = Vector( 16, 16, 72 )
	tracedata.mask = bit.bor(CONTENTS_PLAYERCLIP,MASK_PLAYERSOLID_BRUSHONLY,MASK_SHOT_HULL)
	local tr = util.TraceHull( tracedata )

	if tr.StartSolid or (wasinworld and not util.IsInWorld(tr.HitPos)) then
		tr = util.TraceHull( tracedata )
		tracedata.start=endpos+pltr.HitNormal*3

	end
	if tr.StartSolid or (wasinworld and not util.IsInWorld(tr.HitPos)) then
		tr = util.TraceHull( tracedata )
		tracedata.start=pl:GetPos()+Vector(0,0,1)

	end
	if tr.StartSolid or (wasinworld and not util.IsInWorld(tr.HitPos)) then
		tr = util.TraceHull( tracedata )
		tracedata.start=endpos+diff

	end
	if tr.StartSolid then return false,"unable to perform teleportation without getting stuck" end
	if not util.IsInWorld(tr.HitPos) and wasinworld then return false,"couldnt teleport there" end

	if math.abs(pl:GetVelocity().z) > 10 * 10 * math.sqrt(GetConVarNumber("sv_gravity")) then
		pl:EmitSound("physics/concrete/boulder_impact_hard".. math.random(1, 4) ..".wav")
		pl:SetVelocity(-pl:GetVelocity())
	end

	pl.aowl_tpprevious = pl:GetPos()

	pl:SetPos(tr.HitPos)
	pl:EmitSound"ui/freeze_cam.wav"
end, "mods")


aowl.AddCommand("send", function(ply, line, whos, where)
	if whos == "#us" then
		local players = {}
		for k, ent in pairs( ents.FindInSphere( ply:GetPos(), 256 ) ) do
			if ent:IsPlayer() and ent ~= ply then
				local pos, ang = WorldToLocal( ent:GetPos(), ent:GetAngles(), ply:GetPos(), ply:GetAngles() )
				table.insert( players, {
					ply = ent,
					pos = pos,
					ang = ang
				} )

			end
		end
		ply.aowl_tpprevious = ply:GetPos()


		-- can we actually go?
		local ok, reason = Goto( ply, "", where:Trim() )
		if ok == false then
			return false, reason
		end
		local sent = tostring( ply )
		-- now send everyone else
		for k, ent in pairs( players ) do
			ent.ply.aowl_tpprevious = ent.ply:GetPos()

			local pos, ang = LocalToWorld( ent.pos, ent.ang, ply:GetPos(), ply:GetAngles() )

			-- not using Goto function because it doesn't support vectors for normal players

			sent = sent .. " + " .. tostring( ent.ply )
			ent.ply:SetPos( pos )
			ent.ply:SetAngles( ang )
		end

		aowlMsg( "send", sent .. " -> " .. where:Trim() )
		return true
	end

	local who = easylua.FindEntity(whos)

	if who:IsPlayer() then
		who.aowl_tpprevious = who:GetPos()


		return Goto(who,"",where:Trim())
	end

	return false, aowl.TargetNotFound(whos)

end,"mods")

aowl.AddCommand("back", function(ply, line, target)
	local ent = ply:CheckUserGroupLevel("admins") and target and easylua.FindEntity(target) or ply

	if not IsValid(ent) then
		return false, "Invalid player"
	end
	if not ent.aowl_tpprevious or not type( ent.aowl_tpprevious ) == "Vector" then
		return false, "Nowhere to send you"
	end

	local ok, reason = hook.Run("CanPlyGoBack", ply)
	if ok == false then
		return false, reason or "Can't go back"
	end
	local prev = ent.aowl_tpprevious
	ent.aowl_tpprevious = ent:GetPos()
	ent:SetPos( prev )
	hook.Run("AowlTargetCommand", ply, "back", ent)
end, "mods")

aowl.AddCommand("bring", function(ply, line, target, yes)

	local ent = easylua.FindEntity(target)

	if ent:IsValid() and ent ~= ply then
		if ply:CheckUserGroupLevel("admins") then

			if ent:IsPlayer() and not ent:Alive() then ent:Spawn() end
			if ent:IsPlayer() and ent:InVehicle() then
				ent:ExitVehicle()
			end

			ent.aowl_tpprevious = ent:GetPos()


			local pos = ply:GetEyeTrace().HitPos + (ent:IsVehicle() and Vector(0, 0, ent:BoundingRadius()) or Vector(0, 0, 0))

			ent:SetPos(pos)

			local ang = (ply:EyePos() - ent:EyePos()):Angle()

			if ent:IsPlayer() then
				ang.r=0
				ent:SetEyeAngles(ang)
			elseif ent:IsNPC() then
				ang.r=0
				ang.p=0
				ent:SetAngles(ang)
			else
				ent:SetAngles(ang)
			end

			aowlMsg("bring", tostring(ply) .." <- ".. tostring(ent))
		elseif ent:IsPlayer() and ent.IsFriend and ent:IsFriend(ply) then
			if ent:TeleportingBlocked() then return false,"Teleport blocked" end
			if ply.__is_on_bring_cooldown then return false,"You're still on bring cooldown" end

			if not ent:Alive() then ent:Spawn() end
			if ent:InVehicle() then ent:ExitVehicle() end

			ent.aowl_tpprevious = ent:GetPos()

			ent:SetPos(ply:GetEyeTrace().HitPos)
			ent:SetEyeAngles((ply:EyePos() - ent:EyePos()):Angle())

			aowlMsg("friend bring", tostring(ply) .." <- ".. tostring(ent))

			if co then
				co(function()
					ply.__is_on_bring_cooldown = true
					co.wait(25)
					ply.__is_on_bring_cooldown = false
				end)
			else
				ply.__is_on_bring_cooldown = true
				timer.Simple(25,function()
					ply.__is_on_bring_cooldown = false
				end)
			end
		end
		return

	else
		return false, aowl.TargetNotFound(target)
	end
end, "mods")

aowl.AddCommand("spawn", function(ply, line, target)
	local ent = ply:CheckUserGroupLevel("admins") and target and easylua.FindEntity(target) or ply
	if not ent:IsValid() then return false,'not found' end

	if ent == ply then
		local ok, reason = hook.Run("CanPlyTeleport", ply)
		if ok == false then
			return false, reason or "Respawning blocked, try !kill"
		end
	end

	ent.aowl_tpprevious = ent:GetPos()

	if not timer.Exists(ent:EntIndex()..'respawn') then
		ent:PrintMessage( HUD_PRINTCENTER,"Respawning...")
		timer.Create(ent:EntIndex()..'respawn',1.8,1,function()
			if not ent:IsValid() then return end
			ent:Spawn()
		end)
	end
end, "mods")

aowl.AddCommand({"resurrect", "respawn", "revive"}, function(ply, line, target)
	-- Admins not allowed either, this is added for gamemodes and stuff
	local ok, reason = hook.Run("CanPlyRespawn", ply)
	if (ok == false) then
		return false, reason and tostring(reason) or "Revive is disallowed"
	end

	local ent = ply:CheckUserGroupLevel("admins") and target and easylua.FindEntity(target) or ply
	if ent:IsValid() and ent:IsPlayer() and not ent:Alive() then
		local pos,ang = ent:GetPos(),ent:EyeAngles()
		ent:Spawn()
		ent:SetPos(pos) ent:SetEyeAngles(ang)
	end
end, "mods", true)