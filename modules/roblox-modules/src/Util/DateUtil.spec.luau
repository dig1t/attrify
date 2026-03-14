local DateUtil = require(script.Parent.DateUtil)

return function()
	describe("Clock Formatters", function()
		it("should format a unix timestamp to clock format", function()
			local secondsLeft: number = 80
			local clockTime: string = DateUtil.elapsedTimeClockFormat(secondsLeft)

			expect(clockTime).to.equal("01:20")
		end)

		it("should display a readable string of time passed", function()
			local nowTimestamp: number = DateUtil.unix()
			local timestamp: number = nowTimestamp - 1200
			local readableTime: string = DateUtil.timeAgo(timestamp)

			expect(readableTime).to.equal("20 minutes ago")
		end)

		it("should display a readable string of the time", function()
			local nowTimestamp: number = DateUtil.unix()
			local readableTime: string = DateUtil.totalTime(nowTimestamp - 120)
			local readableTimeDiff: string =
				DateUtil.totalTime(nowTimestamp - 120, nowTimestamp)

			expect(readableTime).to.equal("2 minutes")
			expect(readableTimeDiff).to.equal("2 minutes")
		end)
	end)
end
