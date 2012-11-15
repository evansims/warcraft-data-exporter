
--- GLOBALS
local GetItemInfo = _G.GetItemInfo

--- Configuration
local devMode = true;
local rerunCommand = false;
local rerunIDs = 0;
local scanResultCount = 0;

--- Frames
local frame, events = CreateFrame("Frame"), {};

--- Scanning Tooltip
local WITT = CreateFrame("GameTooltip");
WITT:SetOwner(UIParent, "ANCHOR_NONE");
WITT.left = {}
WITT.right = {}

for i = 1, 30 do
     WITT.left[i] = WITT:CreateFontString()
     WITT.left[i]:SetFontObject(GameFontNormal)
     WITT.right[i] = WITT:CreateFontString()
     WITT.right[i]:SetFontObject(GameFontNormal)
     WITT:AddFontStrings(WITT.left[i], WITT.right[i])
end

--- Cache
local npcCache = {};
local flagCacheNPC = 0;

local factionCache = {};

local itemCache = {};
local itemCacheBookmark = 0;
local itemMissingCache = {};

local spellCache = {};
local spellCacheBookmark = 0;

--SetMapToCurrentZone();

--- EVENTS

--function events:WORLD_MAP_UPDATE(...)
--	local posX, posY = GetPlayerMapPosition("player");
--	print(posX .. "," .. posY)
--end

function events:ADDON_LOADED(addon)
	if(addon == "wowinstant") then
		local addonVersion =  GetAddOnMetadata("wowinstant", "Version");
		print("WoW Instant Collector v" .. addonVersion .. " loaded.");

		local counterKey = 0;
		local counterValue = 0;

		if(_G["WI_npcCache"] ~= nil) then
			npcCache = _G["WI_npcCache"];
			flagCacheNPC = _G["WI_flagCacheNPC"];

			if(npcCache) then
				local npcCacheCount = 0
				for counterKey, counterValue in pairs(npcCache) do
					npcCacheCount = npcCacheCount + 1
				end
				if(npcCacheCount > 0) then
					print("- Loaded " .. npcCacheCount .. " cached NPCs.");
				end
			end
		else
			npcCache = {};
			flagCacheNPC = 0;
		end

		if(_G["WI_factionCache"] ~= nil) then
			factionCache = _G["WI_factionCache"];

			if(factionCache) then
				local factionCacheCount = 0
				for counterKey, counterValue in pairs(factionCache) do
					factionCacheCount = factionCacheCount + 1
				end
				if(factionCacheCount > 0) then
					print("- Loaded " .. factionCacheCount .. " cached factions.");
				end
			end
		else
			factionCache = {};
		end

		if(_G["WI_itemCache"] ~= nil) then
			itemCache = _G["WI_itemCache"];
			--itemCacheBookmark = _G["WI_itemCacheBookmark"];
			itemCacheBookmark = 0;

			if(itemCache) then
				local itemCacheCount = 0
				for counterKey, counterValue in pairs(itemCache) do
					itemCacheCount = itemCacheCount + 1
					if(tonumber(counterKey) > itemCacheBookmark) then
						itemCacheBookmark = counterKey;
					end
				end
				if(itemCacheCount > 0) then
					print("- Loaded " .. itemCacheCount .. " cached items.");
				end
			end
		else
			itemCache = {};
			itemMissingCache = {};
			itemCacheBookmark = 0;
		end

		if(_G["WI_spellCache"] ~= nil) then
			spellCache = _G["WI_spellCache"];
			--spellCacheBookmark = _G["WI_spellCacheBookmark"];
			spellCacheBookmark = 0;

			if(spellCache) then
				local spellCacheCount = 0
				for counterKey, counterValue in pairs(spellCache) do
					spellCacheCount = spellCacheCount + 1
					if(counterKey > spellCacheBookmark) then
						spellCacheBookmark = counterKey;
					end
				end
				if(spellCacheCount > 0) then
					print("- Loaded " .. spellCacheCount .. " cached spells.");
				end
			end
		else
			spellCache = {};
			spellCacheBookmark = 0;
		end
	end
end

function events:PLAYER_LOGOUT(...)

	-- Player logging out; push our local cache out to save for next time.

	_G["WI_npcCache"] = npcCache;
	_G["WI_flagCacheNPC"] = flagCacheNPC;

	_G["WI_factionCache"] = factionCache;

	_G["WI_itemCache"] = itemCache;
	_G["WI_itemCacheBookmark"] = 0;

	_G["WI_spellCache"] = spellCache;
	_G["WI_spellCacheBookmark"] = 0;

end

function events:UPDATE_MOUSEOVER_UNIT(...) -- Cursor moves over a visible unit.
	if(flagCacheNPC == 0) then return end

	if(UnitExists("mouseover")) then -- one can never be too paranoid.
		local npcGUID = tonumber((UnitGUID("mouseover")):sub(-12, -9), 16); -- get GUID
		local npcName, _ = UnitName("mouseover");
		if(npcGUID > 0 and npcName ~= "Unknown") then -- valid GUIDs are only returned for NPCs
			if(npcCache[npcGUID] == nil) then
				local npcLevel = UnitLevel("mouseover");
				local npcSex = UnitSex("mouseover");
				if(npcSex == 3) then npcSex = "Female" elseif(npcSex == 2) then npcSex = "Male" else npcSex = "" end
				--local npcRace = UnitRace("mouseover"); -- NPCs do not have a race.
				local npcTier = UnitClassification("mouseover");
				local _, npcClass = UnitClass("mouseover");

				local npcHealth = UnitHealthMax("mouseover");
				local ncpType = UnitCreatureType("mouseover");
				local _, npcFaction = UnitFactionGroup("mouseover")
				if(npcFaction == nil) then npcFaction = "" end

				local npcPower = UnitPowerMax("mouseover");
				local _, npcPowerType = UnitPowerType("mouseover");

				local npcPlayerControlled = UnitPlayerControlled("mouseover")
				if(npcPlayerControlled ~= nil) then npcPlayerControlled = 1 else npcPlayerControlled = 0 end

				print(npcName .. " ----");
				print("Level " .. npcLevel .. " " .. npcSex .. " " .. ncpType);
				print("Class: " .. npcClass);
				print("Classification: " .. npcTier);
				print("GUID: " .. npcGUID);
				print("Faction: " .. npcFaction);
				print("Player controlled: " .. npcPlayerControlled);

				npcPositions = {};
				if(npcPlayerControlled == 0 and CheckInteractDistance("mouseover", 3)) then
					local npcX, npcY = GetPlayerMapPosition("player");
					npcX = string.format("%.2f", npcX * 100);
					npcY =  string.format("%.2f", npcY * 100);
					print("X: " .. npcX .. ", Y: " ..  npcY);
					tinsert(npcPositions, {npcX, npcY});
				end

				print("HP: " .. npcHealth);
				print("MP: " .. npcPower .. " (" .. npcPowerType .. ")");

				print("----");

				local npcInfo = {
						npcGUID,
						npcName,
						npcSex,
						--npcRace,
						npcLevel,
						npcType,
						npcClass,
						npcTier,
						npcFaction,
						npcPositions,
						npcHealth,
						npcPower,
						npcPowerType,
						npcPlayerControlled
					  }

				tinsert(npcCache, npcGUID, npcInfo);
				--table.insert(npcCache, npcGUID, npcInfo)
				--npcCacheSize = npcCacheSize + 1;

				--print("There are now " .. npcCacheSize .. " NPCs cached.");

				--for k,v in pairs(npcCache) do
				--	print(k,v)
				--end
			else
				if(devMode) then print("This NPC has already been cached.") end;
			end
		end
	end
end

--- EVENT SUPPORT

frame:SetScript("OnEvent", function(self, event, ...) events[event](self, ...); end);

for k, v in pairs(events) do
	frame:RegisterEvent(k);
end

--[[frame:SetScript("OnUpdate", function()
	checkQueue(this, 0.1);
end)

function checkQueue(self, elapsed)
	--print("checkQueue");
end]]--





















--[[local f = CreateFrame("Frame",nil,UIParent)
f:SetFrameStrata("BACKGROUND")
f:SetWidth(128) -- Set these to whatever height/width is needed
f:SetHeight(64) -- for your Texture

local t = f:CreateTexture(nil,"BACKGROUND")
t:SetTexture(0,0,0,1) -- "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Factions.blp"
t:SetAllPoints(f)
f.texture = t

f:SetPoint("CENTER",0,0)
f:Show()--]]














--[[local WITT = GameTooltip;

local function WIHook_Tooltip_OnShow(self, ...)
	print("WIHook_Tooltip_OnShow");

	for i = 1, WITT:NumLines() do
		local line = _G["GameTooltipTextLeft"..i];
		print(line:GetText());
	end
end

local function WIHook_Tooltip_OnUpate(self, elapsed)
	print("WIHook_Tooltip_OnUpate");
end

WITT:HookScript("OnShow", WIHook_Tooltip_OnShow);
--WITT:HookScript("OnUpdate", WIHook_Tooltip_OnUpate);--]]

local function getItem(id)

	if(itemMissingCache[id] ~= nil) then
		return
	end

	if(itemCache[id] == nil) then

		local sIcon = GetItemIcon(id)
		if(sIcon ~= nil) then

			local itemData = {}
			itemData['id'] = id;
			itemData['icon'] = sIcon;
			itemData['tooltip'] = {};
			itemData['tooltip_ext'] = {};

			WITT:ClearLines();
			WITT:SetHyperlink("item:" .. id .. ":0:0:0:0:0:0:0");

			local lines = WITT:NumLines();
			if lines > 0 then
				if WITT.left[lines]:GetText() == "Retrieving item information" then
					--print("ID " .. id .. "    Icon: " .. sIcon);
					rerunCommand = true;
					rerunIDs = rerunIDs + 1;
					return;
				end

				for i = 1, lines do
					local line = WITT.left[i]:GetText();
					if(line) then
						itemData['tooltip'][i] = line;
					end
				end

				for i = 1, lines do
					local line = WITT.right[i]:GetText();
					if(line) then
						itemData['tooltip_ext'][i] = line;
					end
				end
			else
				print("Error on " .. id .. "; tooltip length of 0.");
				return;
			end
			WITT:ClearLines();

			itemData['name'], itemData['link'], itemData['rarity'], itemData['itemlevel'], itemData['level'], itemData['type'], itemData['subtype'], itemData['stack'], itemData['slot'], _, itemData['vendored'] = GetItemInfo(id)

			if (itemData['link'] == nil) then
				print("Error on " .. id .. "; no link returned.");
				return;
			else
				if(itemData['slot'] and _G[itemData['slot']]) then
					itemData['slot'] = _G[itemData['slot']]
				end

				local iUniqueFamily, iUniqueEquipped = GetItemUniqueness(id);
				if(iUniqueEquipped) then
					itemData['unique_family'] = iUniqueFamily;
					itemData['unique_max'] = iUniqueEquipped;
				end

				itemData['stats'] = {};
				local stats = GetItemStats(itemData['link'])
				if(stats) then
					for stat, value in pairs(stats) do
						if(_G[stat]) then
							itemData['stats'][_G[stat]] = value
						else
							itemData['stats'][stat] = value
						end
					end
				end

				itemData['onuse'], _ = GetItemSpell(id)

				itemCache[id] = itemData
				print("Item " .. itemCache[id]['link'] .. " (" .. id .. ") was cached.")
				scanResultCount = scanResultCount + 1;
				return
			end
		else
			itemMissingCache[id] = 1;
		end

	end

end

local function getSpell(id)

	if(spellCache[id] == nil) then

		local spellData = {}
		spellData['id'] = id;
		spellData['name'], _, spellData['icon'], spellData['cost'], spellData['funneled'], spellData['powertype'], spellData['casttime'], spellData['minrange'], spellData['maxrange'] = GetSpellInfo(id)

		if(spellData['icon'] ~= nil) then

			spellData['tooltip'] = {};

			WITT:ClearLines();
			WITT:SetHyperlink("spell:" .. id);

			local lines = WITT:NumLines();
			if lines > 0 then
				if WITT.left[lines]:GetText() == "Retrieving item information" then
					rerunCommand = true;
					rerunIDs = rerunIDs + 1
					return;
				end

				for i = 1, lines do
					local line = WITT.left[i]:GetText();
					if(line) then
						spellData['tooltip'][i] = line;
					end
				end
			end
			WITT:ClearLines();

			if(spellData) then
				print("Spell |Hspell:" .. id .."|h|r|cff71d5ff[" .. spellData['name'] .. "]|r|h (" .. id .. ") was cached");
				spellCache[id] = spellData;
				scanResultCount = scanResultCount + 1;
			else
				rerunCommand = true;
				rerunIDs = rerunIDs + 1
				return;
			end
			return
		end

	end

end

local function getFaction(id)

	if(factionCache[id] == nil) then
		local factionData = {};
		factionData['id'] = id;
		factionData['name'], factionData['description'], _ = GetFactionInfoByID(id)

		if(factionData['name'] ~= nil) then
			print("Faction " .. factionData['name'] .. " (" .. id .. ") was cached.");
			factionCache[id] = factionData;
		end
	end

end

SLASH_WOWINSTANT1, SLASH_WOWINSTANT2 = "/wowinstant", "/wi"
SlashCmdList["WOWINSTANT"] = function(msg, editBox)
	local command, target = msg:match("^(%S*)%s*(.-)$")

	if(command == "item" or command == "items" or command == "spell" or command == "spells" or command == "faction" or command == "factions") then

		local rangeFrom, rangeTo = target:match("([a-z0-9]+)[ ]?(.*)")

		if(rangeFrom ~= "next") then
			if(not rangeFrom) or (not tonumber(rangeFrom)) then
				print("You must provide an ID to query.")
				return
			end
		end

		if(rangeTo ~= "all") then
			if(not rangeTo) or (not tonumber(rangeTo)) then
				rangeTo = 0
			elseif(tonumber(rangeFrom) > tonumber(rangeTo)) then
				print("Your end range ID cannot be greater than you start ID. (" .. rangeTo .. " > " .. rangeFrom .. ")")
				return
			end
		end

		if(command == "item" or command == "items") then

			rerunIDs = 0;

			if(rangeFrom == "next") then
				rangeFrom = itemCacheBookmark;
				rangeTo = itemCacheBookmark + 1500;
			end

			if(tonumber(rangeTo) >= 1) then

				old_itemCacheBookmark = itemCacheBookmark;

				itemCache = {};
				itemCacheBookmark = 0;

				print("Querying items " .. rangeFrom .. "-" .. rangeTo)
				for i = rangeFrom, rangeTo do
					getItem(i)
					itemCacheBookmark = i
					if scanResultCount == 1000 then
						break
					end
				end

				if rerunCommand == true then
					print(rerunIDs .. " queries are pending a response from the server. Please resend this request in a few moments.");
					itemCacheBookmark = old_itemCacheBookmark;
					rerunCommand = false;
				end

				if scanResultCount == 1000 then
					print("Reached memory limit. Aborted scan at 1000 results.");
				end

				print("Done! Cached " .. scanResultCount .. " items.");
				--ReloadUI();
			else
				print("Querying item " .. rangeFrom)
				getItem(rangeFrom)
			end

			scanResultCount = 0;
			return

		elseif(command == "spell" or command == "spells") then

			rerunIDs = 0;

			if(rangeFrom == "next") then
				rangeFrom = spellCacheBookmark;
				rangeTo = spellCacheBookmark + 5000;
			end

			if(tonumber(rangeTo) >= 1) then

				old_spellCacheBookmark = spellCacheBookmark;

				spellCache = {};
				spellCacheBookmark = 0;

				print("Querying spells " .. rangeFrom .. "-" .. rangeTo)

				for i = rangeFrom, rangeTo do
					getSpell(i)
					spellCacheBookmark = i
					if scanResultCount == 4000 then
						break
					end
				end

				if rerunCommand == true then
					print(rerunIDs .. " queries are pending a response from the server. Please resend this request in a few moments.");
					spellCacheBookmark = old_spellCacheBookmark;
					rerunCommand = false;
				end

				if scanResultCount == 4000 then
					print("Reached memory limit. Aborted scan at 4000 results.");
				end

				print("Done! Cached " .. scanResultCount .. " spells.");
				ReloadUI();
			else
				print("Querying spell " .. rangeFrom)
				getSpell(rangeFrom)
			end

			scanResultCount = 0;
			return

		elseif(command == "faction" or command == "factions") then
			if(tonumber(rangeTo) >= 1) then
				print("Querying factions " .. rangeFrom .. "-" .. rangeTo)
				for i = rangeFrom, rangeTo do
					getFaction(i)
				end
				return
			else
				print("Querying faction " .. rangeFrom)
				getFaction(rangeFrom)
				return
			end
		end

	elseif(command == "npc" and target) then

		if(target == "off") then
			flagCacheNPC = 0;
			print("NPC caching disabled.");
			return
		elseif(target == "on") then
			flagCacheNPC = 1;
			print("NPC caching enabled.")
			return
		end

	elseif(command == "clear" and target) then

		if(target == "item" or target == "items") then
			print("Cleared item cache.");
			itemCache = {};
			itemCacheBookmark = 0;
			collectgarbage("collect");
			--ReloadUI();
			return
		elseif(target == "spell" or target == "spells") then
			print("Cleared spell cache.");
			spellCache = {};
			spellCacheBookmark = 0;
			collectgarbage("collect");
			--ReloadUI();
			return
		elseif(target == "faction" or target == "factions") then
			print("Cleared faction cache.");
			factionCache = {};
			collectgarbage("collect");
			--ReloadUI();
			return
		elseif(target == "npc" or target == "npcs") then
			print("Cleared NPC cache.");
			npcCache = {};
			collectgarbage("collect");
			--ReloadUI();
			return
		elseif(target == "all") then
			print("Cleared all caches.");
			itemCache = {};
			spellCache = {};
			factionCache = {};
			npcCache = {};
			itemCacheBookmark = 0;
			spellCacheBookmark = 0;
			collectgarbage("collect");
			return;
		else
			print("Syntax: clear [all|items|spells|factions|npcs]");
			return
		end

	elseif(command == "bookmark") then

		print("Last item scan finished at " .. itemCacheBookmark);
		print("Last spell scan finished at " .. spellCacheBookmark);
		return

	end

	print("Supported commands: item, spell, faction, clear, bookmark")
	print("Syntax: command start [end]")

end
