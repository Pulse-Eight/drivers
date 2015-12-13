--[[=============================================================================
    c4_queue Class

    Copyright 2015 Control4 Corporation. All Rights Reserved.
===============================================================================]]
require "common.p8init"
require "lib.c4_object"

c4_queue = inheritsFrom(nil)

function c4_queue:construct()
	-- entry table
	self._et = {first = 0, last = -1}
	self._maxSize = 0	-- no size limit
	self._name = ""

	local mt = getmetatable(self)
	if (mt ~= nil) then
		mt.__tostring = self.__tostring
	end
end

function c4_queue:__tostring()
	local tOutputString = {}
	table.insert(tOutputString, "--- Queue ---")
	if (not IsEmpty(self._name)) then
		table.insert(tOutputString, "  name = " .. tostring(self._name))
	end
	table.insert(tOutputString, "  first = " .. tostring(self._et.first))
	table.insert(tOutputString, "  last = " .. tostring(self._et.last))
	table.insert(tOutputString, "  number in queue = " .. tostring(self._et.last - self._et.first + 1))
	table.insert(tOutputString, "  maximum size = " .. self._maxSize)
	table.insert(tOutputString, "  next value = " .. tostring(self:value()))
	return table.concat(tOutputString, "\n")
end


-- push a value on the queue
function c4_queue:push(value, ...)
	local numItems = self._et.last - self._et.first + 1

	if ((self._maxSize <= 0) or (numItems < self._maxSize) ) then
		local last = self._et.last + 1
		self._et.last = last
		
		local interval = select(1, ...)
		local units = select(2, ...)
		local command_name = select(3, ...)
		self._et[last] = {["command"] = value, ["command_delay"] = interval, ["delay_units"] = units, ["command_name"] = command_name}		
		--LogTrace ("Queue:push(), first = " .. tostring(self._et.first) .. ", last = " .. tostring(self._et.last) .. ", number in queue = " .. tostring(self._et.last - self._et.first + 1) .. ", value = " .. value)
	else
		-- if addToQueue == true then push value to queue
		if (self:OnMaxSizeReached()) then
			local last = self._et.last + 1
			self._et.last = last
			self._et[last] = {["command"] = value, ["command_delay"] = interval, ["delay_units"] = units, ["command_name"] = command_name}
			--LogTrace ("Queue:push(), first = " .. tostring(self._et.first) .. ", last = " .. tostring(self._et.last) .. ", number in queue = " .. tostring(self._et.last - self._et.first + 1) .. ", value = " .. value)
		end
	end
end

function c4_queue:OnMaxSizeReached()
	--LogTrace ("Max Size Reached - clear queue and push value to the queue (default).")
	local addToQueue = true

	self:clear()
	return (addToQueue)
end

-- pop a value from the queue
function c4_queue:pop()
	local first = self._et.first

	if first > self._et.last then
		--LogTrace("Queue:pop(), queue is empty")
		return ""
	end

	local value = self._et[first]
	self._et[first] = nil        -- to allow garbage collection
	self._et.first = first + 1
	--LogTrace ("Queue:pop(), first = " .. tostring(self._et.first) .. ", last = " .. tostring(self._et.last) .. ", number in queue = " .. tostring(self._et.last - self._et.first + 1) .. ", value = " .. value)

	return value
end

-- clear queue
function c4_queue:clear()
	local first = self._et.first

	if first > self._et.last then
		--LogTrace ("Queue:clear(), queue is empty")
		return ""
	end

	self._et = {first = 0, last = -1}
	--LogTrace ("Queue:clear(), first = " .. tostring(self._et.first) .. ", last = " .. tostring(self._et.last) .. ", number in queue = " .. tostring(self._et.last - self._et.first + 1))
	--LogTrace (self._et)
end

-- return value of first item
function c4_queue:value()
	local first = self._et.first

	if (first > self._et.last) then
		return ""
	else
		return self._et[first]
	end
end

-- return queue's maximum size
function c4_queue:MaxSize()
	return self._maxSize
end

-- return queue's maximum size
function c4_queue:SetMaxSize(size)
	self._maxSize = size
end

function c4_queue:SetName(name)
	self._name = name
end

-- return the queue's current size
function c4_queue:Size()
	return self._et.last - self._et.first + 1
end

-- is queue empty?
function c4_queue:empty()
	-- print ("self._et.first = " .. tostring(self._et.first) .. ", self._et.last = " .. tostring(self._et.last))
	if (self._et.first > self._et.last) then
		return true
	else
		return false
	end
end

--[[
    c4_queue unit tests
--]]
function __test_c4_queue()
	require "test.C4Virtual"
	require "lib.c4_log"

	local LOG = c4_log:new("test_c4_queue")
	LOG:SetLogLevel(5)
	LOG:OutputPrint(true)

	-- create an instance of the queue
	local c4Queue = c4_queue:new()

	c4Queue:SetMaxSize(3)
	assert(c4Queue:MaxSize() == 3, "_maxSize is not equal to '3' it is: " .. c4Queue:MaxSize())

	c4Queue:push("Item #1 in Queue")
	c4Queue:push("Item #2 in Queue")
	c4Queue:push("Item #3 in Queue")
	c4Queue:push("Item #4 in Queue")  -- this should cause OnMaxSizeReached() to be called and clear the queue
	assert(c4Queue:Size() == 1, "queue size is not equal to '1' it is: " .. c4Queue:Size())

	print (c4Queue)

	-- Test inheritance overriding OnMaxSizeReached
	-- Create a new class
	c4_queue_new = inheritsFrom(c4_queue)

	-- override construct()
	function c4_queue_new:construct()
		self.superClass():construct()  -- call base class
		self._maxSizeOption = 1

		local mt = getmetatable(self)
		if (mt ~= nil) then
			mt.__tostring = self.__tostring
		end
	end

	-- override OnMaxSizeReached()
	function c4_queue_new:OnMaxSizeReached()
		--Default: clear queue and push value to the queue. (No need to overload,

		-- Option 1: Do Nothing, new item is not added to queue
		if (self._maxSizeOption == 1) then
			
			LogInfo("Max Size Reached - do nothing, new item not added to queue (option 1)")
			return (false)
		-- Option 2: pop value, and push new value on queue
		elseif(self._maxSizeOption == 2) then
			LogInfo("Max Size Reached - pop value, and push new value on queue (option 2)")
			self:pop()
			return (true)
		-- Option 3: clear queue and DO NOT push new value onto queue
		elseif(self._maxSizeOption == 3) then
			LogInfo("Max Size Reached - clear queue and DO NOT push new value onto queue")
			self:clear()
			return (false)
		end
	end

	-- create an instance of the new queue
	local c4QueueNew = c4_queue_new:new()
	c4QueueNew:SetMaxSize(3)
	c4QueueNew:push("Item #1 in Queue")
	c4QueueNew:push("Item #2 in Queue")
	c4QueueNew:push("Item #3 in Queue")
	c4QueueNew:push("Item #4 in Queue")  -- this should cause OnMaxSizeReached() to be called and clear the queue
	assert(c4QueueNew:Size() == 3, "queue size is not equal to '3' it is: " .. c4QueueNew:Size())

	print(c4QueueNew)
	print ("done...")
end