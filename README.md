#gamework
========

gamework is an **experimental** library is used to control process flow for the LOVE 2d game engine. It does this by forwarding LOVE callbacks to processes called tasks. Each task can have their own set of tasks called subtasks. Those subtasks can have their own subtasks and so on. Using this tree-like design it is easy to control the flow of command to create structures like scenes, sequences, component entities, etc.

----------------------------------------------------------------------------------------------------
# Functions

**addSequence**(`task, subtask, halt, ...`)         
Queues a `subtask` to be added to the master `task`. If `halt` is true then the subtask is flagged as a halt task. This triggers the subtask:added(`...`) callback when the queued task is promoted to a subtask.

**addSubtask**(`task, subtask, ...`)     
Adds a `subtask` to the master `task`. This calls subtask:added(...).     

**attachedToRoot**(`task`)     
Returns true if the `task` is attached to the root.     

**callback** (`task, cb, spread, ...`)     
Triggers a callback starting at `task` and forwards it to its subtasks. This checks to see if task[`cb`] exists and if it does it calls it as a function with the parameters (task, `...`). The callback will disseminate to its subtasks depending on the _spread_ type. Spread can be "normal" which means the callback will spread to all undelegated subtasks. It can be "delegated" which will spread the callback to all subtasks even if they are delegated (but not delegates themselves). Finally spread can be "all" which will spread the callback to all subtasks and delegates regarless if they are delegated or not.     

**clearSequence** (`task`)     
Clears any queued subtasks in a `task's` sequence.     

**clearSubtasks** (`task`)     
Clears a `task` of all of its subtasks.    

**continueSequence** (`task`, `time`)     
Continues a `task's` sequence regardless if the halt task is still active or not. If the `time` parameter has a value then the next task in the sequence has its update callback immediately triggered with _time_ being used as delta time. If you have a halt task continue the sequence during it's update then it can be useful to pass on the remaining delta time for precise timing.

**countSequence** (`task`)     
Returns the number of queued subtasks in a `task's` sequence.     

**countSubtasks** (`task`)     
Returns the number of subtasks that a `task` has.     

**getDelegate** (`task`)     
Returns the `task's` delegate.     

**getHaltSubtask** (`task`)     
Returns the `task's` halt subtask, which is a subtask that prevents a sequence from continuing as long as it's alive.     

**getMaster**(`subtask`)     
Gets a `subtask's` master.     

**getOrder**(`task`)     
Gets the callback order of a `task`.     

**getRoot**()     
Returns the root task.     

**getTaskType**(`task`)     
Returns the type of a `task`.     

**initialize**()     
Initalizes gamework. Call this only once. If you plan to define any love callbacks then make sure you call this afterwards.     

**iterateSequence**(`task`)     
Iterates over all of a `task's` queued tasks.     
```lua     
     for queuedTask in gamework.iterateSequence(task) do     
       -- do something with the queued tasks 
     end     
```

**iterateSubtasks**(`task`)     
Iterates over all  of a `task's` subtasks     
```lua     
     for subtask in gamework.iterateSubtasks(task) do     
       -- do something with the tasks     
     end     
```

**renameCallback**(`original, new`)     
Renames an `original` callback to a `new` one. This is useful if a callback name conflicts with another value in your tasks.     

**setDelegate**(`task, subtask, ...`)     
Sets a delegate `subtask` for a `task`. This triggers subtask:added(`...`).

**setOrder**(`task, order`)     
Sets a `task's` callback `order`     

**topDelegate**(`task`)     
If the `task` is part of a delegate chain then the top delegate is returned.     

**remove**(`subtask, ...`)     
Remove a `subtask` from its master. This triggers subtask:removed(`...`).

**waitSequence**(`task, time`)     
Creates a queued task that pauses a `task's` sequence progression by a certain amount of `time`.

----------------------------------------------------------------------------------------------------
##Forwarded LOVE Callbacks     
Called on all undelegated tasks that are attached to the root.     

**draw**         				
**focus**     
**joystickpressed**     
**joystickreleased**     
**keypressed**     
**keyreleased**     
**load**     
**mousepressed**     
**mousereleased**     
**quit**     
**update**     

----------------------------------------------------------------------------------------------------
##GameWork Callbacks

**added**			
Called when a task or its master is added and attached to the root     

**removed**			
Called when a task or its master is removed and severed from the root     

**delegated**		
Called when a task is assigned a delegate     

**undelegated**		
Called when a task has its delegate removed      

----------------------------------------------------------------------------------------------------
##Glossary

**Attached to the root**     
A task which has its master as the root or has its master attached to the root. In other words, if you follow the chain of masters you eventually reach the root.

**Delegate**    
A subtask that takes overloads its master and all of its other subtasks. Overloaded (delegated) tasks will not have love callbacks forwarded to them.

**Delegate Chain**    
When delegates have delegates themselves it creates a "chain" of several delegates. The delegate at the end of the chain that receives all of the callbacks is called the "top" delegate.

**Delegated Task**    
A task that has its normal operations halted due to a delegate. 

**Halt Task**    
A halt task is a subtask that stops a sequence from progressing further until it is removed from its master or gamework.continueSequence() is called.

**Sequence**    
A sequence is a series of queued tasks waiting to become subtasks. The subtasks are added to their master in the order that they were added to the sequence.
 
**Subtask**    
A task that is a subordinant of another task, which is called its master. Subtasks have their callbacks triggered immediately after their master's.

**Task**      
A task is simply a table but used as a unit inside gamework. When attached to the root it will have certain callback functions automatically triggered.

**Master**    
A task is the master of another task if it owns it as a subtask. A subtask can only have one master.

**Order**     
Subtasks with lower orders have their callbacks triggered first. The default order is zero and can be set with gamework.setOrder(). This is useful if you want certain tasks to be updated or drawn before others.

**Queued Task**    
An inactive subtask that is queued in a sequence

**Root**    
The entry point task for gamework. The root task will be called first. Other tasks must be added as subtasks to the root or subtasks of those subtasks, etc.

----------------------------------------------------------------------------------------------------
##Private Values   
Gamework needs to store private values inside tasks in order to work. Writing to these directly is a good way to break everything. Only values that the task needs to operate will be defined.  

**_gw_master**     					
A task's master.     

**_gw_delegate**    
A task's delegate. Overloads the task and all of its other subtasks    . 

**_gw_index**    
The index of the task in it's master's subtask list.    

**_gw_order**					
The order that the task is called in, in relation to other subtasks.    

**_gw_subtasks**				
A task's subtasks. Their callbacks are called after their master's.     

**_gw_subtasksDirty**			
If true then the _gw_subtasks table needs to be sorted.    

**_gw_subtasksSize**    			
The number of subtasks the task contains 

**_gw_sequenceQueue**			
A queue of tasks to become subtasks.     

**_gw_sequenceLeft**			
The leftmost value in the sequence queue.     

**_gw_sequenceRight**			
The rightmost value in the sequence queue.     

**_gw_sequenceHaltActive**		
The subtask that is halting the sequence.     

**_gw_sequenceHaltTasks**		
Keeps track of what queued tasks will halt the sequence when they become active subtasks.  

**_gw_sequenceParameters**		
Stores parameters from sequenceAdd() for queued subtasks. When a queued task becomes a subtask then the added() callback is triggered and these parameters are passed.     

**_gw_sequenceSize**    			
The number of queued tasks in sequence.

**_gw_taskType**				
The type of task this is. Can be nil, "subtask", "delegate", or "queued".    

----------------------------------------------------------------------------------------------------
