AIBases.LayoutBrick = AIBases.LayoutBrick or Object:callable()
AIBases.LayoutBrick.DataClass = AIBases.LayoutBrick.DataClass or Struct:extend({
	uid = {TYPE_NUMBER, default = -1},
})

AIBases.LayoutBrick.IsBrick = true

AIBases.BrickLookup = { }

function AIBases.LayoutBrick:Initialize()
	self.Data = self.DataClass:new()
end

function AIBases.LayoutBrick:Register(id)
	id = id or self.type
	AIBases.BrickLookup[id] = self
end

function AIBases.IsBrick(t)
	return istable(t) and t.IsBrick and t.type
end

function AIBases.LayoutBrick:GetType()
	return self.type
end

function AIBases.LayoutBrick:Spawn(lay)
	errorNHf("AIBases.LayoutBrick:Spawn() : not implemented. Override this method.")
end

function AIBases.LayoutBrick:PostSpawn(lay)

end


function AIBases.LayoutBrick:PostBuild()

end

function AIBases.LayoutBrick:Serialize()
	local json = util.TableToJSON(self.Data)
	json = json:gsub("^[%[%{]", ""):gsub("[%]%}]$", "")

	return json
end

function AIBases.LayoutBrick:Deserialize(str)
	local dat = util.JSONToTable("{" .. str .. "}")
	local new = self:new()

	for k,v in pairs(dat) do
		new.Data[k] = v
	end

	return new
end

function AIBases.LayoutBrick:Build(ent)
	errorNHf("AIBases.LayoutBrick:Build() : not implemented. Override this method.")
end

function AIBases.LayoutBrick:Remove()
	errorNHf("AIBases.LayoutBrick:Remove() : not implemented. Override this method.")
end

do -- autorefresh
	function AIBases.__bricktostring(self)
		return ("LayoutBrick %s[%s]"):format(AIBases.IDToName(self.type) or "[untyped]", self.Data.uid)
	end

	function AIBases.LayoutBrick:__tostring()
		return AIBases.__bricktostring(self)
	end
end

AIBases.BRICK_PROP = 0
AIBases.BRICK_BOX = 1
AIBases.BRICK_ENEMY = 2
AIBases.BRICK_DOOR = 3
AIBases.BRICK_SIGNAL = 4
AIBases.BRICK_LOOT = 5

FInc.FromHere("bricks/*.lua", FInc.SHARED, FInc.RealmResolver()
	:SetDefault(true)
)

AIBases.IDLookup = AIBases.IDLookup or {}
for k,v in pairs(AIBases) do
	if isstring(k) and k:match("^BRICK_") then
		AIBases.IDLookup[v] = k
	end
end

function AIBases.IDToBrick(id)
	return AIBases.BrickLookup[id]
end

function AIBases.IDToName(id)
	return AIBases.IDLookup[id]
end