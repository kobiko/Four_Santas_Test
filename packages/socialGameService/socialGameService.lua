-- socialGameService.lua

createLibSocialGameService = function()

	local socialGameService = {}
	--------------------------------------------------
	--consts
	--------------------------------------------------

	--------------------------------------------------
	--private
	--------------------------------------------------

	--------------------------------------------------
	--public
	--------------------------------------------------
	function socialGameService.init()
		scores:getScore("RegularScore"):reset()
		scores:getScore("LeaderBoardScore"):reset()
		scores:getScore("MilestoneScore"):reset()
	end

	function socialGameService.increaseScore(scoreName)
		scores:getScore(scoreName):increaseValue(1)
	end

	function socialGameService.getScore(scoreName)
		local score = scores:getScore(scoreName):getValue()
		return score
	end

	function socialGameService.showLeaderboard(leaderboardName)
		socialService:showLeaderboard(leaderboardName)
	end

	function socialGameService.showAllLeaderboards()
		socialService:showLeaderboard("")
	end

	function socialGameService.showAchievement()
		socialService:showAchievement()
	end

	--check if connected to google service
	function socialGameService.isConnected()
		return socialService:isConnected()
	end
	
	function socialGameService.connect()
		socialService:connect()
	end

	return socialGameService
end

socialGameService = createLibSocialGameService()

