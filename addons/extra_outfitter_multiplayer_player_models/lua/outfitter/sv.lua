local Tag='outfitter'
local NTag = 'OF'


module(Tag,package.seeall)

util.AddNetworkString(Tag)
util.AddNetworkString(NTag)

function RateLimitMessage(pl,rem)
	local msg = "[Outfitter] you need to wait before sending a new outfit ("..math.ceil(rem).." s remaining)"
	pl:ChatPrint(msg)
end

local ent
function PrecacheModel(mdl)

	local loaded = util.IsModelLoaded(mdl)
	if loaded then return end
	
	dbg("ADDING TO LIST",('%q'):format(mdl))
	
	if StringTable then
		StringTable("modelprecache"):AddString(true,mdl)
		return
	end
	
	if not ent or not ent:IsValid() then
		ent = ents.Create'base_entity'
		if not ent or not ent:IsValid() then return end
		
		ent:SetNoDraw(true)
		ent:Spawn()
		ent:SetNoDraw(true)
		
	end
	
	ent:SetModel(mdl)
	
end


local m1 = "models/player/kleiner.mdl"
local m2 = "models/player/combine_soldier.mdl"
-- Fix movement fuckup, but break everything else (test with cl_predict 0)
function CyclePlayerModel(pl)
	assert(pl:IsValid() and pl:IsPlayer())
	local tid = ("%s_%s"):format(Tag,tostring(pl:EntIndex()))
	local omdl = pl:GetModel()
	if not pl:IsValid() then return end
	local nmdl = omdl:lower()==m1 and m2 or m1
	pl:SetModel(nmdl)
	timer.Create(tid,0.1,1,function()
		if not pl:IsValid() then return end
		local cmdl = pl:GetModel()
		if hook.Run("OutfitterCyclePlayerModel",pl,omdl,cmdl,nmdl)==false then return end
		if cmdl~=nmdl then Msg"OF: ?! " print(omdl,cmdl,nmdl) end -- return end
		pl:SetModel(omdl)
	end)
end

net.Receive(Tag,function(len,pl)
	
	--no longer needed
	--dbg("CyclePlayerModel",pl)
	--CyclePlayerModel(pl)
	
end)


function NetData(pl,k,val)
	if k~=NTag then return end

	if not isstring(val) and val~=nil then
		dbg(pl,"val",type(val))
		return false
	end
	
	local mdl,wsid
	if val then
		
		if #val>2048*2 or #val==0 then
			dbg("NetData","badval",#val,pl)
			return false
		end
		
		mdl,wsid = DecodeOW(val)
		
	end
	
	local ret = hook.Run("CanOutfit",pl,mdl,wsid)
	if ret == false then return false end
	
	pl:OutfitSetInfo(mdl,wsid)
	
	dbg("NetData",pl,"outfit",mdl,wsid)
	dbg("Outfitter SV: outfitting", pl, "with", mdl, "(workshop ID:", wsid, ")")
	
	if not val then return true end
		
	local ret = SanityCheckNData(mdl,wsid)
	
	if ret~=nil then
		dbg("NetData",pl,"sanity check fail",tostring(val):sub(1,256))
		return ret
	end
	
	assert(mdl)
	
	local should,remaining = pl:NetDataShouldLimit(NTag,util.IsModelLoaded(mdl) and 3 or 14)
	
	if should then
		RateLimitMessage(pl,math.abs(remaining))
		dbg("NetData",pl,"ratelimiting",string.NiceTime(math.ceil(math.abs(remaining))))
		return -- TODO
	end
	
	PrecacheModel(mdl)
	-- CyclePlayerModel(pl) -- it needs to happen after networking
	
	return true
end


CreateConVar("_outfitter_version","0.8.3",FCVAR_NOTIFY)
resource.AddSingleFile "materials/icon64/outfitter.png"


function TestOutfitsOnBots()
	local t = {
		{ "models/player/mikier/renamon.mdl",599541401},
		{ "models/pechenko_121/deadpool/chr_deadpoolclassic.mdl",200700693},
		{ "models/pechenko_121/deadpool/chr_deadpool2.mdl",200700693},
		{ "models/pechenko_121/deadpool/chr_deadpoolclassic.mdl",200700693},
		{ "models/raptor_player/raptor_player_red.mdl",609850164},
		{ "models/player/scoutplayer/scout.mdl",352668843},
		{ "models/player/vimeinen.mdl",572932796},
		{ "models/argonian.mdl",646729594},
		{ "models/captainbigbutt/vocaloid/apocalypse_miku.mdl",629121990},
		{ "models/player_chibiterasu.mdl",503568129},
	}
	for k,v in next,player.GetBots() do
		local of = t[(k-1)%(#t)+1]
		PrecacheModel(of[1])
		SHNetworkOutfit(v,unpack(of))
	end
end
