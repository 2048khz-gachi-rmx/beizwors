AIBases.LayoutBrick = AIBases.LayoutBrick or Struct:extend({
	type = TYPE_NUMBER,
})

AIBases.LayoutBrick.IsBrick = true

function AIBases.IsBrick(t)
	return istable(t) and t.IsBrick and t:Require("type")
end

function AIBases.LayoutBrick:GetType()
	return self.type
end

function AIBases.LayoutBrick:Spawn()
	errorNHf("AIBases.LayoutBrick:Spawn() : not implemented. Override this method.")
end

function AIBases.LayoutBrick:Serialize()
	return util.TableToJSON(self)
end

function AIBases.LayoutBrick:Build(ent)
	errorNHf("AIBases.LayoutBrick:Build() : not implemented. Override this method.")
end

AIBases.BRICK_PROP = 0
AIBases.BRICK_BOX = 1

FInc.FromHere("bricks/*.lua", FInc.SHARED, FInc.RealmResolver()
	:SetDefault(true)
)

local lkup = {
	[AIBases.BRICK_PROP] = AIBases.PropBrick,
	[AIBases.BRICK_BOX] = AIBases.BoxBrick,
}
function AIBases.IDToLayout(id)
	return lkup[id]
end