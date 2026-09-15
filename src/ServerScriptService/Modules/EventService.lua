local EventService = {}
EventService.__index = EventService

function EventService.new(context)
	local self = setmetatable({}, EventService)
	self.Context = context
	return self
end

function EventService:StartRiftSurge()
	if self.Context.RewardMultiplier and self.Context.RewardMultiplier > 1 then return end
	local cfg = self.Context.Config.WorldEvents
	self.Context.RewardMultiplier = 2
	self.Context.Remotes.WorldEvent:FireAllClients("RIFT SURGE", cfg.RiftSurgeDuration)
	self.Context:NotifyAll("RIFT SURGE! Enemy Coins and XP are doubled for " .. cfg.RiftSurgeDuration .. " seconds.", "event")

	task.delay(cfg.RiftSurgeDuration, function()
		self.Context.RewardMultiplier = 1
		self.Context:NotifyAll("The Rift Surge has ended.", "info")
	end)
end

function EventService:Start()
	local cfg = self.Context.Config.WorldEvents
	task.spawn(function()
		task.wait(cfg.RiftSurgeFirstDelay)
		while self.Context.WorldFolder and self.Context.WorldFolder.Parent do
			self:StartRiftSurge()
			task.wait(cfg.RiftSurgeInterval)
		end
	end)
	print("[World Events] Rift Surge active; hidden eggs are owned by WildEggService")
end

return EventService
