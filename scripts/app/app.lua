--map.lua

createLibMap = function()
	local map = {}

	local m_numLevels = 1
	local m_lastLevelEntered = 1
	local m_newLevelCompleted = false
	local m_firstLockedLevelByGate = 0
	local m_didOpenGate = false
	local m_sceneNames={}

	local initMembers = function()
		 m_lastLevelEntered = 1
		 m_newLevelCompleted = false
		 m_firstLockedLevelByGate = 0
		 m_didOpenGate = false
	end

	--private
	--------------------------------------------------
	local getConfigData = function(tbl,row,column)
		idx = ConfigTables.Index:new(tbl,row,column)
		r,val = config:get(idx,v)
		if(not r) then
			return nil
		else
			return val
		end
	end

	local initConfigurationMapLevelsInfo = function()
		-- also puts in a hash tabke the sceneName
		m_lastLevelEntered = map.getCurrentLevel()
		local levelWithNum = "level"..m_numLevels
		print("initConfigurationMapLevelsInfo m_newLevelCompleted: "..tostring(m_newLevelCompleted))

		local sceneName = getConfigData("mapLevelsInfo",levelWithNum,"sceneName")

		while (sceneName ~= nil) do
			print("levelWithNum "..levelWithNum)
			print("sceneName "..sceneName)
			if (m_sceneNames[sceneName] == 1) then
				print("Error: sceneName exists more than once")
			else
				m_sceneNames[sceneName] = 1
				print("sets to 1 - m_sceneNames[sceneName] "..m_sceneNames[sceneName])
			end
			
			local levelLayerZoomInPositionX = getConfigData("mapLevelsInfo",levelWithNum,"layerZoomInPositionX")
			if (levelLayerZoomInPositionX == nil) then
				print("map.validate - level "..levelWithNum.." doesn't have layerZoomInPositionX")
			end
			local levelLayerZoomInPositionY = getConfigData("mapLevelsInfo",levelWithNum,"layerZoomInPositionY")
			if (levelLayerZoomInPositionY == nil) then
				print("map.validate - level "..levelWithNum.." doesn't have layerZoomInPositionY")
			end
			
			m_numLevels = m_numLevels + 1
			print("m_numLevels: "..m_numLevels)
			levelWithNum = "level"..m_numLevels
			print("levelWithNum: "..levelWithNum)
			sceneName = getConfigData("mapLevelsInfo",levelWithNum,"sceneName")
		end
		m_numLevels = m_numLevels -1
		print("m_numLevels "..m_numLevels)
	end

	local initEvents = function()
		print("entered initEvents")
		local eventRow,eventName = config:getFirstRow("mapEvents",v)
		while (eventRow == true) do
			local scoresEventName = "event_"..eventName
			print("initEvents scoresEventName:"..scoresEventName)
			scores:getScore(scoresEventName):setValue(0)
			eventRow, eventName = config:getNextRow("mapEvents", eventName, v)
		end
	end

	local validateConfigurationMapScenesInfo = function()
		print("entered validateConfigurationMapScenesInfo")
		local sceneRow,scene = config:getFirstRow("mapScenesInfo",v)
		local numScenes = 0
		while (sceneRow == true) do
			numScenes = numScenes + 1
			local imageIndexLocked = getConfigData("mapScenesInfo",scene,"imageIndexLocked")
			if (imageIndexLocked == nil) then
				print("map.validate - scene "..scene.." doesn't have imageIndexLocked")
			end
			local imageIndexOpened = getConfigData("mapScenesInfo",scene,"imageIndexOpened")
			if (imageIndexOpened == nil) then
				print("map.validate - scene "..scene.." doesn't have imageIndexOpened")
			end
			local previewBubbleImageIndex = getConfigData("mapScenesInfo",scene,"previewBubbleImageIndex")
			if (previewBubbleImageIndex == nil) then
				print("map.validate - scene "..scene.." doesn't have previewBubbleImageIndex")
			end
			sceneRow, scene = config:getNextRow("mapScenesInfo", scene, v)
		end
		--makes sure that the number of levels equal the number of scenes.
		if(numScenes ~= m_numLevels) then
			print("the number of levels isn't equal to the number of scenes.")
		end
	end

	local validateScores = function()
		print("entered  validateScores")
		if (not scores:exists("currentLevel")) then
			print("map.validate - currentLevel doesn't exist in the scoring board")
		end
		for i=1,m_numLevels do
			if (not scores:exists("level"..i.."_stars")) then
				print("map.validate - level "..i.." stars doesn't exist in the scoring board")
			end
		end
	end

	local refreshFirstLockedLevelByGate = function()
		m_firstLockedLevelByGate = m_numLevels + 1
		print("refreshFirstLockedLevelByGate")
		print("refreshFirstLockedLevelByGate m_numLevels:("..m_numLevels..")")
		local gateRow,gateName = config:getFirstRow("mapGates",v)
		while (gateRow == true) do
			local gateLevel = tonumber(getConfigData("mapGates", gateName, "level"))
			print("refreshFirstLockedLevelByGate gateLevel("..gateLevel..")")
			print("refreshFirstLockedLevelByGate gateName("..gateName..")")
			print("refreshFirstLockedLevelByGate m_firstLockedLevelByGate("..m_firstLockedLevelByGate..")")
			if ((not map.isGateOpen(gateName)) and (gateLevel < m_firstLockedLevelByGate)) then
				m_firstLockedLevelByGate = gateLevel
				print("refreshFirstLockedLevelByGate ("..m_firstLockedLevelByGate..")")
				print("gateName: "..gateName)
			end
			gateRow, gateName = config:getNextRow("mapGates", gateName, v)
		end
		print("refreshFirstLockedLevelByGate: after loop ("..m_firstLockedLevelByGate..")")
	end

	local setCurrentLevel = function(level)
		print("entered setCurrentLevel")
		print("Setting current level to "..level)
		scores:getScore("currentLevel"):setValue(level)
	end

	--------------------------------------------------
	--public
	--------------------------------------------------
	map.init = function()
		initMembers()
		initConfigurationMapLevelsInfo()
		validateConfigurationMapScenesInfo()
		validateScores()
		initEvents()
		refreshFirstLockedLevelByGate()
	end

	map.reset = function()
		print("entered map.reset")
		setCurrentLevel(1)
		for m = 1, m_numLevels do
			local levelStarsInit = "level"..m.."_stars"
			scores:getScore(levelStarsInit):setValue(0)
		end

		local eventRow,eventName = config:getFirstRow("mapEvents",v)
		while (eventRow == true) do
			local scoresEventName = "event_"..eventName
			scores:getScore(scoresEventName):setValue(0)
			eventRow, eventName = config:getNextRow("mapEvents", eventName, v)
		end

		local gateRow,gateName = config:getFirstRow("mapGates",v)
		while (gateRow == true) do
			local scoresGateName = "gate_"..gateName
			scores:getScore(scoresGateName):setValue(0)
			gateRow, gateName = config:getNextRow("mapGates", gateName, v)
		end
		map.init()
	end

	map.getCurrentLevel = function()
		print("map.getCurrentLevel ==>"..scores:getScore("currentLevel"):getValue())
		return scores:getScore("currentLevel"):getValue()
	end

	map.isLevelLocked = function(level)
		print("map.isLevelLocked level("..level..")")
		print("map.isLevelLocked m_firstLockedLevelByGate("..m_firstLockedLevelByGate..")")
		print("map.isLevelLocked ==>"..tostring(level > map.getCurrentLevel() or level >= m_firstLockedLevelByGate))
		return ((level > map.getCurrentLevel()) or (level >= m_firstLockedLevelByGate))
	end

	map.getLevelSceneName = function(level)
		print("map.getLevelSceneName")
		local levelName = "level"..level
		return (getConfigData("mapLevelsInfo",levelName,"sceneName"))
	end

	map.getLevelImageIndex = function(level)
		local imageIndexState
		print("entered map.getLevelImageIndex")
		if ( map.isLevelLocked(level) ) then
			print("map.getLevelImageIndex level locked "..level)
			imageIndexState = "imageIndexLocked"
			print("map.getLevelImageIndex imageIndexState "..imageIndexState)
		else
			print("map.getLevelImageIndex level open "..level)
			imageIndexState = "imageIndexOpened"
			print("map.getLevelImageIndex imageIndexState "..imageIndexState)
		end
		local levelSceneName = map.getLevelSceneName(level)
		return (getConfigData("mapScenesInfo", levelSceneName, imageIndexState))
	end

	map.getPreviewBubbleImageIndex = function(level)
		print("entered map.getPreviewBubbleImageIndex")
		return (getConfigData("mapScenesInfo",map.getLevelSceneName(level), "previewBubbleImageIndex"))
	end

	map.getLevelStars = function(level)
		local levelStars = "level"..level.."_stars"
		return (scores:getScore(levelStars):getValue())
	end

	map.setLevelStars = function(level,starsCount)
		print("entered map.setLevelStars")
		local levelStars = "level"..level.."_stars"
		local starsBefore = map.getLevelStars(level)
		if (starsCount > starsBefore) then
			print("map.setLevelStars is updating level:"..level.." to: "..starsCount.." stars")
			scores:getScore(levelStars):setValue(starsCount)
		end
	end

	map.getTotalStars = function()
		print("map.getTotalStars START")
		local counter = 0
		for i=1,m_numLevels do
			print("map.getTotalStars lvl="..i.." stars="..map.getLevelStars(i))
			counter = counter + map.getLevelStars(i)
		end
		print("map.getTotalStars ==> "..counter)
		return (counter)
	end

	map.levelEntered = function(level)
		print("entered map.levelEntered is level:"..level)
		m_lastLevelEntered = level
		m_newLevelCompleted = false
		m_didOpenGate = false
		refreshFirstLockedLevelByGate()
	end

	map.getLastLevelEntered = function()
		print("entered map.getLastLevelEntered m_lastLevelEntered("..m_lastLevelEntered..")")
		return m_lastLevelEntered
	end

	map.levelCompleted = function(starsCount)
		print("entered map.levelCompleted starsCount("..starsCount..")")
		if (m_lastLevelEntered == map.getCurrentLevel() and starsCount > 0) then
			print("map.levelCompleted first if. m_lastLevelEntered: "..m_lastLevelEntered)
			m_newLevelCompleted = true
			setCurrentLevel(m_lastLevelEntered+1)
		else
			print("map.levelCompleted first else")
			m_newLevelCompleted = false
		end
		if (starsCount > map.getLevelStars(m_lastLevelEntered) ) then
			print("map.levelCompleted 2nd if. starsCount"..starsCount)
			map.setLevelStars(m_lastLevelEntered,starsCount)
		end
	end

	map.getStarsForMapEvents = function(eventName)
		print("entered map.getStarsForMapEvents")
		return (tonumber(getConfigData("mapEvents", eventName, "stars")))
	end

	map.getLevelForMapEvents = function(eventName)
		print("entered map.getLevelForMapEvents")
		return (tonumber(getConfigData("mapEvents", eventName, "level")))
	end

	map.getNextMapEvent = function()
		print("!!!entered map.getNextMapEvent")
		local totalStars = tonumber(map.getTotalStars())
		local currentLevel = tonumber(map.getCurrentLevel())
		print("map.getNextMapEvent totalStars("..totalStars..")")
		local eventRow,eventName = config:getFirstRow("mapEvents",v)

		while (eventRow == true) do
			local isStarsQualifies = false
			local isLevelsQualifies = false
			local scoresEventName = "event_"..eventName
			local scoresEventNameValue = scores:getScore(scoresEventName):getValue()
			local starsRequired = map.getStarsForMapEvents(eventName)
			local levelRequired = map.getLevelForMapEvents(eventName)
			print("map.getNextMapEvent scoresEventName: "..scoresEventName)
			if (starsRequired ~= nil) then
				print("starsRequired: "..starsRequired)
			end
			if (levelRequired ~= nil) then
				print("levelRequired: "..levelRequired..", currentLevel: "..currentLevel)
			end
			if (scoresEventNameValue ~= 1) then
				if (levelRequired == nil) then
					isLevelsQualifies = true
				elseif (currentLevel >= levelRequired) then
					isLevelsQualifies = true
				end

				if(starsRequired == nil) then
					isStarsQualifies = true
				elseif (totalStars >= starsRequired) then
					isStarsQualifies = true
				end
				
				if (isLevelsQualifies and isStarsQualifies) then
					scores:getScore(scoresEventName):setValue(1)
					gateName = getConfigData("mapEvents", eventName, "gate")
					print("(gateName ~= nil) ==> "..(tostring(gateName ~= nil)))
					if(gateName ~= nil) then
						print ("EventOccur opens gate ("..gateName..")")
						map.openGate(gateName)
					end
					
					return (eventName)
				end
			end
			eventRow, eventName = config:getNextRow("mapEvents", eventName, v)
		end
		print("map.getNextMapEvent ret nil")
		return nil
	end

	map.shouldAdvanceAvatar = function()
		print("map.shouldAdvanceAvatar m_newLevelCompleted: "..tostring(m_newLevelCompleted))
		if (m_didOpenGate) then
			print ("return true")
			return true
		end
		local condition2 = (map.getCurrentLevel() < m_firstLockedLevelByGate)
		print("map.shouldAdvanceAvatar condition2: "..tostring(condition2))
		local ret = (m_newLevelCompleted and map.getCurrentLevel() < m_firstLockedLevelByGate)
		print ("map.shouldAdvanceAvatar ==> "..tostring(ret))
		return (m_newLevelCompleted and map.getCurrentLevel() < m_firstLockedLevelByGate)
	end

	map.getAvatarLevel = function()
		print("map.getAvatarLevel")
		if (map.getCurrentLevel() == 1) then
			print("map.getAvatarLevel ==> 1")
			return 1
		end
		if (map.shouldAdvanceAvatar())then
			print("map.getAvatarLevel map.shouldAdvanceAvatar() true==>"..(map.getCurrentLevel()-1))
			return (map.getCurrentLevel()-1)
		end
		if (map.getCurrentLevel() >= m_firstLockedLevelByGate)then
			print("map.getAvatarLevel map.getCurrentLevel("..map.getCurrentLevel()..")")
			print("map.getAvatarLevel m_firstLockedLevelByGate..("..m_firstLockedLevelByGate..")")
			print("map.getAvatarLevel (map.getCurrentLevel() >= m_firstLockedLevelByGate) true==>"..(map.getCurrentLevel()-1))
			return (map.getCurrentLevel()-1)
		end
		print("map.getAvatarLevel else==>"..(map.getCurrentLevel()))
		return (map.getCurrentLevel())
	end

	map.getAvatarInitialPositionX = function()
		local level = map.getAvatarLevel()
		print("map.getAvatarInitialPositionX("..level..")")
		print("map.getAvatarInitialPositionX ==>"..(tonumber(getConfigData("mapLevelsInfo", "level"..level, "avatarPositionX"))))
		return (tonumber(getConfigData("mapLevelsInfo", "level"..level, "avatarPositionX")))
	end

	map.getAvatarInitialPositionY = function()
		local level = map.getAvatarLevel()
		print("map.getAvatarInitialPositionX("..level..")")
		print("map.getAvatarInitialPositionX ==>"..(tonumber(getConfigData("mapLevelsInfo", "level"..level, "avatarPositionX"))))
		return (tonumber(getConfigData("mapLevelsInfo", "level"..level, "avatarPositionY")))
	end

	map.getAvatarFinalPositionX = function()
		print("entered map.getAvatarFinalPositionX")
		local level = map.getCurrentLevel()
		return (tonumber(getConfigData("mapLevelsInfo", "level"..level, "avatarPositionX")))
	end

	map.getAvatarFinalPositionY = function()
		print("entered map.getAvatarFinalPositionY")
		local level = map.getCurrentLevel()
		return (tonumber(getConfigData("mapLevelsInfo", "level"..level, "avatarPositionY")))
	end

	map.getLayerZoomInPositionX = function()
		print("entered map.getLayerZoomInPositionX")
		local level = map.getLastLevelEntered()
		return (tonumber(getConfigData("mapLevelsInfo", "level"..level, "layerZoomInPositionX")))
	end

	map.getLayerZoomInPositionY = function()
		local level = map.getLastLevelEntered()
		return (tonumber(getConfigData("mapLevelsInfo", "level"..level, "layerZoomInPositionY")))
	end

	map.getLevelStarTime = function()
		local level = map.getLastLevelEntered()
		return (tonumber(getConfigData("mapLevelsInfo", "level"..level, "timeStars")))
	end

	map.didEventOccur = function(eventName)
		print ("map.didEventOccur("..eventName..")")
		local scoresEventName = "event_"..eventName
		local didEventOccur = scores:getScore(scoresEventName):getValue()
		print("map.didEventOccur==>"..(tostring(didEventOccur == 1)))
		return (didEventOccur == 1)
	end

	--returns 0,1,2,3 according to the number of stars if the level is open, and 4 if the level is locked
	map.getStarsImageIndex = function(eventNum)
		if (map.isLevelLocked(eventNum)) then
			print("map.getStarsImageIndex locked")
			return 4
		end
		local scoresLevelWithStars = "level"..eventNum.."_stars"
		local levelStars = scores:getScore(scoresLevelWithStars):getValue()
		print("map.getStarsImageIndex ==>"..levelStars)
		return (levelStars)
	end

	map.isGateOpen = function(gateName)
		print("map.isGateOpen("..gateName..")")
		local scoreGateName = "gate_"..gateName
		print("map.isGateOpen ==> "..(tostring(scores:getScore(scoreGateName):getValue() == 1)))
		return (scores:getScore(scoreGateName):getValue() == 1)
	end

	map.openGate = function(gateName)
		print ("map.openGate gateName("..gateName..")")
		local scoreGateName = "gate_"..gateName
		scores:getScore(scoreGateName):setValue(1)
		m_didOpenGate = true
		refreshFirstLockedLevelByGate()
		print ("map.openGate exit")
	end

	return map
end

map = createLibMap()