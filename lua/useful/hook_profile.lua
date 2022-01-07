_HRUN = _HRUN or hook.Run
_HCALL = _HCALL or hook.Call

setfenv(1, _G)

local ENABLE_HOOK = true
local ENABLE_GARBAGE = false


local frs = {}
local fn = FrameNumber()
local garbage = 0
local growth = 0

hook.Add("PostRender", "a", function()
	cam.Start2D()
		fn = FrameNumber()
		local garb = fn % 1 == 0 and collectgarbage("count") or garbage
		if fn % 1 == 0 then
			growth = garb - garbage
		end

		garbage = garb

		local _, th = draw.SimpleText(("%.1fkb."):format(garb), "DermaLarge", ScrW() / 2, ScrH(), color_white, 1, 4)
		draw.SimpleText(("%s%.1fkb."):format(growth > 0 and "+" or "", growth),
			"DermaLarge", ScrW() / 2, ScrH() - th, color_white, 1, 4)
	cam.End2D()
end)

if not ENABLE_HOOK then
	hook.Remove("PostRender", "a")
end

if not ENABLE_GARBAGE then
	hook.Call = _HCALL
	local reg = debug.getregistry()

	for k,v in pairs(reg) do
		if v == _NHCALL then
			reg[k] = hook.Call
		end
	end

else
	local disable = table.KeysToValues({
		--"Think",	-- ~40kb
		--"PostDrawTranslucentRenderables",	-- ~30kb
		-- "PreDrawViewModel",
	})

	local inspect = table.KeysToValues({
		--"Think",
		--"PostDrawTranslucentRenderables",
		--"PreDrawHalos",
		-- "HUDPaint",
		-- "PreDrawViewModel",
		-- "PostDrawViewModel",
	})

	local ceil = 1.5

	_NHCALL = _NHCALL or _HCALL

	local Hooks = hook.GetULibTable()

	local function inspectRun(name, gm, ...)
		local HookTable = Hooks[ name ]

		if ( HookTable != nil ) then

			for i=-2, 2 do

				for k, v in pairs( HookTable[ i ] ) do

					if ( v.isstring ) then

						--
						-- If it's a string, it's cool
						--
						local gPre = collectgarbage("count")
						local a, b, c, d, e, f = v.fn( ... )
						local gPost = collectgarbage("count")

						if gPost - gPre > ceil then
							print(k, gPost - gPre)
						end
						if ( a != nil && i > -2 && i < 2 ) then
							return a, b, c, d, e, f
						end

					else

						--
						-- If the key isn't a string - we assume it to be an entity
						-- Or panel, or something else that IsValid works on.
						--
						if ( IsValid( k ) ) then
							--
							-- If the object is valid - pass it as the first argument (self)
							--
							local a, b, c, d, e, f = v.fn( k, ... )
							if ( a != nil && i > -2 && i < 2 ) then
								return a, b, c, d, e, f
							end
						else
							--
							-- If the object has become invalid - remove it
							--
							HookTable[ i ][ k ] = nil
						end
					end
				end
			end
		end

		--
		-- Call the gamemode function
		--
		if ( !gm ) then return end

		local gPre = collectgarbage("count")
		local GamemodeFunction = gm[ name ]
		if ( GamemodeFunction == nil ) then return end

		local a, b, c, d, e, f = GamemodeFunction( gm, ... )
		local gPost = collectgarbage("count")

		if gPost - gPre > ceil then
			print("GM:" .. name, gPost - gPre)
		end

		return a, b, c, d, e, f
	end

	function hook.Call(name, ...)
		if disable[name] then return _HCALL(name, ...) end
		if inspect[name] then return inspectRun(name, ...) end

		local gPre = collectgarbage("count")
		local a, b, c, d, e, f = _HCALL(name, ...)
		local gPost = collectgarbage("count")
		if gPost - gPre > 3 then
			print(name, gPost - gPre)
		end
		return a, b, c, d, e, f
	end

	local reg = debug.getregistry()
	for k,v in pairs(reg) do
		if v == _HCALL or v == _NHCALL then
			reg[k] = hook.Call
		end
	end

	_NHCALL = hook.Call

end

--[=[
local function qerp(delta, a, b)
    local qdelta = -(delta ^ 2) + (delta * 2)

    qdelta = math.Clamp(qdelta, 0, 1)

    return Lerp(qdelta, a, b)
end

SWEP.LHIKAnimation_IsIdle = false
SWEP.LHIKAnimation = nil
SWEP.LHIKAnimationStart = 0
SWEP.LHIKAnimationTime = 0

SWEP.LHIKCamAng = Angle(0, 0, 0)
SWEP.LHIKGunAng = Angle(0, 0, 0)

SHARED_VEC = Vector()

function SWEP:DoLHIKAnimation(key, time)
    local lhik_model
    local LHIK_GunDriver
    local LHIK_CamDriver

    local tranim = self:GetBuff_Hook("Hook_LHIK_TranslateAnimation", key)

    key = tranim or key

    for i, k in pairs(self.Attachments) do
        if !k.Installed then continue end
        if !k.VElement then continue end

        if self:GetBuff_Stat("LHIK", i) then
            lhik_model = k.VElement.Model

            if self:GetBuff_Stat("LHIK_GunDriver", i) then
                LHIK_GunDriver = self:GetBuff_Stat("LHIK_GunDriver", i)
            end

            if self:GetBuff_Stat("LHIK_CamDriver", i) then
                LHIK_CamDriver = self:GetBuff_Stat("LHIK_CamDriver", i)
            end
        end
    end

    if !lhik_model then return false end

    local seq = lhik_model:LookupSequence(key)

    if !seq then return false end
    if seq == -1 then return false end

    lhik_model:ResetSequence(seq)

    if !time then time = lhik_model:SequenceDuration(seq) end

    self.LHIKAnimation = seq
    self.LHIKAnimationStart = UnPredictedCurTime()
    self.LHIKAnimationTime = time

    self.LHIKAnimation_IsIdle = false

    if LHIK_GunDriver then
        local att = lhik_model:LookupAttachment(LHIK_GunDriver)
        local ang = lhik_model:GetAttachment(att).Ang
        local pos = lhik_model:GetAttachment(att).Pos

        self.LHIKGunAng = lhik_model:WorldToLocalAngles(ang)
        self.LHIKGunPos = lhik_model:WorldToLocal(pos)
    end

    if LHIK_CamDriver then
        local att = lhik_model:LookupAttachment(LHIK_CamDriver)
        local ang = lhik_model:GetAttachment(att).Ang

        self.LHIKCamAng = lhik_model:WorldToLocalAngles(ang)
    end

    -- lhik_model:SetCycle(0)
    -- lhik_model:SetPlaybackRate(dur / time)

    return true
end

SWEP.LHIKDelta = {}
SWEP.LHIKDeltaAng = {}
SWEP.ViewModel_Hit = Vector(0, 0, 0)
SWEP.Customize_Hide = 0

local SHARED_MATRIX = Matrix()
local f_lerp   = Lerp

local function LerpSource(dlt, from, to)
    from[1] = f_lerp(dlt, from[1], to[1])
    from[2] = f_lerp(dlt, from[2], to[2])
    from[3] = f_lerp(dlt, from[3], to[3])
end

local function LerpInto(dlt, from, to, into)
    into[1] = f_lerp(dlt, from[1], to[1])
    into[2] = f_lerp(dlt, from[2], to[2])
    into[3] = f_lerp(dlt, from[3], to[3])
end

function SWEP:GetLHIKAnim()
    local cyc = (UnPredictedCurTime() - self.LHIKAnimationStart) / self.LHIKAnimationTime

    if cyc > 1 then return nil end
    if self.LHIKAnimation_IsIdle then return nil end

    return self.LHIKAnimation
end

function SWEP:DoLHIK()
    local justhide = false
    local lhik_model = nil
    local hide_component = false
    local delta = 1

    local vm = self:GetOwner():GetViewModel()
    local t = self:GetTable()
    if !t.NoHideLeftHandInCustomization and !self:GetBuff_Override("Override_NoHideLeftHandInCustomization") then
        if self:IsCustomizing() then
            t.Customize_Hide = math.Approach(t.Customize_Hide, 1, FrameTime() / 0.25)
        else
            t.Customize_Hide = math.Approach(t.Customize_Hide, 0, FrameTime() / 0.25)
        end
    end

    for i, k in pairs(t.Attachments) do
        if !k.Installed then continue end
        -- local atttbl = ArcCW.AttachmentTable[k.Installed]

        -- if atttbl.LHIKHide then
        if self:GetBuff_Stat("LHIKHide", i) then
            justhide = true
        end

        if !k.VElement then continue end

        -- if atttbl.LHIK then
        if self:GetBuff_Stat("LHIK", i) then
            lhik_model = k.VElement.Model
        end
    end

    if t.LHIKTimeline then
        local tl = t.LHIKTimeline

        local stage, next_stage, next_stage_index

        for i, k in pairs(tl) do
            if !k or !k.t then continue end
            if k.t + t.LHIKStartTime > CurTime() then
                next_stage_index = i
                break
            end
        end

        if next_stage_index then
            if next_stage_index == 1 then
                -- we are on the first stage.
                stage = {t = 0, lhik = 0}
                next_stage = t.LHIKTimeline[next_stage_index]
            else
                stage = t.LHIKTimeline[next_stage_index - 1]
                next_stage = t.LHIKTimeline[next_stage_index]
            end
        else
            stage = t.LHIKTimeline[#t.LHIKTimeline]
            next_stage = {t = t.LHIKEndTime, lhik = t.LHIKTimeline[#t.LHIKTimeline].lhik}
        end

        local local_time = CurTime() - t.LHIKStartTime

        local delta_time = next_stage.t - stage.t
        delta_time = (local_time - stage.t) / delta_time

        delta = qerp(delta_time, stage.lhik, next_stage.lhik)

        if lhik_model and IsValid(lhik_model) then
            local key

            if stage.lhik > next_stage.lhik then
                key = "in"
            elseif next_stage.lhik > stage.lhik then
                key = "out"
            end

            if key then
                local tranim = self:GetBuff_Hook("Hook_LHIK_TranslateAnimation", key)

                key = tranim or key

                local seq = lhik_model:LookupSequence(key)

                if seq and seq > 0 then
                    lhik_model:SetSequence(seq)
                    lhik_model:SetCycle(delta)
                end
            end
        end

        -- if tl[4] <= UnPredictedCurTime() then
        --     -- it's over
        --     delta = 1
        -- elseif tl[3] <= UnPredictedCurTime() then
        --     -- transition back to 1
        --     delta = (UnPredictedCurTime() - tl[3]) / (tl[4] - tl[3])
        --     delta = qerp(delta, 0, 1)

        --     if lhik_model and IsValid(lhik_model) then
        --         local key = "out"

        --         local tranim = self:GetBuff_Hook("Hook_LHIK_TranslateAnimation", key)

        --         key = tranim or key

        --         local seq = lhik_model:LookupSequence(key)

        --         if seq and seq > 0 then
        --             lhik_model:SetSequence(seq)
        --             lhik_model:SetCycle(delta)
        --         end
        --     end
        -- elseif tl[2] <= UnPredictedCurTime() then
        --     -- hold 0
        --     delta = 0
        -- elseif tl[1] <= UnPredictedCurTime() then
        --     -- transition to 0
        --     delta = (UnPredictedCurTime() - tl[1]) / (tl[2] - tl[1])
        --     delta = qerp(delta, 1, 0)

        --     if lhik_model and IsValid(lhik_model) then
        --         local key = "in"

        --         local tranim = self:GetBuff_Hook("Hook_LHIK_TranslateAnimation", key)

        --         key = tranim or key

        --         local seq = lhik_model:LookupSequence(key)

        --         if seq and seq > 0 then
        --             lhik_model:SetSequence(seq)
        --             lhik_model:SetCycle(delta)
        --         end
        --     end
    else
        -- hasn't started yet
        delta = 1
    end

    if delta == 1 and t.Customize_Hide > 0 then
        if !lhik_model or !IsValid(lhik_model) then
            justhide = true
            delta = math.min(self.Customize_Hide, delta)
        else
            hide_component = true
        end
    end

    if justhide then
        for _, bone in pairs(ArcCW.LHIKBones) do
            local vmbone = vm:LookupBone(bone)

            if !vmbone then continue end -- Happens when spectating someone prolly

            local vmtransform = vm:GetBoneMatrix(vmbone)

            if !vmtransform then continue end -- something very bad has happened

            local vm_pos = vmtransform:GetTranslation()
            local vm_ang = vmtransform:GetAngles()

            local newtransform = Matrix()

            --[[
            local eang = EyeAngles()
            local wtf = vm_pos - (eang:Up() * 12) - (eang:Forward() * 12) - (eang:Right() * 4)
            LerpSource(delta, vm_pos, vm_pos + wtf)
            newtransform:SetTranslation(vm_pos)
            ]]
            newtransform:SetTranslation(LerpVector(delta, vm_pos, vm_pos - (EyeAngles():Up() * 12) - (EyeAngles():Forward() * 12) - (EyeAngles():Right() * 4)))
            newtransform:SetAngles(vm_ang)

            vm:SetBoneMatrix(vmbone, newtransform)
        end
    end

    if !lhik_model or !IsValid(lhik_model) then return end

    lhik_model:SetupBones()

    if justhide then return end

    local cyc = (UnPredictedCurTime() - t.LHIKAnimationStart) / t.LHIKAnimationTime

    if t.LHIKAnimation and cyc < 1 then
        lhik_model:SetSequence(t.LHIKAnimation)
        lhik_model:SetCycle(cyc)
    else
        local key = "idle"

        local tranim = self:GetBuff_Hook("Hook_LHIK_TranslateAnimation", key)

        key = tranim or key

        self:DoLHIKAnimation(key, 1)

        t.LHIKAnimation_IsIdle = true
    end

    local cf_deltapos = Vector(0, 0, 0)
    local cf = 0

    for _, bone in pairs(ArcCW.LHIKBones) do
        local vmbone = vm:LookupBone(bone)
        if !vmbone then continue end

        local lhikbone = lhik_model:LookupBone(bone)
        if !lhikbone then continue end

        local vmtransform = vm:GetBoneMatrix(vmbone)
        if !vmtransform then continue end

        local lhiktransform = lhik_model:GetBoneMatrix(lhikbone)
        if !lhiktransform then continue end

        local lhik_pos = lhiktransform:GetTranslation()
        local lhik_ang = lhiktransform:GetAngles()

        local newtransform = SHARED_MATRIX
        newtransform:Identity()

        local newTransl

        if delta == 1 then
            -- less GAWWBAGE
            newtransform:SetTranslation(lhik_pos)
            newTransl = lhik_pos
            newtransform:SetAngles(lhik_ang)
        else
            local vm_pos = vmtransform:GetTranslation()
            local vm_ang = vmtransform:GetAngles()

            LerpSource(delta, vm_pos, lhik_pos)
            LerpSource(delta, vm_ang, lhik_ang)

            newtransform:SetTranslation(vm_pos)
            newTransl = vm_pos
            newtransform:SetAngles(vm_ang)
        end

        --[[if !self:GetBuff_Override("LHIK_GunDriver") and
            t.LHIKDelta[lhikbone] and
            t.LHIKAnimation and cyc < 1 then
            local deltapos = lhik_model:WorldToLocal(lhik_pos) - t.LHIKDelta[lhikbone]

            if !deltapos:IsZero() then
                cf_deltapos = cf_deltapos + deltapos
                cf = cf + 1
            end
        end

        self.LHIKDelta[lhikbone] = lhik_model:WorldToLocal(lhik_pos)]]

        if hide_component then
            -- EEK WTF IS THIS
            local new_pos = newTransl
            local ea = EyeAngles()
            local eau, eaf, ear = ea:Up(), ea:Forward(), ea:Right()
            eau:Mul(12) eaf:Mul(12) ear:Mul(12)

            local new = SHARED_VEC
            new:Set(vector_origin)
            new:Add(new_pos) new:Sub(eau) new:Sub(eaf) new:Sub(ear)

            LerpSource(self.Customize_Hide,
                new_pos,
                new)

            newtransform:SetTranslation(new_pos)
        end

        vm:SetBoneMatrix(vmbone, newtransform)
    end

    if !cf_deltapos:IsZero() and cf > 0 and self:GetBuff_Override("LHIK_Animation") then
        local new = SHARED_VEC
        local viewmult = self:GetBuff_Override("LHIK_MovementMult") or 1
        new:SetUnpacked(
            cf_deltapos[2],
            cf_deltapos[1],
            cf_deltapos[3]
        )

        new:Mul(viewmult)
        new:Div(cf)

        self.ViewModel_Hit = LerpVector(0.25, t.ViewModel_Hit, new):GetNormalized()
    end
end
]=]