--

Queue = Queue or Object:callable()

function Queue:Initialize(t)
	if istable(t) then
		self = setmetatable(self, Queue)
	else
		t = nil
	end

	self.f = 1
	self.l = 0

	if t then
		for k,v in ipairs(t) do
			self:Push(v)
		end
	end
end

function Queue:Push(v)
	local last = self.l + 1
	self.l = last
	self[last] = v
end
Queue:AliasMethod(Queue.Push, "push")

function Queue:Pop()
	local f = self.f
	if f > self.l then return end

	local v = self[f]
	self[f] = nil
	self.f = f + 1

	return v
end
Queue:AliasMethod(Queue.Pop, "pop")

function Queue:Peek(fromTop)
	fromTop = fromTop or 1
	return self[self.f - fromTop + 1]
end
Queue:AliasMethod(Queue.Peek, "peek")

function Queue:Empty()
	return self.f == self.l
end
Queue:AliasMethod(Queue.Empty, "empty")

function Queue:Length()
	return self.l - self.f + 1
end
Queue:AliasMethod(Queue.Length, "length", "len")

function Queue:Last()
	return self[self.l]
end
Queue:AliasMethod(Queue.Last, "last")

Queue.Size = Queue.Length
Queue.__len = Queue.Length

function Queue:Reset()
	self.f = nil
	self.l = nil

	for k,v in pairs(self) do self[k] = nil end

	self.f = 1
	self.l = 0
end
Queue:AliasMethod(Queue.Reset, "reset", "clear", "Clear")

-- iteration: bottom (least recent) to top
local function stateless(q, ctrl)
	local v = q[q.f + ctrl]
	if v then return ctrl + 1, v end
end

function Queue:iter()
	return stateless, self, 0
end
Queue:AliasMethod(Queue.iter, "Iter", "pairs")

-- reverse iter: top (most recent) to bottom
local function stateless_rev(q, ctrl)
	local v = q[q.l - ctrl]
	if v then return ctrl + 1, v end
end

function Queue:reviter()
	return stateless_rev, self, 0
end
Queue:AliasMethod(Queue.reviter, "RevIter", "Reviter", "revIter")