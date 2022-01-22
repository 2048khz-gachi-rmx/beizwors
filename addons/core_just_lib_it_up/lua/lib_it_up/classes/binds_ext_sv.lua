--
util.AddNetworkString("lbu_Binds")

function Binds.Remap(ply)
	table.Empty(ply._keysToBinds)

	for k,v in pairs(ply._bindsToKey) do
		ply._keysToBinds[v] = ply._keysToBinds[v] or {}
		table.insert(ply._keysToBinds[v], k)
	end
end

net.Receive("lbu_Binds", function(len, ply)
	print("received", len / 8, "bytes of bind data from", ply)
	local amt = net.ReadUInt(16)

	ply._bindsToKey = ply._bindsToKey or {}
	ply._keysToBinds = ply._keysToBinds or {}

	for i=1, amt do
		local id = net.ReadString()
		local key = net.ReadUInt(32)

		if not Binds.Objects[id] then
			print("!! unrecognized bind from", ply, ": ", id)
			continue
		end

		ply._bindsToKey[id] = key
	end

end)