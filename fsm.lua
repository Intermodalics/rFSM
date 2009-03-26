--
-- simple lua UML 2.0 state machine
-- 

function verify_fsm(fsm)
   -- checks:
   --  no duplicate states
   --  no transitions to invalid states
   --  unknown table attributes -> e.g. detect typos
   --  each fsm has initial_state
   --  each state has a name
   --  each transition has target
   return true
end

-- debugging helpers
function dbg(...) return nil end

-- function dbg(...)
--    arg.n = nil
--    io.write("DEBUG: ")
--    map(function (e) io.write(e, " ") end, arg)
--    io.write("\n")
-- end

function warn(...)
   arg.n = nil
   io.write("WARN: ")
   map(function (e) io.write(e, " ") end, arg)
   io.write("\n")
end

function err(...)
   arg.n = nil
   io.write("ERROR: ")
   map(function (e) io.write(e, " ") end, arg)
   io.write("\n")
end


-- get current state
function get_cur_state(fsm)
   return get_state_by_name(fsm, fsm.cur_state)
end

-- return a state specified by string
function get_state_by_name(fsm, name)
   local state = 
      filter(function (s)
		if s.name == name then
		   return true
		else return false
		end
	     end, fsm.states)
   return state[1]
end

-- transitions selection algorithm
function select_transition(state, event)
   transitions =
      filter(function (t)
		if t.event == event then
		   return true
		else return false
		end
	     end, state.transitions)
   if #transitions > 1 then
      warn("multiple valid transitions found, using first")
   end
   return transitions[1]
end
   
-- additional parameter: maxsteps required
-- returns number of steps performed
function step(fsm)
   local event = pick_event(fsm)
   
   if event == nil then
      dbg("event queue empty")
      return false
   else 
      dbg("got event: ", event)
   end
   
   local cur_state = get_cur_state(fsm)
   dbg("cur_state: ", table.tostring(cur_state))

   local trans = select_transition(cur_state, event)
   
   if not trans then
      warn('no transition found for event', event, '- dropping it.')
      return false
   end

   dbg("selected transition: ", table.tostring(trans))
   local new_state = get_state_by_name(fsm, trans.target)
   dbg("new_state: ", table.tostring(new_state))

   if trans.guard then
      if not eval(trans.guard) then
	 return count
      end
   end

      
   -- execute transition, RTCS starts here
   if cur_state.exit then eval(cur_state.exit) end
   if trans.effect then eval(trans.effect) end
   if new_state.entry then eval(new_state.entry) end
   fsm.cur_state = new_state.name
   -- RTCS ends here

   if new_state.doo then eval(new_state.doo) end
   
   return true
   
end

-- get an event from the queue
function pick_event(fsm)
   -- tbd: take deferred events into account
   return table.remove(fsm.queue, 1)
end

-- store an event in the queue
function send(fsm, event)
   table.insert(fsm.queue, event)
end

-- initalize state machine
function init(fsm)
   fsm.queue = {}
   fsm.cur_state = fsm.inital_state
end

-- imports
dofile("../mylib/misc.lua")
dofile("../mylib/functional.lua")

-- sample statemachine
fsm = { 
   inital_state = "off", 
   states = { { 
		 name = "on", 
		 entry = "print('entry on')", 
		 doo = "print('inside on do')", 
		 exit = "print('inside on exit')", 
		 transitions = { { event="off-button", target="off" } } },
	      { 
		 name = "off", 
		 entry = "print('entry off')", 
		 doo = "print('inside off do')", 
		 exit = "print('inside off exit')",
		 transitions = { { event="on-button", target="on" } } } 
	   }
}


-- here we go
-- eval(fsm.states.name)
init(fsm)
send(fsm, "invalid-event")
send(fsm, "on-button")
send(fsm, "off-button")
step(fsm)
step(fsm)
step(fsm)

