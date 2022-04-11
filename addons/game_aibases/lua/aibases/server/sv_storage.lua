--

AIBases.Storage = AIBases.Storage or {}
local ST = AIBases.Storage

function ST.stuff() end

function ST.SerializeBricks(brs)
	local strs = {}

	for _, brick in ipairs(brs) do
		local ser = brick:Serialize()
		local id = brick:GetType()

		-- group by ID: similarly encoded data will compress better
		strs[id] = strs[id] or {}
		strs[id][#strs[id] + 1] = ser
	end

	local data = ""

	-- i gave up making it efficient n shit, fuck that
	local datas = {}

	for id, arr in pairs(strs) do
		local idw = util.TableToJSON(arr)
		datas[id] = idw
	end

	data = util.TableToJSON(datas)

	return util.Compress(data)
end

function ST.DeserializeBricks(str)
	local decomp = util.Decompress(str)
	local lv1 = util.JSONToTable(decomp)

	local ret = {}

	for id, json in pairs(lv1) do
		local arr = util.JSONToTable(json)
		local base = AIBases.IDToBrick(id)
		local out = {}

		for k, dat in pairs(arr) do
			local brick = base:Deserialize(dat)
			out[#out + 1] = brick
		end

		ret[id] = out
	end

	return ret
end

function ST.DeserializeNavs(str)
	local decomp = util.Decompress(str)
	local navs = util.JSONToTable(decomp)

	local ret = {}
	local bld = AIBases.Builder

	local navDatas = {}

	for k, navJson in ipairs(navs) do
		local data = util.JSONToTable(navJson)
		navDatas[k] = data
		local lnav = bld.NavClass:Load(data)

		ret[k] = lnav
	end

	return ret
end

concommand.Add("aibases_savenav", function(ply, _, arg)
	if not AIBases.Builder.Allowed(ply) then return end

	local name = arg[1]
	if not arg[1] then print("give a name tard") return end

	local overwrite = arg[2]
	if file.Exists("aibases/layouts/" .. name .. "_nav.dat", "DATA") and overwrite ~= "yes" then
		ply:ChatPrint("nav already exists: make second arg 'yes' to confirm overwrite")
		print("nav already exists: make second arg 'yes' to confirm overwrite")
		return
	end

	if not file.Exists("aibases/layouts/" .. name .. ".dat", "DATA") then
		ply:ChatPrint("layout for this nav doesn't exist; make a layout first")
		print("layout for this nav doesn't exist; make a layout first")
		return
	end

	print("saving nav `" .. name .. "`...")

	local navs = AIBases.Builder.Navs[ply]
	if not navs then
		print("nvm no navs lol", ply)
		return
	end

	local arr = {}
	for k,v in pairs(navs) do
		v:UpdateID()
	end

	for k,v in pairs(navs) do
		arr[#arr + 1] = v:Serialize()
	end

	local out = util.Compress(util.TableToJSON(arr))

	file.CreateDir("aibases/layouts")
	file.Write("aibases/layouts/" .. name .. "_nav.dat", out)
end)