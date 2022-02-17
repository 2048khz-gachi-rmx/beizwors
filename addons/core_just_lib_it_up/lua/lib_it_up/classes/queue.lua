--

Queue = Queue or Object:callable()

function Queue:Initialize(t)
	if istable(t) then self = setmetatable(t, Queue) end

	self.f = 0
	self.l = -1
end

function Queue:Push(v)
	local last = self.l + 1
	self.l = last
	self[last] = v
end

function Queue:Pop()
	local f = self.f
	if f > self.l then return end

	local v = self[f]
	self[f] = nil
	self.f = f + 1

	return v
end

function Queue:Peek()
	return self[self.f]
end

function Queue:Empty()
	return self.f == self.l
end

function Queue:Length()
	return self.l - self.f + 1
end

function Queue:Last()
	return self[self.l]
end

Queue.Size = Queue.Length
Queue.__len = Queue.Length

function Queue:Reset()
	self.f = nil
	self.l = nil

	for k,v in pairs(self) do self[k] = nil end

	self.f = 0
	self.l = -1
end