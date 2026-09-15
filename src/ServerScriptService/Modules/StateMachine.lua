--[[
State machine helper adapted from Roblox Corporation's MIT-licensed
`resources/experiences/npc-state-machine/SimpleStateMachine` example.
See docs/THIRD_PARTY.md for attribution and license notes.
]]

local StateMachine = {}

function StateMachine.new(initialState, context)
	return {
		activeState = initialState,
		context = context or {},
		transitions = {},
	}
end

function StateMachine.addTransition(machine, startStates, endState, test)
	table.insert(machine.transitions, {
		startStates = startStates,
		endState = endState,
		test = test,
	})
end

function StateMachine.tick(machine)
	local activeState = machine.activeState
	local context = machine.context

	for _, transition in ipairs(machine.transitions) do
		local fromActiveState = false
		for _, startState in ipairs(transition.startStates) do
			if startState == activeState then
				fromActiveState = true
				break
			end
		end

		if fromActiveState and transition.test(context) then
			if activeState.onExit then activeState.onExit(context) end
			machine.activeState = transition.endState
			if transition.endState.onEnter then transition.endState.onEnter(context) end
			return true
		end
	end

	if activeState.onStay then activeState.onStay(context) end
	return false
end

return StateMachine
