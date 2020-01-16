-- output color
local color = "|cFFD2B48C";
local highlight = "|cFFd8c7af";

-- fart tracking
local DB = {};
local NF_DB = {};
local waiting = { iFartedOn = {}, fartedOnMe = {} };

-- register events
local FP = CreateFrame("Frame");
FP:RegisterEvent("ADDON_LOADED");
FP:RegisterEvent("PLAYER_LOGOUT");
FP:RegisterEvent("CHAT_MSG_TEXT_EMOTE");
FP:SetScript("OnEvent",function(self,event,...) self[event](self,event,...); end);

-- load the DBs
function FP:ADDON_LOADED()
	-- saved per character
	FARTPATROL_DB = FARTPATROL_DB or { iFartedOn = {}, fartedOnMe = {} };
	DB = FARTPATROL_DB;	
	-- saved per account
	NOFART_DB = NOFART_DB or { noFartZone = {} };
	NF_DB = NOFART_DB;
end

-- add the current zone to the no fart zone list
local function addNoFartZone() 
	local name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceMapID, instanceGroupSize = GetInstanceInfo();
	NF_DB.noFartZone[instanceMapID] = true;
end

-- delete the current zone from the no fart list
local function delNoFartZone() 
	local name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceMapID, instanceGroupSize = GetInstanceInfo();
	NF_DB.noFartZone[instanceMapID] = nil;
end

-- check if zone is a valid fart zone (checks no fart zone list)
local function isValidFartZone()
	-- check to see if all chat is toggled off
	if NF_DB.noFartZone["ALL"] == true then 
		print(color .. "FartPatrol" .. highlight .. " /say has been disabled. Toggle it on using /fartpatrol chaton");
		return false;
	end
	-- check to see if zone chat is toggled off
	local name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceMapID, instanceGroupSize = GetInstanceInfo();
	if NF_DB.noFartZone[instanceMapID] == true then 
		print(color .. "FartPatrol" .. highlight .. " /say for this zone has been disabled. Toggle it on using /fartpatrol zoneon");
		return false;
	end
	-- if we made it here, chat is not toggled off
	return true;
end

-- play fart sound file
local function playFartSound()
	-- PlaySound(117484, "Master");
	PlaySoundFile("interface\\addons\\FartPatrol\\fart.ogg", "Master");
end

-- format text names to match Blizzard convention
local function formatName(msg)
	local name, junk = msg:match("^(%S*)%s*(.-)$");
	name = name:sub(1,1):upper()..name:sub(2):lower();
	return name;
end

-- /fart events - count who has been farted on
hooksecurefunc("DoEmote", function(token, unit)
	token = token:lower();
	-- check for fart token
	if token ~= "fart" then 
		return; -- not a fart emote, just return
	end 
	
	-- only count farts on valid player targets
	-- set the unit to the target
	if not unit or unit == "" then
		unit = "target";
	end
	
	-- check if unit exists and is not self
	if UnitExists(unit) and not UnitIsUnit(unit, "player") then
		-- check if unit is a player
		if UnitIsPlayer(unit) then
			local name = UnitName(unit);
			-- check if fart spam
			if waiting.iFartedOn[name] == nil then
				-- count the fart
				DB.iFartedOn[name] = (DB.iFartedOn[name] or 0) + 1;
				-- get updated fart count
				local fartcount = DB.iFartedOn[name];
				-- turn on fart spam protection
				waiting.iFartedOn[name] = true;
				C_Timer.After(10, function() waiting.iFartedOn[name] = nil; end); -- prevent /fart spam from counting
				-- play a fart sound
				playFartSound();
				if isValidFartZone() then
					-- chat
					SendChatMessage("Farted on "..name..". Total farts on "..name..": "..fartcount , "SAY", nil,  DEFAULT_CHAT_FRAME.editBox.languageID); 
				else
					 --  report to self only
					print(color .. "Farted on "..name..". Total farts on "..name..": "..fartcount);
				end
			end
		end
	end	
end)

-- fartee events - count who farted on you
function FP.CHAT_MSG_TEXT_EMOTE(self, event, ...)	
	local emote, name, _ = ...; -- get the args from the event
	-- check chat for fart emote string
	if strfind(emote, "brushes up against you and farts loudly.") then
		-- check if fart spam
		if waiting.fartedOnMe[name] == nil then
			-- count fart
			DB.fartedOnMe[name] = (DB.fartedOnMe[name] or 0) + 1;
			-- get updated fart count
			local fartcount = DB.fartedOnMe[name];
			-- turn on fart spam protection
			waiting.fartedOnMe[name] = true;
			C_Timer.After(10, function() waiting.fartedOnMe[name] = nil; end) -- prevent /fart spam from counting
			-- play a fart sound
			playFartSound();
			if isValidFartZone() then
				-- chat
				SendChatMessage("Fart detected by "..name..". Total farts counted by "..name..": "..fartcount , "SAY", nil,  DEFAULT_CHAT_FRAME.editBox.languageID); 
			else
				-- report to self only
				print(color .. "Fart detected by "..name..". Total farts counted by "..name..": "..fartcount);
			end
		end
	end
end

-- /fartpatrol commands
SLASH_FP1 = "/fartpatrol";
function SlashCmdList.FP(msg)
	local cmd, arg = msg:match("^(%S*)%s*(.-)$");
	cmd = string.lower(cmd); -- case insensitive
	
	-- display stats: /fartpatrol stats
	if cmd == "stats" then
		print(color.."FartPatrol /fart Stats:");
		print(color.." - My farts: use /fartpatrol farter");
		print(color.." - Farts on me: use /fartpatrol fartee");
		
	-- display farter stats: /fartpatrol farter
	elseif cmd == "farter" then
		print(color.."FartPatrol - Who I farted on:");
		if next(DB.iFartedOn) == nil then
			print(color .. "  No farts recorded.");
		end	
		for k,v in pairs(DB.iFartedOn) do
			print(color .. "  " .. k .. ": " .. v);
		end
		
	-- display fartee stats: /fartpatrol fartee stats
	elseif cmd == "fartee" then
		print(color.."FartPatrol - Who farted on me:");
		if next(DB.fartedOnMe) == nil then
			print(color .. "  No farts recorded.");
		end	
		for k,v in pairs(DB.fartedOnMe) do
			print(color .. "  " .. k .. ": " .. v);
		end
		
	-- clear fart stats: /fartpatrol clear
	elseif cmd == "clear" then
		print(color .. "FartPatrol: clearing fart stats");
		DB = { iFartedOn = {}, fartedOnMe = {} };
		FARTPATROL_DB = DB;
		
	-- toggle fart chat off for current zone
	elseif cmd == "zoneoff" then
		addNoFartZone();
		print(color .. "FartPatrol - /say is now toggled off for this zone. Farts will still be counted, but there will be no report to /say chat.");
		
	-- toggle fart chat on for current zone
	elseif cmd == "zoneon" then
		delNoFartZone()
		print(color .. "FartPatrol - /say is now toggled on for this zone.");
		
	-- toggle all fart chat off
	elseif cmd == "chatoff" then
		NF_DB.noFartZone["ALL"] = true;
		print(color .. "FartPatrol - /say is now toggled off. Farts will still be counted, but there will be no report to /say chat.");
		
	-- toggle all fart chat
	elseif cmd == "chaton" then
		NF_DB.noFartZone["ALL"] = nil;
		print(color .. "FartPatrol - /say is now toggled on.");		
	
	-- print instructions: /fartpatrol
	else 	
		print(color .. "FartPatrol tracks farts! /fart must be used on a player TARGET to count");
		print(color .. "Commands: /fartpatrol " ..highlight.. "command");
		print(highlight .. "  farter" .. color .. ": displays my /fart stats");
		print(highlight .. "  fartee".. color ..": displays who farted on me stats");
		print(highlight .. "  clear".. color ..": deletes ALL FartPatrol stats");
		print(color .. "    * clears both farter and fartee stats");
		print(highlight .. "  zoneoff".. color ..": toggles /say chat OFF for the current zone (farts will be counted but /say chat is disabled)");
		print(highlight .. "  zoneon".. color ..": toggles /say chat ON for the current zone");
		print(highlight .. "  chatoff".. color ..": toggles /say chat OFF for (farts will be counted but /say chat is disabled)");
		print(highlight .. "  chaton".. color ..": toggles /say chat ON");
		
	end
end





