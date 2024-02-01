local uni = require('unicode')
Start = function()
	engineLoadingState("Loading sound")
	playSound("Before Every Load",true)
	engineLoadingState("Loading main UI")
	setColorFilter(0x0)
	local currentTextIndex = text(160/2-math.ceil(uni.len(loc.welcomeMessage)/2), 25, 0xFFFFFF, loc.welcomeMessage)
	fadeIn(1.5,0xDDDDDD)
	invoke(function()
		UI[currentTextIndex] = nil
		setColorFilter(0xDDDDDD)
		--Lets let user pick name
		local len = math.ceil(uni.len(loc.yourName)/2)
		local currentTextIndex = text(160/2-len,25,0xFFFFFF,loc.yourName)
		local playerNameTextIndex = text(160/2-len,26,0xFFFFFF,'')
		local indexOfHandleToText = getID()
		local inputHandle = inputHandler()
		inputHandle.maxInputLen = 6
		callEverytime[indexOfHandleToText] = function() UI[playerNameTextIndex].text = inputHandle.text UI[playerNameTextIndex].x = 160/2-math.ceil(uni.len(inputHandle.text)/2) end
		inputHandle.onInputFinished = function()
		  removeFromET(indexOfHandleToText)
		  scripts.RoundManager.PLAYERNICKNAME = inputHandle.text
	      --Now, lets go with round manager and ask for a new round.
		  execute('RoundManager','ShowEnergy')
		end
	end, 2.5)
end