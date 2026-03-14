local DateUtil = {}

export type DateTimeComponents = {
	Year: number,
	Month: number,
	Day: number,
	Hour: number,
	Minute: number,
	Second: number,
	Millisecond: number,
} | any

local milisecondsInSecond: number = 1000
local milisecondsInMinute: number = milisecondsInSecond * 60
local milisecondsInHour: number = milisecondsInMinute * 60
local milisecondsInDay: number = milisecondsInHour * 24
local milisecondsInYear: number = 31556952000
local milisecondsInMonth: number = 2629746000

local secondsInMinute: number = 60
local secondsInHour: number = secondsInMinute * 60
local secondsInDay: number = secondsInHour * 24
local secondsInMonth: number = 2629746
local secondsInYear: number = 31556952

local timeNames: { { any } } = {
	{ secondsInYear, "year" },
	{ secondsInMonth, "month" },
	{ secondsInDay, "day" },
	{ secondsInHour, "hour" },
	{ secondsInMinute, "minute" },
	{ 1, "second" },
}

--[=[
	Converts a DateTimeComponents table to a timestamp.

	@within Util
	@param components DateTimeComponents
	@return number
]=]
function DateUtil.dateTimeComponentsToTimestamp(components: DateTimeComponents): number
	assert(typeof(components) == "table", "Components must be a table")
	assert(typeof(components.Year) == "number", "Components.Year must be a number")
	assert(typeof(components.Month) == "number", "Components.Month must be a number")
	assert(typeof(components.Day) == "number", "Components.Day must be a number")
	assert(typeof(components.Hour) == "number", "Components.Hour must be a number")
	assert(typeof(components.Minute) == "number", "Components.Minute must be a number")
	assert(typeof(components.Second) == "number", "Components.Second must be a number")
	assert(
		typeof(components.Millisecond) == "number",
		"Components.Millisecond must be a number"
	)

	local timestamp: number = 0

	timestamp += components.Year * milisecondsInYear
	timestamp += components.Month * milisecondsInMonth
	timestamp += components.Day * milisecondsInDay
	timestamp += components.Hour * milisecondsInHour
	timestamp += components.Minute * milisecondsInMinute
	timestamp += components.Second * milisecondsInSecond
	timestamp += components.Millisecond

	return timestamp / 1000
end

--[=[
	Get the current unix timestamp in UTC time.
	This is the number of **seconds** since January 1, 1970.

	@within Util
	@return number
]=]
function DateUtil.unix(): number
	local utcDateComponents: DateTimeComponents = DateTime.now():ToUniversalTime()

	return DateUtil.dateTimeComponentsToTimestamp(utcDateComponents)
end

--[=[
	Gets the time in seconds since now or the provided timestamp.

	@within Util
	@param timestamp number?
	@param endTimestamp number? -- The timestamp to compare to. Defaults to current time.
	@return number
]=]
function DateUtil.timeAgoUnix(timestamp: number, endTimestamp: number?): number
	assert(typeof(timestamp) == "number", "Timestamp must be a number")
	assert(
		typeof(endTimestamp) == "number" or endTimestamp == nil,
		"toTimestamp must be a number or nil"
	)

	return (endTimestamp or DateUtil.unix()) - timestamp
end

--[=[
	Converts a unix timestamp to a `mm:ss` format (e.g. 00:02).
	A format and locale can be provided.

	Use the [DateTime](https://create.roblox.com/docs/reference/engine/datatypes/DateTime) API for formatting options.

	#### Example
	```lua
	local secondsLeft: number = 80

	Util.formatUnix(secondsLeft, "mm:ss", nil, true) -- 01:20
	Util.formatUnix(secondsLeft, "HH:mm:ss", nil, true) -- 00:01:20
	```

	@within Util
	@param timestamp number
	@param format string -- The format to use.
	@param locale string? -- The locale to use. Defaults to `en-us`.
	@param useUTC boolean? -- Whether to use UTC time. Defaults to local time.
	@return string -- The formatted time in local time.
]=]
function DateUtil.formatUnix(
	timestamp: number,
	format: string,
	locale: string?,
	useUTC: boolean
): string
	assert(typeof(timestamp) == "number", "Timestamp must be a number")
	assert(typeof(format) == "string", "format must be a string")
	assert(typeof(locale) == "string" or locale == nil, "locale must be a string or nil")

	local dateTime = DateTime.fromUnixTimestamp(math.floor(timestamp))

	return (dateTime :: any)[useUTC and "FormatUniversalTime" or "FormatLocalTime"](
		dateTime,
		format,
		locale or "en-us"
	)
end

--[=[
	Converts a unix timestamp to a `mm:ss` format (e.g. 00:02).

	#### Example
	```lua
	Util.elapsedTimeClockFormat(80) -- 01:20
	Util.elapsedTimeClockFormat(3661) -- 01:01:01
	```

	@within Util
	@param timestamp number
	@return string -- The formatted time in local time.
]=]
function DateUtil.elapsedTimeClockFormat(timestamp: number): string
	assert(typeof(timestamp) == "number", "Timestamp must be a number")

	local isOverAnHour: boolean = timestamp >= 3600

	return DateUtil.formatUnix(
		timestamp,
		isOverAnHour and "HH:mm:ss" or "mm:ss",
		"en-us",
		true
	)
end
--[=[
	Converts a unix timestamp to a readable time ago format (e.g. 1 minute ago, 1 minute 20 seconds ago).

	#### Example
	```lua
	local secondsLeft: number = 80

	Util.timeAgo(secondsLeft) -- 1 minute ago
	```

	```lua
	local secondsLeft: number = 80

	Util.timeAgo(secondsLeft, 80 + 60) -- just now
	```

	@within Util
	@param timestamp number
	@param endTimestamp number? -- The timestamp to compare to. Defaults to current time.
	@return string
]=]
function DateUtil.timeAgo(timestamp: number, endTimestamp: number?): string
	assert(typeof(timestamp) == "number", "Timestamp must be a number")
	assert(
		typeof(endTimestamp) == "number" or endTimestamp == nil,
		"endTimestamp must be a number or nil"
	)

	local timeAgo: number = DateUtil.timeAgoUnix(timestamp, endTimestamp)
	local result: string = ""

	if timeAgo < 1 then
		return "now"
	end

	local current: number = 1
	local previousUnitSeconds: number = 0

	while current <= #timeNames do
		local _time: {} = timeNames[current]
		local unitThreshold: number = timeNames[current][1]
		local unit: string = timeNames[current][2]

		if (timeAgo >= unitThreshold) and current <= #timeNames then
			local amount: number =
				math.floor((timeAgo - previousUnitSeconds) / unitThreshold)

			previousUnitSeconds += amount * unitThreshold

			if amount > 0 then
				local plural: string = amount > 1 and "s" or ""

				result = `{result}{amount} {unit}{plural} `
			end
		end

		current += 1
	end

	return `{result}ago`
end

--[=[
	Similar to `Util.timeAgo` but returns a more detailed string with the total time instead of the largest unit.
	Convert a unix timestamp to a readable format (1 days, 1 hours, 1 minutes, 1 seconds).

	#### Example
	```lua
	local secondsLeft: number = 80

	Util.totalTime(secondsLeft) -- 1 minute 20 seconds
	```

	@within Util
	@param timestamp number
	@param endTimestamp number? -- The timestamp to compare to. Defaults to current time.
	@param separator string? -- The separator to use between each unit. Defaults to a space.
	@param depth number? -- The maximum number of units to return.
	@return string
]=]
function DateUtil.totalTime(
	timestamp: number,
	endTimestamp: number?,
	separator: string?,
	depth: number?
): string
	assert(typeof(timestamp) == "number", "Timestamp must be a number")
	assert(
		typeof(endTimestamp) == "number" or endTimestamp == nil,
		"endTimestamp must be a number or nil"
	)
	assert(
		typeof(separator) == "string" or separator == nil,
		"separator must be a string or nil"
	)
	assert(typeof(depth) == "number" or depth == nil, "depth must be a number or nil")

	local _separator: string = separator or " "

	local timeAgo: number = DateUtil.timeAgoUnix(timestamp, endTimestamp)
	local result: string = ""

	if timeAgo < 1 then
		return "now"
	end

	local current: number = 1
	local previousUnitSeconds: number = 0
	local iteration: number = 0

	while current <= #timeNames and (depth == nil or iteration < depth) do
		local _time: {} = timeNames[current]
		local unitThreshold: number = timeNames[current][1]
		local unit: string = timeNames[current][2]

		if (timeAgo >= unitThreshold) and current <= #timeNames then
			local amount: number =
				math.floor((timeAgo - previousUnitSeconds) / unitThreshold)

			previousUnitSeconds += amount * unitThreshold

			if amount > 0 then
				local plural: string = amount > 1 and "s" or ""

				result = `{result}{amount} {unit}{plural}{_separator}`
				iteration += 1
			end
		end

		current += 1
	end

	-- Trim last separator and return
	return string.sub(result, 1, string.len(result) - string.len(_separator))
end

return DateUtil
