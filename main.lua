--==================================================================================================
	-- Gamework is a library used to control process flow for the LOVE 2d game engine. 
	-- It does this by forwarding LOVE callbacks to processes called tasks. 
	-- Each task can have their own set of tasks called subtasks. 
	-- Those subtasks can have their own subtasks and so on. 
	-- Using this tree-like design it is easy to control the flow of command to create 
	-- structures like scenes, sequences, component entities, etc. 
----------------------------------------------------------------------------------------------------

--==================================================================================================
 	-- Gamework starts with a single task called the root task. 
	-- All other tasks are subtasks of the root.

	-- Here is a simple “Hello World” program in LOVE.
----------------------------------------------------------------------------------------------------

-- Define love's draw callback.
function love.draw()
 	love.graphics.print("hello world - from love", 0, 0)
end

--==================================================================================================
	--	Here’s the same program using gamework. 
----------------------------------------------------------------------------------------------------
-- Get the module.
local gamework = require "gamework"

-- Initialize gamework. Always call this after defining your love callbacks.
gamework.initialize()

-- Get the root.
local root = gamework.getRoot()

-- Define the root's draw callback.
function root:draw()
	love.graphics.print("hello world - from gamework", 0, 20)
end

--==================================================================================================
	-- Adding more tasks is simple. Tasks can be ANY table. Any callbacks in the task are 
	-- automatically called after added as a subtask.
----------------------------------------------------------------------------------------------------
-- Create an empty table.
local subtask = {}

-- Define the table's draw callback.
function subtask:draw()
	love.graphics.print("goodbye world", 0, 40)
end

-- Add the table as a subtask to root.
gamework.addSubtask(root, subtask)

--==================================================================================================
	-- Removing the subtask is even easier 
----------------------------------------------------------------------------------------------------
-- Remove the subtask.
gamework.remove(subtask)

-- Ok let's add it back because we need it.
gamework.addSubtask(root, subtask)

--==================================================================================================
	-- As stated before, subtasks can have their own subtasks.
----------------------------------------------------------------------------------------------------
-- Empty table
local subtask2 = {}

-- Define draw
function subtask2:draw()
	love.graphics.print("No wait! Don't Go!", 0, 60)
end

-- Add the table as a subtask to the first subtask
gamework.addSubtask(subtask, subtask2)

-- Now on love.draw(), root's draw function will be called followed by subtask and then subtask2

--==================================================================================================
	-- You can have multiple subtasks on one task
----------------------------------------------------------------------------------------------------
-- Let's make a task that draws a rectangle
local rect = {}
function rect:draw()
	love.graphics.setColor(100,255,255,255)
	love.graphics.rectangle("fill", 0, 80, 50, 50)
	love.graphics.setColor(255,255,255,255)
end


-- Another rectangle
local rect2 = {}
function rect2:draw()
	love.graphics.setColor(255,255,100,255)
	love.graphics.rectangle("fill", 25, 105, 50, 50)
	love.graphics.setColor(255,255,255,255)
end

-- Add the tasks to the root. You can __index the gamework table or copy its functions
-- for easier syntax.
root.addSubtask = gamework.addSubtask
root:addSubtask(rect)
root:addSubtask(rect2)

--==================================================================================================
	-- You can control the update and drawing order of subtasks by using setOrder().
	-- If order is not defined then it defaults to 0.
----------------------------------------------------------------------------------------------------
-- Define the keypressed callback for the rectangle drawing task.
function rect:keypressed(k)
	
	-- If we press up then set its order to 1. This will put it above the second rectangle.
	if k == "up" then 
		gamework.setOrder(self, 1)
	
	-- If we press down then set its order to -1. This will but it below the second rectangle.
	elseif k == "down" then
		gamework.setOrder(self, -1)
	end
end

-- Make some instructions
local instructions = {}
function instructions:draw()
	love.graphics.print("Press up and down to change the order.", 55, 80)
end

-- make it a subtask of our rectangle task
gamework.addSubtask(rect, instructions)

--==================================================================================================
	-- There are special subtasks called delegates. Delegates override its master and all of its other 
	-- subtasks. Delegates are really useful for game scenes.
----------------------------------------------------------------------------------------------------
-- Create an empty table for the delegate and a task that will switch to it.
local delegate = {}
local switcher = {}

-- When enter is pressed then the delegate is set.
function switcher:keypressed(k)
	if k == "return" then gamework.setDelegate(root, delegate) end
end

-- Draw the instructions.
function switcher:draw()
	love.graphics.print("Press enter to switch scenes!", 0 , 180)
end

-- When switched to the delegate then hit escape to return.
function delegate:keypressed(k)
	if k == "escape" then 
		gamework.remove(self) 
	end
end

-- Print the instructions.
function delegate:draw()
	love.graphics.print("Press escape to switch back!", 0 , 180)
end

-- Add the switcher task to the root.
gamework.addSubtask(root, switcher)

--==================================================================================================
	-- You can delegate tasks that are delegates themselves. In this way you can create a chain of 
	-- delegates.
----------------------------------------------------------------------------------------------------

-- Create a task that allows us to add another delegate to the first one.
local deeper = {}
gamework.addSubtask(delegate, deeper)

-- Table for the second delegate.
local delegate2 = {}

-- If enter is pressed then add the second delegate to the first one.
function deeper:keypressed(k)
	if k == "return" then gamework.setDelegate(delegate, delegate2) end
end
	
-- Draw the instructions. Also draw the master's instructions (which would be the first delegate).
function deeper:draw()
	local master = gamework.getMaster(self)
	master:draw()
	love.graphics.print("Press enter to go even deeper!", 0, 200)
end

-- Let the second delegate be able to remove itself.
function delegate2:keypressed(k)
	if k == "escape" then gamework.remove(self) end
end

-- User feedback
function delegate2:draw()
	local master = gamework.getMaster(self)
	love.graphics.print("That's deep, man!", 0, 220)
end

--==================================================================================================
	-- You can queue subtasks to be added through sequences. Sequences are useful for tasks that 
	-- must happen in sequential order parallel to other tasks. A common example is text dialogue 
	-- in RPGs. When you queue a task in a sequence you must speficify if that task is a halt task 
	-- or not. Halt tasks will prevent the sequence from continuing until that task is removed from 
	-- its master or gamework.continueSequence() is called.
----------------------------------------------------------------------------------------------------

-- These draw different words
local word1 = {draw = function(self) love.graphics.print("hello", 0, 240 ) end}
local word2 = {draw = function(self) love.graphics.print("world", 40, 260 ) end}
local word3 = {draw = function(self) love.graphics.print("from", 80, 280 ) end}
local word4 = {draw = function(self) love.graphics.print("sequence!", 120, 300) end}

-- This clears its master of any subtasks. "added" is callback specific to gamework. It's called
-- on a task when it is added as a subtask or delegate.
local clearer = {added = function(self) gamework.clearSubtasks(gamework.getMaster(self)) end}

-- Create a task that we can demonstrate sequences with. 
-- Copy some gamework functions as shortcuts
local sequencer = {}
sequencer.addSequence = gamework.addSequence
sequencer.clearSequence = gamework.clearSequence
sequencer.clearSubtasks = gamework.clearSubtasks
sequencer.waitSequence = gamework.waitSequence

function sequencer:keypressed(k)

	-- When shift is pressed
	if k == "lshift" or k == "rshift" then
	
		-- clear any ongoing tasks
		self:clearSequence()
		self:clearSubtasks()
		
		-- Add a series of tasks as a sequence. The sequence will print one word, wait a bit,
		-- and then print another.
		self:addSequence(word1, false)
		self:waitSequence(0.5)
		self:addSequence(word2, false)
		self:waitSequence(0.4)
		self:addSequence(word3, false)
		self:waitSequence(0.3)
		self:addSequence(word4, false)
		self:waitSequence(0.2)
			
		-- afterwards clear the sequencer of any subtasks
		self:addSequence(clearer, false)
			
	end
end

-- draw instructions
function sequencer:draw()
	love.graphics.print("Press shift to demo sequences", 0, 200)
	if gamework.getHaltSubtask(self) then 
		love.graphics.print("Sequence is active!", 0, 220) 
	end
end

-- add the sequencer as a subtask to root
gamework.addSubtask(root, sequencer)
--==================================================================================================





