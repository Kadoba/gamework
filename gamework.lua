----------------------------------------------------------------------------------------------------
-- GameWork
----------------------------------------------------------------------------------------------------
-- Gamework is a library used to control process flow for the LOVE 2d game engine. It does this by
-- forwarding LOVE callbacks to processes called tasks. Each task can have their own set of tasks
-- called subtasks. Those subtasks can have their own subtasks and so on. Using this tree-like 
-- design it is easy to control the flow of command to create structures like scenes, sequences, 
-- component entities, etc.

----------------------------------------------------------------------------------------------------
-- Setup local variables
local gamework = {}

-- The root task.
local root = {}
root._gw = {}
root._gw_master = root
root._gw_taskType = "root"

-- The love callbacks.
local callbacks = {"draw", "focus", "joystickpressed", "joystickreleased", "keypressed",
					"keyreleased", "mousepressed", "mousereleased", "quit", "update"}
					
callbacks.old = {}					-- We'll put the old callbacks in here.
local initialized = false			-- If true then gamework is initialized.
local renamedCallbacks = {}			-- Callback functions that are renamed.
local inf = math.huge				-- Infinity
local blank = {_gw_order = inf}		-- Used to fill subtask holes when removed
local removed = {}					

----------------------------------------------------------------------------------------------------
-- HELPER FUNCTIONS
----------------------------------------------------------------------------------------------------

-- Assign a master to a subtask. Also ensures _gw is defined. Helper function.
local function assignMaster(task, subtask, taskType)

	if subtask._gw_master then error("assignMaster() - Task already has another master") end
	if task == subtask then error("assignMaster() - A task can not be its own master") end
	subtask._gw_master = task
	subtask._gw_taskType = taskType
	
end

----------------------------------------------------------------------------------------------------
-- Checks a sequence to see if it's halted. If not then it fills the subtask list until the queue
-- runs out or a halt task is found. Helper function.
local function checkSequence(task)

	local subtask, params
	while not task._gw_sequenceHaltActive and task._gw_sequenceLeft <= task._gw_sequenceRight do
		subtask = task._gw_sequenceQueue[ task._gw_sequenceLeft ]
		params = task._gw_sequenceParameters[ subtask ]
		
		
		task._gw_sequenceQueue[ task._gw_sequenceLeft ] = nil
		task._gw_sequenceLeft = task._gw_sequenceLeft + 1
		task._gw_sequenceSize = task._gw_sequenceSize - 1
		
		-- If there is a task then add it as a subtask.
		if subtask then 
			subtask._gw_master = nil
			gamework.addSubtask(task, subtask, params and unpack(params)) 
		end
		
		-- If task is a halt task then halt the sequence
		if task._gw_sequenceHaltTasks[subtask] then 
			task._gw_sequenceHaltActive = subtask
			task._gw_sequenceHaltTasks[subtask] = nil
		end
		
		-- cleanup
		if params then 
			task._gw_sequenceParameters[ subtask ] = nil 
			params = nil
		end
	end
	
end

----------------------------------------------------------------------------------------------------
-- Sorting function used to sort a task's subtask list.
local function sortByOrder(task1, task2)

	return (task1._gw_order or 0) < (task2._gw_order or 0)
	
end

----------------------------------------------------------------------------------------------------
-- Sorts a task's subtasks is it needs it
local function sortSubtasks(task)
	-- If the subtasks' order has changed then sort it.
	if task._gw_subtasksDirty then
		table.sort(task._gw_subtasks, sortByOrder)
		task._gw_subtaskDirty = nil
		local highest = #task._gw_subtasks
		while task._gw_subtasks[highest] and task._gw_subtasks[highest]._gw_order == inf do
			task._gw_subtasks[highest] = nil
			highest = highest-1
		end
	end
end

----------------------------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
----------------------------------------------------------------------------------------------------

-- Put a task in queue to be a subtask
function gamework.addSequence(task, subtask, halt, param1, ...)

	assignMaster(task, subtask, "queued")
	
	-- Check and see if the sequence values are initalized for the task
	if not task._gw_sequenceQueue then
		task._gw_sequenceQueue = {}
		task._gw_sequenceLeft = 1
		task._gw_sequenceRight = 0
		task._gw_sequenceSize = 0
		task._gw_sequenceHaltTasks = {}
		task._gw_sequenceParameters = {}
	end
	
	-- Store the task
	task._gw_sequenceHaltTasks[subtask] = halt
	task._gw_sequenceRight = task._gw_sequenceRight + 1
	task._gw_sequenceSize = task._gw_sequenceSize + 1
	task._gw_sequenceQueue[task._gw_sequenceRight] = subtask
	if param1 then task.__gw_sequenceParameters[subtask] = {param1, ...} end
	
	-- Check and see if we need to add any new tasks
	checkSequence(task)
	
end

----------------------------------------------------------------------------------------------------
-- Add a subtask
function gamework.addSubtask(task, subtask, ...)

	assignMaster(task, subtask, "subtask")
	
	-- check if subtask values are defined
	if not task._gw_subtasks then 
		task._gw_subtasks = {} 
		task._gw_subtasksSize = 0
	end
	
	task._gw_subtasksDirty = true
	task._gw_subtasksSize = task._gw_subtasksSize + 1
	subtask._gw_index = #task._gw_subtasks+1
	task._gw_subtasks[subtask._gw_index] = subtask
	if gamework.attachedToRoot(subtask) then gamework.callback(subtask, "added", "all", ...) end

end

----------------------------------------------------------------------------------------------------
-- Checks if a task is attached to the root or not
function gamework.attachedToRoot(task)

	while task._gw_master do
		if task._gw_master == root then return true end
		task = task._gw_master
	end
	return false
	
end

----------------------------------------------------------------------------------------------------
-- Perform a callback on the specified task and all of its subtasks. 
--
-- The spread parameter determines how the callback is disseminated.
-- It can be "normal", which prevents the spread to delegated tasks and subtasks. 
-- It can be "delegated" which spreads the callback to tasks and subtasks regardless if they are 
-- delegated or not (but not delegates themselves). Lastly, spread can be "all" which spreads the 
-- callback to all subtasks and delegates regardless if they are delegated  or not.

function gamework.callback(task, cb, spread, ...)

	-- If a callback is renamed then change it
	if renamedCallbacks[cb] then cb = renamedCallbacks[cb] end
	
	-- Check if the spread is valid.
	if spread ~= "normal" and spread ~= "all" and spread ~= "delegated" then
		error("gamework.callback() - Unknown spread type " .. tostring(spread))
	end
	
	-- If the task has a delegate then find the top one and forward the callback to it.
	if task._gw_delegate and spread ~= "delegated" then
		gamework.callback(gamework.topDelegate(task), cb, spread, ...)
		if spread == "normal" then return end
	end
	
	-- Otherwise immediately trigger the callback.
	if task[cb] then task[cb](task, ...) end
	
	-- If the task has any subtasks then call those.
	if task._gw_subtasks then
	
		-- Recursively call this function on every subtask.
		for i = 1, #task._gw_subtasks do
			if task._gw_subtasks[i] then gamework.callback(task._gw_subtasks[i], cb, spread, ...) end
		end
		
		-- If the subtasks' order has changed then sort it.
		if task._gw_subtasksDirty then
			table.sort(task._gw_subtasks, sortByOrder)
			local highest = #task._gw_subtasks
			while task._gw_subtasks[highest] and task._gw_subtasks[highest]._gw_order == inf do
				task._gw_subtasks[highest] = nil
				highest = highest-1
			end
			for k,v in pairs(task._gw_subtasks) do
				v._gw_index = k
			end
			task._gw_subtasksDirty = nil
		end
		
	end
	
end

----------------------------------------------------------------------------------------------------
-- Clear the task of all queued subtasks in sequence.
function gamework.clearSequence(task)

	for subtask in gamework.iterateSequence(task) do
		gamework.remove(subtask)
	end

end


----------------------------------------------------------------------------------------------------
-- Clear the task of all active subtasks.
function gamework.clearSubtasks(task, ...)

	if not task._gw_subtasks then return end
	
	local i = 1
	local subtasks = task._gw_subtasks
	local cap = #subtasks
	
	for i= 1,cap do
		if subtasks[i] then gamework.remove(subtasks[i]) end
	end
	
end

----------------------------------------------------------------------------------------------------
-- Continue a sequence regardless if it's stopped or not
function gamework.continueSequence(task)

	if not task._gw_sequenceQueue then return end
	task._gw_sequenceHaltActive = nil
	checkSequence(task)
	
end

----------------------------------------------------------------------------------------------------
-- Return the number of queued tasks in a sequence. If tasks have been removed from the queue
-- early then this number is not reliable.
function gamework.countSequence(task)
	return task._gw_sequenceSize or 0
end

----------------------------------------------------------------------------------------------------
-- Return the number of subtasks.
function gamework.countSubtasks(task)
	return task._gw_subtasksSize or 0
end

----------------------------------------------------------------------------------------------------
-- Get the delegate of a task
function gamework.getDelegate(task) 
	return task._gw_delegate 
end

----------------------------------------------------------------------------------------------------
-- Get the subtask that is halting a sequence
function gamework.getHaltSubtask(task) 
	return task._gw_sequenceHaltActive
end

----------------------------------------------------------------------------------------------------
-- Get the master of a task. The root task is its own master
function gamework.getMaster(subtask) 
	return subtask._gw_master 
end

----------------------------------------------------------------------------------------------------
-- Get the order of the task
function gamework.getOrder(task) 
	return task._gw_order or 0
end

----------------------------------------------------------------------------------------------------
-- Get the root
function gamework.getRoot() 
	return root 
end

----------------------------------------------------------------------------------------------------
-- Get the task type. Can be "root", "subtask", "delegate", or "queued"
function gamework.getTaskType(task) 
	return task._gw_taskType 
end

----------------------------------------------------------------------------------------------------
-- Initializes gamework. This must be called after defining any love callbacks and can only be
-- called once.
function gamework.initialize()

	-- You can only initialize once
	if initialized then 
		error("gamework.initialize() - Gamework can only be initialized once") 
	else 
		initialized = true 
	end
	
	-- redefine the callbacks
	for i = 1,#callbacks do
		local cb = callbacks[i]
		callbacks.old[cb] = love[cb]
		love[cb] = function(...)
		if callbacks.old[cb] then callbacks.old[cb](...) end
			gamework.callback(root, cb, "normal", ...)
		end
	end
	
end

----------------------------------------------------------------------------------------------------
-- Checks to see if the other task is a subtask of the first task
function gamework.isSubtask(task, other)

	if not task._gw_subtasks then return false end
	for subtask in gamework.iterateSubtasks(task) do
		if subtask == other then return true end
	end
	return false
end

----------------------------------------------------------------------------------------------------
-- Checks to see if the other task is queued in the first task's sequence
function gamework.isSequence(task, other)

	if not task._gw_sequenceQueued then return false end
	for queued in gamework.iterateSequence(task) do
		if queued == other then return true end
	end
	return false
	
end

----------------------------------------------------------------------------------------------------
-- Iterate over all queued tasks
function gamework.iterateSequence(task)

	-- Return a dummy function if there is no sequence
	if not task._gw_sequenceQueue then return function() end end

	-- Go from left to right iterating over all values
	local i = task._gw_sequenceLeft
	local right = task._gw_sequenceRight
	local sequence = task._gw_sequenceQueue
	return function()
		while i <= right do
			i = i + 1
			if sequence[i-1] then return sequence[i-1] end
		end
	end
	
end

----------------------------------------------------------------------------------------------------
-- Iterate over all subtasks.
function gamework.iterateSubtasks(task)

	-- If there is no subtasks then return a dummy function
	if not task._gw_subtasks then return function() end end
	
	-- Iterate in reverse so removal doesn't screw things up
	local subtasks = task._gw_subtasks
	local i = 1
	local last = #task._gw_subtasks
	return function()
		while i <= last do
			i = i + 1
			if subtasks[i-1] then return subtasks[i-1] end
		end
	end
	
end

----------------------------------------------------------------------------------------------------
-- Used to rename a callback if there is a naming conflict
function gamework.renameCallback(original, new)

	renamedCallbacks[original] = new
	
end

----------------------------------------------------------------------------------------------------
-- Set the delegate for a task.
function gamework.setDelegate(task, subtask, ...)

	assignMaster(task, subtask, "delegate")
	
	-- Remove the old delegate and assign the new one.
	if task._gw_delegate then gamework.remove(task._gw_delegate) end	
	task._gw_delegate = subtask
	
	-- If the subtask is attached to the root then perform the "added" callback on it.
	if gamework.attachedToRoot(subtask) then gamework.callback(subtask, "added", "all", ...) end
	
end

----------------------------------------------------------------------------------------------------
-- Change the order of the task.
function gamework.setOrder(task, order)

	if order == inf then 
		error("gamework.setOrder - order can not be set to infinity for internal reasons (sorry!)")
	end
	task._gw_order = order
	if task._gw_master then task._gw_master._gw_subtasksDirty = true end
	
end

----------------------------------------------------------------------------------------------------
-- Return the top delegate, which is the last delegate in a chain of delegates.
function gamework.topDelegate(task)

	task = task or root
	
	while task._gw_delegate do
		task = task._gw_delegate
	end
	return task
	
end

----------------------------------------------------------------------------------------------------
-- Remove the subtask from its master.
function gamework.remove(task, ...)

	if not task._gw_master then return end
		-- error(string.format("gamework.remove() - %s does not have a master", task.name or "Task"))
	-- end
	
	local master = task._gw_master
	task._gw_master = nil
	
	-- type is a plain subtask
	if task._gw_taskType == "subtask" then 
		if gamework.attachedToRoot(master) then gamework.callback(task, "removed", "all", master, ...) end
		master._gw_subtasks[ task._gw_index ] = removed
		master._gw_subtasksDirty = true
		task._gw_index = nil

		if task == master._gw_sequenceHaltActive then
			gamework.continueSequence(master)
		end
		master._gw_subtasksSize = master._gw_subtasksSize - 1
		
	-- type is a delegate
	elseif task._gw_taskType == "delegate" then
		if gamework.attachedToRoot(master) then gamework.callback(task, "removed", "all", master, ...) end
		master._gw_delegate = nil
		
	-- queued in a sequence
	elseif task._gw_taskType == "queued" then
		local queuedTask
		for i = master._gw_sequenceLeft, master._gw_sequenceRight do
			queuedTask = master._gw_sequenceQueue[i]
			if queuedTask == task then 
				master._gw_sequenceQueue[i] = nil
				master._gw_sequenceHaltTasks[task] = nil
				master._gw_sequenceParameters[task] = nil
				break
			end
		end
		master._gw_sequenceSize = master._gw_sequenceSize - 1
	end
	
end

----------------------------------------------------------------------------------------------------
-- Queues a task that will cause the sequence to wait for a bit.
function gamework.waitSequence(task, delay)
	wait = {}
	wait.timeleft = delay
	function wait:update(dt)
		self.timeleft = self.timeleft - dt
		if self.timeleft < 0 then
			gamework.continueSequence(self._gw_master, -self.timeleft)
			gamework.remove(self)
		end
	end
	gamework.addSequence(task, wait, true)
end

----------------------------------------------------------------------------------------------------
-- Return the namespace
return gamework