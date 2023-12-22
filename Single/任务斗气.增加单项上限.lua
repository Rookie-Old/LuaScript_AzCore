print(">>Script: QuestStateSystem...OK")

local STATE = {}
STATE.Config = {
    itemEntry = 600000,   --物品id,需要那些可以点击使用的物品，比如炉石之类的
    questToStateRate = 5, --每个任务提供多少点自由属性

    ResetItemEntry = 58005, --重置加点所需要的物品材料
    ResetItemCount = 1, --重置加点所需要的物品数量
}

STATE.core = {{"力量",7780},{"敏捷",7778},{"耐力",7455},{"智力",7792},{"精神",7456},{"急速",300001},{"暴击",300002},}

local LIMIT = {
    {min =  1,max = 10,upper = 10 }, -- 等级在 1 ~ 10级时 单项加点上限为：10
    {min = 11,max = 20,upper = 25 }, 
    {min = 21,max = 30,upper = 45 }, 
    {min = 31,max = 40,upper = 65 }, 
    {min = 41,max = 50,upper = 85 }, 
    {min = 51,max = 60,upper = 100 }, 
    {min = 61,max = 70,upper = 200 }, 
    {min = 71,max = 80,upper = 300 },
}

STATE.PlayerData = {}

function Player:SetState(t,v)
    if v < 0 then v = 0 end
    local pGUID = self:GetGUIDLow()
    local s = STATE.core[t][2]
    STATE.PlayerData[pGUID][t] = v
    self:RemoveAura(s)
    if v ~= 0 then
        self:CastCustomSpell(self,s,true,v)
    end
end

function Player:GetState(t)
    local pGUID = self:GetGUIDLow()
    if (STATE.PlayerData[pGUID][t]~=nil) then
        return STATE.PlayerData[pGUID][t]
    end
end

function Player:AddStat(t,v)
    if v == nil then v = 1 end
    STATE.PlayerData[self:GetGUIDLow()][t] = self:GetState(t) + v
end

function Player:GetQuestCount()
    local pGUID = self:GetGUIDLow()
    return STATE.PlayerData[pGUID].questCount
end

function Player:QueryQuestCount()
    self:SaveToDB()
    local pGUID = self:GetGUIDLow()
    local query = CharDBQuery("SELECT counter FROM character_achievement_progress WHERE criteria=3631 and guid="..pGUID.." LIMIT 1")
    if query then
        return query:GetUInt32(0)
    end
    return 0
end

function Player:GetUsePoints()
    local usePoints = 0
    for i=1,7 do
        usePoints = usePoints + self:GetState(i)
    end
    return usePoints
end

function Player:GetPoints()
    return math.floor(self:GetQuestCount()*STATE.Config.questToStateRate) - self:GetUsePoints()
end

function Player:ResetState()
    for i=1,7 do
        self:SetState(i,0)
    end
    self:SaveState()
end

function Player:SaveState()
    CharDBExecute(string.format("REPLACE INTO character_Quest_State_System (Guid,Strength,Agility,Stamina,Intelligence,Spirit,rapidly,Critical) values (%s,%s,%s,%s,%s,%s,%s,%s)",
    self:GetGUIDLow(),self:GetState(1),self:GetState(2),self:GetState(3),self:GetState(4),self:GetState(5),self:GetState(6),self:GetState(7)))
end

function Player:GetUpperLimit()
    local level = self:GetLevel()
    local currLimit = 0
    for i=1, #LIMIT do
        if(level >= LIMIT[i].min and level <= LIMIT[i].max) then
            currLimit = LIMIT[i].upper
            break
        end
    end
    return currLimit
end

function STATE.ItemOnUse(event, player, item)
    if (STATE.PlayerData[player:GetGUIDLow()]==nil) then
        STATE.Onlogin(event, player)
    end
    if (player:IsInCombat()) then
		return false
	end
    STATE.GossipHello(event, player, item)
    return false
end

function STATE.GossipHello(event, player, item)
    player:GossipClearMenu()
    player:GossipMenuAddItem(1,string.format("完成每个任务将获得%s点潜力点数。|n( |cFFA50000%s|r \\ |cFF006699%s|r ) |n|cFFFF0000当前等级得单项上限为：%s",
    STATE.Config.questToStateRate,player:GetPoints(),math.floor(player:GetQuestCount()*STATE.Config.questToStateRate), player:GetUpperLimit()),
    0,0,false,"点击确认将重置未保存的加点数据!")
   
    for i = 1,7 do
        player:GossipMenuAddItem(3,">>  "..STATE.core[i][1].." + |cFF006699"..player:GetState(i).."|r",0,i)
    end
    if (player:GetUsePoints() > 0) then
        player:GossipMenuAddItem(4,"|cff0000ff★保存★",0,998,false,"确定保存吗?")
        player:GossipMenuAddItem(2,"【重置加点分配】",0,999,false,"确定重置吗？\n\n需要消耗:"..GetItemLink(STATE.Config.ResetItemEntry).." x "..STATE.Config.ResetItemCount)
    end
    player:GossipSendMenu(100, item)
    return false
end

function STATE.Onlogin(event, player)
    local pGUID = player:GetGUIDLow()
    local query = CharDBQuery("SELECT Guid,Strength,Agility,Stamina,Intelligence,Spirit,rapidly,Critical FROM character_Quest_State_System WHERE guid="..pGUID)
    STATE.PlayerData[pGUID] = {0,0,0,0,0,0,0,questCount = 0}
    if(query) then
        repeat
            for i=1,7 do
                STATE.PlayerData[pGUID][i] = query:GetUInt32(i)
                player:SetState(i,player:GetState(i))
            end
        until not query:NextRow()
    else
        for i=1,7 do
            STATE.PlayerData[pGUID][i] = 0
        end
    end
    STATE.PlayerData[pGUID].questCount = player:QueryQuestCount()
end

function STATE.GossipSelect(event, player, item, sender, intid)
    if intid == 0 then
        STATE.Onlogin(event, player)
        STATE.GossipHello(event, player, item)
        return
    end
   
    if intid == 999 then
        if (player:GetState(1) + player:GetState(2) + player:GetState(3) + player:GetState(4) + player:GetState(5) + player:GetState(6) + player:GetState(7)) <= 0 then
            player:SendBroadcastMessage("你当前并未加点，无需重置。")
        else
            if player:HasItem(STATE.Config.ResetItemEntry,STATE.Config.ResetItemCount) then   
                player:RemoveItem(STATE.Config.ResetItemEntry,STATE.Config.ResetItemCount)
                player:ResetState()
                player:SendBroadcastMessage("重置完毕~~~~")
            else
                player:SendBroadcastMessage("重置失败，缺少"..GetItemLink(STATE.Config.ResetItemEntry).." x "..STATE.Config.ResetItemCount)
            end
        end
        STATE.GossipHello(event, player, item)
        return
    end
   
    if intid == 998 then
        for i = 1,7 do
            player:SetState(i,player:GetState(i))
        end
        player:SaveState()
        STATE.GossipHello(event, player, item)
        return
    end
   
    if (intid >= 1 and intid <= 7) then
        if player:GetPoints() <= 0 then
            player:SendBroadcastMessage("剩余潜能点数不足，请继续完成任务吧~")
            STATE.GossipHello(event, player, item)
            return
        end
        
        if ((player:GetUpperLimit() - player:GetState(intid)) < STATE.Config.questToStateRate) then
            player:SendBroadcastMessage("已达上限，不可再增加属性了~")
            STATE.GossipHello(event, player, item)
            return
        end

        player:AddStat(intid, STATE.Config.questToStateRate)
        STATE.GossipHello(event, player, item)
    end
end

CharDBExecute([[
CREATE TABLE IF NOT EXISTS `character_Quest_State_System` (   
  `guid` int(11) NOT NULL,
  `Strength` int(11) NOT NULL DEFAULT '0',
  `Agility` int(11) NOT NULL DEFAULT '0',
  `Stamina` int(11) NOT NULL DEFAULT '0',
  `Intelligence` int(11) NOT NULL DEFAULT '0',
  `Spirit` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
]])

RegisterPlayerEvent(3, STATE.Onlogin)
RegisterItemGossipEvent(STATE.Config.itemEntry, 1, STATE.ItemOnUse)
RegisterItemGossipEvent(STATE.Config.itemEntry, 2, STATE.GossipSelect)