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