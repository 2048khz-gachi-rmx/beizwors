local tree = Research.Tree:new("Weaponry")
tree:SetDescription("Everything that goes pow")

local base_att = Research.Perk:new("acw_atts")
Research.ACW_AttPerk = base_att

base_att:SetName("Attachments")
base_att:SetTreeName("Weaponry")
base_att:SetColor(Color(230, 210, 130))

base_att.Levels = {
	{	Unlocks = {"optic", "optic_lp", "optic_sniper"},
		Name = "Optics",
		Description = "Unlocks the ability to install optics onto ArcCW guns.",
		Reqs = {
			Items = {
				iron_bar = 3,
				copper_bar = 2,
				-- weaponparts = 1,
				laserdiode = 2,
			}
		}
	}, {
		Unlocks = {"tac", "foregrip"},
		Name = "Tactical",
		Description = "Unlocks the ability to install tactical and foregrip attachments onto ArcCW guns.",
		Reqs = {
			Items = {
				weaponparts = 1,
				laserdiode = 5,
			}
		}
	}, {
		Unlocks = "muzzle",
		Name = "Muzzles",
		Description = "Unlocks the ability to install muzzle attachments onto ArcCW guns.",
		Reqs = {
			Items = {
				weaponparts = 3,
				iron_bar = 20,
				-- todo: titanium
			}
		}
	}, {
		Unlocks = {"grip", "stock", "go_stock", "go_stock_pistol_bt"},
		Name = "Grips",
		Description = "Unlocks the ability to install grip and stock attachments onto ArcCW guns.",
		Reqs = {
			Items = {
				weaponparts = 5,
				wepkit = 1,
			}
		}
	}, {
		Unlocks = {"magazine", "slide"},
		Name = "Conversions",
		Description = "Unlocks the ability to install slides and magazines onto ArcCW guns.",
		Reqs = {
			Items = {
				weaponparts = 10,
				blank_bp = 250,
				lube = 5,
				wepkit = 2,
			}
		}
	},
}

local function isSlide(s, t)
	return s:match("barrel") or s:match("slide") or s:match("_hg$")
end

local function isMag(s)
	return s:match("_mag_") or s:match("_mag$") or s:match("magazine")
end

local function isStock(s)
	return s:match("_stock$") or s:match("_stock_")
end

local function resolveSlot(slot, t)
	if isSlide(slot, t) then return base_att.LookupLvs.slide end
	if isMag(slot) then return base_att.LookupLvs.magazine end
	if isStock(slot) then return base_att.LookupLvs.stock end
end

local function tryResolve(ply, attName, att, lv)
	local slot = att.Slot

	if isstring(slot) then
		local ret = resolveSlot(slot, att)
		if ret then return ret end

	elseif istable(slot) then

		for k,v in ipairs(slot) do
			local ret = resolveSlot(v, att)
			if ret then return ret end
		end

	end
end

base_att.LookupLvs = {}

for k,v in ipairs(base_att.Levels) do
	if isstring(v.Unlocks) then
		base_att.LookupLvs[v.Unlocks] = k
	elseif istable(v.Unlocks) then
		for _, att in pairs(v.Unlocks) do
			base_att.LookupLvs[att] = k
		end
	elseif isfunction(v.Unlocks) then
		base_att.LookupLvs[v.Name] = v.Unlocks
	end
end

for k,v in pairs(base_att.Levels) do
	local i = k - 1

	local level = base_att:AddLevel(k)
	level:SetPos(i * 2, 0)
	level:SetIcon(CLIENT and Icons.Plus)
	level:SetDescription(v.Description)
	if v.Reqs then
		level:SetRequirements(v.Reqs)
	end
	level:SetNameFragments({base_att:GetName(), ": ", v.Name})
end

function Research.AttAllowed(ply, attName)
	do return true end

	local att
	if istable(attName) then att = attName else att = ArcCW.AttachmentTable[attName] end

	if not att then return true end
	if not att.Slot then return true end

	local lv = ply:GetPerkLevel("acw_atts")
	lv = lv and lv:GetLevel() or 0
	-- if not lv or lv == 0 then return false end

	if isstring(att.Slot) then
		local req_lv = base_att.LookupLvs[att.Slot]
		if not req_lv then
			req_lv = tryResolve(ply, attName, att, lv)
			if not req_lv then
				return true
			end
		end

		--print(attName, lv, req_lv)
		return lv >= req_lv, req_lv
	end

	for k,v in pairs(att.Slot) do
		local req_lv = base_att.LookupLvs[v]
		if not req_lv then
			req_lv = tryResolve(ply, attName, att, lv)
			if not req_lv then
				continue
			end
		end

		if lv < eval(req_lv, attName, att) then return false, req_lv end
	end

	return true
end



hook.Add("ArcCW_PlayerCanAttach", "Research", function(ply, wep, attname, slot, detach, slotTbl)
	do return end
	if not attname or attname == "" or detach then return end

	if not Research.AttAllowed(ply, attname) then
		return false
	end

end)

if CLIENT then
	include("weaponry_cl_ext.lua")
end