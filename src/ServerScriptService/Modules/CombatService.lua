local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local CombatService = {}
CombatService.__index = CombatService

function CombatService.new(context)
	return setmetatable({Context=context, Enemies={}, LastAttack={}, LastAbility={}}, CombatService)
end

local function hpGui(parent, boss)
	local gui=Instance.new("BillboardGui")
	gui.Name="HP"; gui.Size=boss and UDim2.new(0,280,0,70) or UDim2.new(0,200,0,55)
	gui.StudsOffset=Vector3.new(0,boss and 6 or 4,0); gui.AlwaysOnTop=true; gui.MaxDistance=boss and 90 or 55; gui.Parent=parent
	local label=Instance.new("TextLabel")
	label.Name="Label"; label.Size=UDim2.fromScale(1,1); label.BackgroundColor3=Color3.fromRGB(20,22,30); label.BackgroundTransparency=.15
	label.BorderSizePixel=0; label.TextColor3=Color3.fromRGB(255,238,220); label.TextStrokeTransparency=.5; label.TextScaled=true; label.TextWrapped=true; label.Font=Enum.Font.GothamBold; label.Parent=gui
	local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,8); c.Parent=label
end

function CombatService:CreateModel(name,pos,color,boss)
	local model=Instance.new("Model"); model.Name=name; model.Parent=self.Context.WorldFolder:WaitForChild("Enemies")
	local body=Instance.new("Part"); body.Name="HumanoidRootPart"; body.Size=boss and Vector3.new(7,9,5) or Vector3.new(4,6,3); body.CFrame=CFrame.new(pos); body.Anchored=true; body.CanCollide=true; body.Color=color:Lerp(Color3.fromRGB(35,35,42),.22); body.Parent=model
	local head=Instance.new("Part"); head.Name="Head"; head.Size=boss and Vector3.new(5,5,5) or Vector3.new(3.4,3.4,3.4); head.Shape=Enum.PartType.Ball; head.CFrame=CFrame.new(pos+Vector3.new(0,boss and 7 or 4.5,0)); head.Anchored=true; head.CanCollide=false; head.Color=Color3.fromRGB(224,204,188); head.Parent=model
	local light=Instance.new("PointLight"); light.Color=color; light.Brightness=boss and 3 or 1.4; light.Range=boss and 24 or 12; light.Parent=body
	hpGui(head,boss); model.PrimaryPart=body; return model
end

function CombatService:UpdateLabel(model)
	local d=self.Enemies[model]; if not d then return end
	local head=model:FindFirstChild("Head"); local gui=head and head:FindFirstChild("HP"); local label=gui and gui:FindFirstChild("Label")
	if label then label.Text=(d.Boss and "BOSS • " or "")..d.Name.."\n"..math.max(0,math.floor(d.HP)).." / "..math.floor(d.MaxHP).." HP" end
end

function CombatService:AddEnemy(zone,index,boss)
	local pos
	if boss then pos=zone.Center+Vector3.new(0,8,-34) else local a=((index-1)/7)*math.pi*2; pos=zone.Center+Vector3.new(math.cos(a)*29,6,math.sin(a)*29) end
	local model=self:CreateModel(boss and "Rift Tyrant" or zone.EnemyName,pos,boss and Color3.fromRGB(235,70,150) or zone.Color,boss)
	self.Enemies[model]={Name=boss and "Rift Tyrant" or zone.EnemyName,HP=boss and 9500 or zone.EnemyHP,MaxHP=boss and 9500 or zone.EnemyHP,Damage=boss and 46 or zone.EnemyDamage,Coins=boss and 2400 or zone.RewardCoins,XP=boss and 1200 or zone.RewardXP,Gems=boss and 18 or 0,Zone=zone,Index=index,Boss=boss,Alive=true,Spawn=pos,LastHit=0}
	self:UpdateLabel(model)
end

function CombatService:ClosestEnemy(pos,range)
	local best,dist=nil,range
	for model,d in pairs(self.Enemies) do if d.Alive and model.Parent and model.PrimaryPart then local n=(model.PrimaryPart.Position-pos).Magnitude; if n<=dist then best,dist=model,n end end end
	return best,dist
end

function CombatService:ClosestPlayer(pos,range)
	local bp,br,bd=nil,nil,range
	for _,p in ipairs(Players:GetPlayers()) do local ch=p.Character; local h=ch and ch:FindFirstChildOfClass("Humanoid"); local r=ch and ch:FindFirstChild("HumanoidRootPart"); if h and h.Health>0 and r then local d=(r.Position-pos).Magnitude; if d<=bd then bp,br,bd=p,r,d end end end
	return bp,br,bd
end

function CombatService:Pulse(pos,color,size,time)
	local folder=self.Context.WorldFolder and self.Context.WorldFolder:FindFirstChild("WorldEvents"); if not folder then return end
	local p=Instance.new("Part"); p.Shape=Enum.PartType.Ball; p.Size=Vector3.one; p.CFrame=CFrame.new(pos); p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.Material=Enum.Material.Neon; p.Color=color; p.Transparency=.2; p.Parent=folder
	TweenService:Create(p,TweenInfo.new(time),{Size=Vector3.new(size,size,size),Transparency=1}):Play(); task.delay(time+.05,function() if p.Parent then p:Destroy() end end)
end

function CombatService:DamageNumber(model,amount,crit)
	if not model.PrimaryPart then return end
	local gui=Instance.new("BillboardGui"); gui.Size=UDim2.new(0,110,0,42); gui.StudsOffset=Vector3.new(math.random(-10,10)/10,4,0); gui.AlwaysOnTop=true; gui.Parent=model.PrimaryPart
	local l=Instance.new("TextLabel"); l.Size=UDim2.fromScale(1,1); l.BackgroundTransparency=1; l.Text=(crit and "CRIT " or "").."-"..amount; l.TextColor3=crit and Color3.fromRGB(255,222,90) or Color3.fromRGB(255,110,110); l.TextStrokeTransparency=.25; l.TextScaled=true; l.Font=Enum.Font.GothamBlack; l.Parent=gui
	TweenService:Create(gui,TweenInfo.new(.5),{StudsOffset=gui.StudsOffset+Vector3.new(0,2.5,0)}):Play(); TweenService:Create(l,TweenInfo.new(.5),{TextTransparency=1,TextStrokeTransparency=1}):Play(); task.delay(.55,function() if gui.Parent then gui:Destroy() end end)
end

function CombatService:Kill(player,model)
	local d=self.Enemies[model]; if not d or not d.Alive then return end; d.Alive=false
	local stats=player:FindFirstChild("leaderstats"); local profile=player:FindFirstChild("RiftProfile"); if not stats or not profile then return end
	local mult=self.Context.RewardMultiplier or 1; local coins=math.floor(d.Coins*mult); local xp=math.floor(d.XP*mult); stats.Coins.Value+=coins; self.Context.Services.DataService:AddXP(player,xp); profile.QuestKills.Value+=1
	if d.Boss then stats.Gems.Value+=d.Gems; profile.QuestBosses.Value+=1; self.Context:NotifyAll(player.Name.." defeated the RIFT TYRANT!","boss") else self.Context:Notify(player,"+"..coins.." Coins • +"..xp.." XP","loot") end
	self.Context.Services.QuestService:Check(player)
	for _,o in ipairs(model:GetDescendants()) do if o:IsA("BasePart") then o.CanCollide=false; TweenService:Create(o,TweenInfo.new(.28),{Transparency=1}):Play() end end
	local zone,index,boss=d.Zone,d.Index,d.Boss; task.delay(.35,function() self.Enemies[model]=nil; if model.Parent then model:Destroy() end end)
	task.delay(boss and self.Context.Config.Game.BossRespawnSeconds or self.Context.Config.Game.EnemyRespawnSeconds,function() if self.Context.WorldFolder and self.Context.WorldFolder.Parent then self:AddEnemy(zone,index,boss) end end)
end

function CombatService:Hit(player,model,damage,crit)
	local d=self.Enemies[model]; if not d or not d.Alive then return end; d.HP-=damage; self:DamageNumber(model,damage,crit); self:UpdateLabel(model); if d.HP<=0 then self:Kill(player,model) end
end

function CombatService:Attack(player)
	local now=os.clock(); local cfg=self.Context.Config.Game; if now-(self.LastAttack[player] or 0)<cfg.AttackCooldown then return end
	local ch=player.Character; local hum=ch and ch:FindFirstChildOfClass("Humanoid"); local root=ch and ch:FindFirstChild("HumanoidRootPart"); local tool=ch and ch:FindFirstChild("Rift Blade"); if not hum or hum.Health<=0 or not root or not tool then return end
	self.LastAttack[player]=now; self:Pulse((root.CFrame*CFrame.new(0,0,-4)).Position,Color3.fromRGB(185,120,255),7,.18)
	local target=self:ClosestEnemy(root.Position,cfg.AttackRange); local stats=player:FindFirstChild("leaderstats"); if not target or not stats then return end
	local crit=math.random()<=.08; self:Hit(player,target,math.floor(cfg.BaseDamage*stats.Power.Value*(crit and 1.75 or 1)),crit)
end

function CombatService:Ability(player,name)
	local cfg=self.Context.Config.Game; local now=os.clock(); local key=tostring(player.UserId)..":"..name; local cd=name=="Dash" and cfg.DashCooldown or cfg.BurstCooldown; if now-(self.LastAbility[key] or 0)<cd then return end
	local ch=player.Character; local hum=ch and ch:FindFirstChildOfClass("Humanoid"); local root=ch and ch:FindFirstChild("HumanoidRootPart"); if not hum or hum.Health<=0 or not root then return end; self.LastAbility[key]=now
	if name=="Dash" then local v=root.CFrame.LookVector; local d=Vector3.new(v.X,0,v.Z); if d.Magnitude>.1 then root.AssemblyLinearVelocity=d.Unit*cfg.DashSpeed+Vector3.new(0,math.max(root.AssemblyLinearVelocity.Y,0),0); self:Pulse(root.Position,Color3.fromRGB(110,185,255),6,.22) end
	elseif name=="Burst" then local stats=player:FindFirstChild("leaderstats"); if not stats then return end; self:Pulse(root.Position,Color3.fromRGB(210,95,255),cfg.BurstRange*2,.35); local dmg=math.floor(cfg.BaseDamage*stats.Power.Value*cfg.BurstDamageMultiplier); local list={}; for m,d in pairs(self.Enemies) do if d.Alive and m.Parent and m.PrimaryPart and (m.PrimaryPart.Position-root.Position).Magnitude<=cfg.BurstRange then table.insert(list,m) end end; for _,m in ipairs(list) do self:Hit(player,m,dmg,false) end end
end

function CombatService:StepAI(dt)
	local cfg=self.Context.Config.Game; local now=os.clock()
	for model,d in pairs(self.Enemies) do if d.Alive and model.Parent and model.PrimaryPart then local body=model.PrimaryPart; local p,pr,dist=self:ClosestPlayer(body.Position,cfg.EnemyAggroRange); local target=p and Vector3.new(pr.Position.X,d.Spawn.Y,pr.Position.Z) or d.Spawn
		if p and dist<=cfg.EnemyAttackRange then local hum=p.Character and p.Character:FindFirstChildOfClass("Humanoid"); if hum and now-d.LastHit>=cfg.EnemyAttackCooldown then d.LastHit=now; hum:TakeDamage(d.Damage); self:Pulse(pr.Position,d.Boss and Color3.fromRGB(255,70,145) or d.Zone.Color,d.Boss and 8 or 5,.16) end
		else local delta=target-body.Position; local flat=Vector3.new(delta.X,0,delta.Z); if flat.Magnitude>.5 then local speed=d.Boss and cfg.BossMoveSpeed or cfg.EnemyMoveSpeed; local nextPos=body.Position+flat.Unit*math.min(flat.Magnitude,speed*dt); nextPos=Vector3.new(nextPos.X,d.Spawn.Y,nextPos.Z); model:PivotTo(CFrame.lookAt(nextPos,Vector3.new(target.X,nextPos.Y,target.Z))) end end
	end end
end

function CombatService:GiveBlade(player)
	local backpack=player:WaitForChild("Backpack"); for _,c in ipairs({backpack,player.Character}) do if c then local old=c:FindFirstChild("Rift Blade"); if old then old:Destroy() end end end
	local tool=Instance.new("Tool"); tool.Name="Rift Blade"; tool.ToolTip="Click / Tap to attack"; tool.CanBeDropped=false; tool.RequiresHandle=true
	local h=Instance.new("Part"); h.Name="Handle"; h.Size=Vector3.new(.45,4.5,.65); h.Color=Color3.fromRGB(184,118,255); h.Material=Enum.Material.Neon; h.CanCollide=false; h.Massless=true; h.Parent=tool
	local light=Instance.new("PointLight"); light.Color=h.Color; light.Brightness=1.4; light.Range=8; light.Parent=h; tool.Grip=CFrame.new(0,-1.2,0)*CFrame.Angles(0,0,math.rad(12)); tool.Parent=backpack
	task.delay(.4,function() local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if hum and tool.Parent==backpack then hum:EquipTool(tool) end end)
end

function CombatService:Start()
	for _,zone in ipairs(self.Context.Config.Zones) do for i=1,7 do self:AddEnemy(zone,i,false) end end; self:AddEnemy(self.Context.Config.Zones[4],0,true)
	self.Context.Remotes.Attack.OnServerEvent:Connect(function(p) self:Attack(p) end)
	self.Context.Remotes.Ability.OnServerEvent:Connect(function(p,name) if typeof(name)=="string" and (name=="Dash" or name=="Burst") then self:Ability(p,name) end end)
	RunService.Heartbeat:Connect(function(dt) self:StepAI(dt) end)
end

return CombatService
