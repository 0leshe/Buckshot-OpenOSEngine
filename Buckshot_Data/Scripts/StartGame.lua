local uni = require('unicode')
Start = function()
	os.sleep(1)
	playSound("Before Every Load",true)
	local len = math.ceil(uni.len(loc.welcomeMessage)/2)
	local currentTextIndex = text(160/2-len,25,0xFFFFFF,loc.welcomeMessage)
	colorFilter = 0x0
	fadeIn()
	invoke(function()
		UI[currentTextIndex] = nil
		colorFilter = 0xDDDDDD
	end, 1.5)
end