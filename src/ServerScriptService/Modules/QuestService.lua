local QuestService = {}
QuestService.__index = QuestService

function QuestService.new(context)
	local self = setmetatable({}, QuestService)
	self.Context = context
	return self
end

function QuestService:Check(player)
	local stats = player:FindFirstChild("leaderstats")
	local profile = player:FindFirstChild("RiftProfile")
	if not stats or not profile then return end

	local mappings = {
		{Progress = "QuestKills", Done = "QuestKillsDone", Config = self.Context.Config.Quests[1]},
		{Progress = "QuestHatches", Done = "QuestHatchesDone", Config = self.Context.Config.Quests[2]},
		{Progress = "QuestBosses", Done = "QuestBossesDone", Config = self.Context.Config.Quests[3]},
	}

	for _, mapping in ipairs(mappings) do
		local progress = profile:FindFirstChild(mapping.Progress)
		local done = profile:FindFirstChild(mapping.Done)
		local quest = mapping.Config
		if progress and done and not done.Value and progress.Value >= quest.Target then
			done.Value = true
			stats.Coins.Value += quest.Coins
			stats.Gems.Value += quest.Gems
			local reward = "+" .. quest.Coins .. " Coins"
			if quest.Gems > 0 then
				reward ..= " +" .. quest.Gems .. " Gems"
			end
			self.Context:Notify(player, "MISSION COMPLETE: " .. quest.Title .. " • " .. reward, "success")
		end
	end
end

return QuestService
