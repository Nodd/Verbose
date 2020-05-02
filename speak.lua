local addonName, Verbose = ...


function Verbose:GetRandomFromTable(t)
	if not t then return end

	local len = #t
	if len < 1 then return end

	local n = math.random(1, len);
	return t[n]
end

function Verbose:GetRandomMsg(messages)
    -- Get random message
    local msg = self:GetRandomFromTable(messages)
	if not msg then return end

    -- Replace from list randomly
    for listID, list in pairs(self.db.profile.lists) do
        local listStr = "<" .. list.name .. ">"
        local n
        repeat
            local element = self:GetRandomFromTable(list.values)
            msg, n = msg:gsub(listStr, element, 1)
        until(n == 0)
    end

    -- TODO: replace target...

	return msg
end

function Verbose:Speak(msgData)
    if not msgData then return end

    -- Check enabled
    if not msgData.enabled then print("local disabled") return end

    -- Check global cooldown
    local currentTime = GetServerTime()
    local lastTime = self.db.profile.lastTime or 0
    local elapsed = currentTime - lastTime
    if elapsed < self.db.profile.cooldown then print("on global CD")  return end

    -- Check event cooldown
    lastTime = msgData.lastTime or 0
    elapsed = currentTime - lastTime
    if elapsed < msgData.cooldown then print("on local CD")  return end

    -- Check probability
    if math.random(100) > msgData.proba * 100 then print("proba fail") return end

    -- All pass, speak to the world !
    message = self:GetRandomMsg(msgData.messages)
    if not message then print("no message") return end

    -- Update times
    msgData.LastTime = currenttime
    self.db.profile.lastTime = currenttime

    -- SendChatMessage("msg" ,"chatType" ,"language" ,"channel");
    SendChatMessage(message ,"SAY" ,nil ,"channel");
end
