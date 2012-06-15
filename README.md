gamework
========

The gamework library is used to control process flow for the LOVE 2d game engine. It does this by forwarding LOVE callbacks to processes called tasks. Each task can have their own set of tasks called subtasks. Those subtasks can have their own subtasks and so on. Using this tree-like design it is easy to control the flow of command to create structures like scenes, sequences, component entities, etc.

----------------------------------------------------------------------------------------------------
## API

**addSequence(_task, subtask, halt, ..._)         
Queues a _subtask_ to be added through sequence to the master _task_. If _halt_ is true then the subtask is flagged as a halt task. This triggers the subtask:added(...) callback when the queued task is promoted to a subtask.

**addSubtask(_task, subtask, ..._)     
Adds a _subtask_ to _task_. This calls subtask:added(...).     

**attachedToRoot**(_task_)     
Returns true if the _task_ is attached to the root.     

**callback** (_task, cb, spread, ..._)     
Chains a callback starting at _task_ and travels to its subtasks. This checks to see if task[_cb_] exists and if it does it calls it as a function with the parameters (task, ...). The callback will disseminate to its subtasks depending on the _spread_ type. Spread can be "normal" which means the callback will spread to all undelegated subtasks. It can be "delegated" which will spread the callback to all subtasks even if they are delegated (but not delegates themselves). Finally spread can be "all" which will spread the callback to all subtasks and delegates regarless if they are delegated or not.     

**clearSequence** (_task_)     
Clears any queued subtasks in a _task's_ sequence.     

**clearSubtasks** (_task_)     
Clears a _task's_ of all of its subtasks.    

**continueSequence** (_task_, _time_)     
Continues a _task's_ sequence regardless if the halt task is still active or not. If a value for _time_ is set then the next queued task's update callback is immediately triggered with _time_ being used as delta time. If you have a halt task continue the sequence during it's update then it can be useful to pass on the remaining delta time for precise timing.

**countSequence** (_task_)     
Returns the number of queued subtasks in a _task's_ sequence.     

**countSubtasks** (_task_)     
Returns the number of subtasks a _task_ has.     

**getDelegate** (_task_)     
Returns the _task's_ delegate.     

**getHaltSubtask** (_task_)     
Returns the _task's_ halt subtask, which is a subtask that prevents a sequence from continuing as long as it's alive.     

**getMaster**(_subtask_)     
Gets a _subtask's_ master.     

**getOrder**(_task_)     
Gets the order of a _task_.     

**getRoot**()     
Returns the root task.     

**getTaskType**(_task_)     
Returns the type of a _task_.     

**initialize**()     
Initalizes gamework. Call this only once. If you plan to define any love callbacks then make sure you call this afterwards.     

**iterateSequence**(_task_)     
Iterates over all of a _task's_ queued tasks.     

**iterateSubtasks**(_task_)     
Iterates over all  of a _task's_ subtasks     

_example:_     
```lua     
     for subtask in gamework.iterateSubtasks(task) do     
       -- do something with the tasks     
     end     
```

**renameCallback**(_original, new_)     
Renames an _original_ callback to a _new_ one. This is useful if a callback name conflicts with another value in your tasks.     

**setDelegate**(_task, subtask, ..._)     
Sets a delegate _subtask_ for a _task_. This triggers subtask:added(...).

**setOrder**(_task, order_)     
Sets a _task's order_     

**topDelegate**(_task_)     
If the _task_ is part of a delegate chain then the top delegate is returned.     

**remove**(_subtask_, ...)     
Remove a _subtask_ from its master. This triggers subtask:removed(...).

**waitSequence**(_task_, _time_)
Creates a queued task that pauses a _task's_ sequence progression by a certain amount of _time_.

----------------------------------------------------------------------------------------------------
##Forwarded LOVE Callbacks     
Called on all undelegated tasks attached to the root.     

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

**Task**     
A task is simply a table but used as a unit inside gamework. When attached to the root it will have certain callback functions automatically triggered.

**Subtask**
A task that is a subordinant of another task, which is called its master. Subtasks have their callbacks triggered immediately after their master's.

**Master**
A task is the master of another task if it owns it as a subtask. A subtask can only have one master.

**Sequence**
A sequence is a series of queued tasks waiting to become subtasks. The subtasks are added to their master in the order that they were added to the sequence.

**Queued Task**
A subtask that is queued in a sequence

**Halt Task**
A halt task is a subtask that stops a sequence from progressing further until it is removed from its master or gamework.contineuSequence() is called.

**Delegate**
A subtask that takes overloads its master and all of its other subtasks. Overloaded (delegated) tasks will not have love callbacks forwarded to them.

**Delegate Chain**
When delegates have delegates themselves it creates a "chain" of several delegates. The delegate at the end of the chain that receives all of the callbacks is called the "top" delegate.

**Delegated Task**
A task that has its normal operations halted due to a delegate. 

**Attached to the root**
A task who has the root task for its master. 

**Root**
The entry point task for gamework. The root task will be called first. Other tasks must be added as subtasks to the root or subtasks of those subtasks, etc.

**Order**
Subtasks with lower orders have their callbacks triggered first. The default order is zero and can be set with gamework.setOrder(). This is useful if you want certain tasks to be updated or drawn before others.

----------------------------------------------------------------------------------------------------
##Private Values   
Gamework needs to store private values inside tasks in order to work. Writing to these directly is a good way to break everything. Only values that the task needs to operate will be defined.  

**_gw_master*					
A task's master.     

**_gw_delegate**				
A task's delegate. Overloads the task and all of its other subtasks     

**_gw_order**					
The order that the task is called in, in relation to other subtasks     

**_gw_subtasks**				
A task's subtasks. Their callbacks are called after their master's.     

**_gw_subtasksDirty**			
If true then the __subtasks table needs to be sorted     

**_gw_sequenceQueue**			
A queue of tasks to become subtasks     

**_gw_sequenceLeft**			
The leftmost value in the sequence queue     

**_gw_sequenceRight**			
The rightmost value in the sequence queue     

**_gw_sequenceHaltActive**		
The subtask task that is halting the sequence.     

**_gw_sequenceHaltTasks**		
Keeps track of what tasks will halt the sequence when active     

**_gw_sequenceParameters**		
task:added() parameters for queued subtasks.     

**_gw_taskType**				
The type of task this is. Can be nil, "subtask", "delegate", or "queued"     

----------------------------------------------------------------------------------------------------