--[[=============================================================================
    c4_object Class

    Copyright 2015 Control4 Corporation. All Rights Reserved.
===============================================================================]]

function inheritsFrom( baseClass )
	local new_class = {}
	local class_mt = { __index = new_class }

	function new_class:create(...)
		local newinst = {}

		setmetatable( newinst, class_mt )

		-- Call the constructor when we create this class
		if newinst.construct then
			-- Allow returning a different obj than self. This allows for readonly tables etc...
			newinst = newinst:construct(...) or newinst
		end

		return newinst
	end

	if nil ~= baseClass then
		setmetatable( new_class, { __index = baseClass } )
	end

	--[[=============================================================================
	    Implementation of additional OO properties starts here 
	===============================================================================]]
	
	-- Return the class object of the instance
	function new_class:class()
		return new_class
	end

	--[[=============================================================================
	    Return the super class object of the instance. 

	    Note Calling methods on the base class itself will modify
	    the base table's static properties. In order to have call
	    the base class' methods and have them modify the current object
	    use super() or superAsSelf(). 
	===============================================================================]]
	function new_class:superClass()
		return baseClass
	end

	--[[=============================================================================
	    Returns a table that allows calling of the base class's method
	    while maintaining the objects state as the modified state of the base
	    class' methods. For example consider the following statements (order matters):

	    -- The child sees the parents property if the child hasn't overriden the property
	       obj:superClass().id = "parent"
	       obj.id == "parent" -- true

	    -- Setting the property on the child overrides (hides) the parents property
	       obj.id = "child"
	       obj.id == "child" -- true

	    -- The super() method pass
	       obj:super().id == "parent" -- true
	       obj:super().id = "child"
	       obj:super().id == "parent" -- still true
	       obj.id == "child" -- still true
	===============================================================================]]
	function new_class:super()
		local holder = {}

		holder.child = self
		holder.parent = baseClass

		local mt = {}
		mt.__index = function(table, index)
			if table.parent[index] then
				return table.parent[index]
			else 
				return table.child[index]
			end
		end

		-- Only set the new values to the child.
		mt.__newindex = function(table, key, value)
			table.child[key] = value
		end

		mt.__tostring = function(table)
			return tostring(table.child)
		end

		setmetatable(holder, mt)
		return holder
	end

	new_class.new = new_class.create

	--[[=============================================================================
	    Return true if the caller is an instance of theClass
	===============================================================================]]
	function new_class:isa( theClass )
		local b_isa = false
		local cur_class = new_class

		while ( nil ~= cur_class ) and ( false == b_isa ) do
			if cur_class == theClass then
				b_isa = true
			else
				cur_class = cur_class:superClass()
			end
		end

		return b_isa
	end

	return new_class
end

--[[=============================================================================
    Inheritance unit tests
===============================================================================]]
function __test_inheritance()
	local b = inheritsFrom(nil)

	b.construct = function(self, msg)
		self._msg = msg
	end

	local t = inheritsFrom(b)
	t.construct = function(self, msg)
		self:super():construct(msg)
	end

	t1 = t:new("t1")
	t2 = t:new("t2")
	assert(t1._msg == "t1", "t1 message is not equal to 't1' it''s: " .. t1._msg)
	assert(t2._msg == "t2", "t2 message is not equal to 't2' it''s: " .. t2._msg)    
	assert(tostring(t1:super()) ==  tostring(t1), "tostrings don't match");
	assert(t1:superClass() == b, "superClass and baseClass should be the same. They are not.")

	t1:superClass().id = "parent"
	assert(t1.id == "parent", "obect''s super class has invalid property value: ", t1.id)

	-- Setting the property on the child overrides (hides) the parents property
	t1.id = "child"
	assert(t1.id == "child", "object instance variable has invalid property value: " .. t1.id)

	-- The super() method maintains the self pointer to the child and not to the base
	assert(t1:super().id == "parent", "superAsSelf found invalid value for base class variable")
	t1:super().id = "child1"
	assert(t1:super().id == "parent", "Setting of instance variable hid base classes variable from itself");
	assert(t1.id == "child1", "Settings of instance variable did not change child instance variable")
end