local sel = LibItUp.Selection or Emitter:callable()
LibItUp.Selection = sel
Selection = LibItUp.Selection

function sel:Initialize(opts, def)
	assert(not opts or istable(opts), "options arg should be nil or a table")
	if opts then
		self:SetOptions(opts)
	end
	if def ~= nil then self:Select(def) end
end

function sel:Select(v, force)
	if not force and self.KeyOptions and not self.KeyOptions[v] then
		errorf("`%s` is not a valid option (%s)", v, self.Possibilities)
		return
	end

	local prev = self.CurValue
	self.CurValue = v
	self:Emit("Selected", prev, v)
	return self
end
sel.__call = sel.Select

function sel:Deselect()
	return self:Select(nil, true)
end

function sel:Get()
	return self.CurValue
end

function sel:Selected(v)
	return self.CurValue == v
end

function sel:GetOptions()
	return self.Options
end

function sel:SetOptions(opts)
	self.KeyOptions = table.KeysToValues(opts)
	self.Options = opts

	local arr = table.ClearKeys(opts)
	table.sort(arr)
	self.Possibilities = table.concat(arr, ", ")
end