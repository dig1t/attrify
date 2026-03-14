--[=[
	@class Signal

	Author: dig1t

	A lightweight signal implementation that allows for firing, connecting, and disconnecting.

	Install with wally by adding the following to your `wally.toml`:
	```toml
	Signal = "dig1t/signal@1.0.0"
	```
]=]

--!strict
--!native

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Util = require(script.Parent.Util)

local SIZE_LIMIT: number = 0 -- The maximum number of events that can be stored in the buffer before being fired.
local BUFFER_TIME: number = 0 -- The time in seconds before the buffer is automatically fired.
local BUFFER_CHAR_LIMIT = 1000

local Connection = {}
Connection.__index = Connection

-- Contains arguments passed to the signal
type BufferItem = { any }

--[=[
	@interface BufferOptions
	@within Signal
	.sizeLimit number?
	.bufferTime number?
]=]
export type BufferOptions = {
	sizeLimit: number?,
	bufferTime: number?,
}

export type Connection<T...> = RBXScriptConnection & typeof(setmetatable(
	{} :: {
		_connectionId: string,
		_signal: Signal<T...>,
		_callback: Callback<T...>,
	},
	Connection
))

--[=[
	@type Callback (T...) -> ()
	@within Signal
]=]
export type Callback<T...> = (T...) -> ()

function Connection.new<T...>(signal: Signal<T...>, callback: Callback<T...>): Connection<T...>
	return setmetatable({
		_connectionId = Util.randomString(8),
		_signal = signal,
		_callback = callback,

		Connected = true,
	}, Connection) :: Connection<T...>
end

function Connection.Disconnect<T...>(self: Connection<T...>)
	if not self.Connected or not self._signal then
		return
	end

	self.Connected = false
	self._signal:Disconnect(self._connectionId)
end

local Signal = {}
Signal.__index = Signal

export type Signal<T...> = {
	_connections: { [string]: any },
	_buffer: { BufferItem },
	_bufferSize: number,
	_charCount: number,
	_elapsedTime: number,
	_timerConnection: RBXScriptConnection?,

	sizeLimit: number,
	bufferTime: number,

	onDestroy: () -> ()?,

	new: () -> Signal<T...>,
	Fire: (Signal<T...>, T...) -> (),
	Disconnect: (Signal<T...>, connectionId: string) -> (),
	Connect: (Signal<T...>, callback: Callback<T...>) -> RBXScriptConnection,
	Once: (Signal<T...>, callback: Callback<T...>) -> RBXScriptConnection,
	Wait: (Signal<T...>) -> T...,
	Destroy: (Signal<T...>) -> (),

	_flush: (Signal<T...>) -> (),
	_startTimer: (Signal<T...>) -> (),
	_stopTimer: (Signal<T...>) -> (),
}

local function getTableCharacterCount(table: { any }): number
	local json: string = HttpService:JSONEncode(table)

	return #json
end

--[=[
	Starts a new signal

	On creation, an `onDestroy` function can be defined to run when the signal is destroyed.
]=]
function Signal.new<T...>(options: BufferOptions?): Signal<T...>
	local bufferOptions = options or {} :: BufferOptions

	return setmetatable({
		_connections = {},
		_buffer = {},
		_bufferSize = 0,
		_charCount = 0,
		_elapsedTime = 0,
		_timerConnection = nil,

		sizeLimit = bufferOptions.sizeLimit or SIZE_LIMIT,
		bufferTime = bufferOptions.bufferTime or BUFFER_TIME,
	}, Signal) :: any
end

--[=[
	Fires the signal with the given arguments
	All arguments are stored in the buffer until the buffer is full or the buffer time has elapsed

	@method Fire
	@within Signal
	@param ... tuple -- The arguments to pass to the signal
]=]
function Signal.Fire<T...>(self: Signal<T...>, ...)
	table.insert(self._buffer, { ... } :: BufferItem)

	self._bufferSize += 1
	self._charCount += getTableCharacterCount(self._buffer)

	-- Prevent dropped signals by checking the character count
	if self._charCount >= BUFFER_CHAR_LIMIT then
		self:_flush()
		return
	end

	if self._bufferSize >= self.sizeLimit then
		self:_flush()
	elseif not self._timerConnection then
		self:_startTimer()
	end
end

--[=[
	Flushes the buffer and fires all events.

	@private
	@method _flush
	@within Signal
]=]
function Signal._flush<T...>(self: Signal<T...>)
	self:_stopTimer()

	-- Equivalent of running signal:Fire()
	for _, connection in pairs(self._connections) do
		if connection.Connected then
			for _, args in self._buffer do
				task.spawn(connection._callback, unpack(args))
			end
		end
	end

	self._buffer = {}
	self._bufferSize = 0
	self._charCount = 0
	self._elapsedTime = 0
end

function Signal._startTimer<T...>(self: Signal<T...>)
	-- Prevent multiple connections
	if self._timerConnection then
		return
	end

	self._timerConnection = RunService.Stepped:Connect(function(deltaTime: number)
		if self._bufferSize == 0 then
			return
		end

		self._elapsedTime += deltaTime

		if self._elapsedTime > self.bufferTime then
			self:_flush()
			self._elapsedTime = 0
		end
	end)
end

function Signal._stopTimer<T...>(self: Signal<T...>)
	if self._timerConnection then
		self._timerConnection:Disconnect()
		self._timerConnection = nil
	end
end

--[=[
	Disconnects a connection from the signal using the connection's ID.

	For advanced usage, you can store the connection's ID and disconnect it later.

	@private
	@method Disconnect
	@within Signal
]=]
function Signal.Disconnect<T...>(self: Signal<T...>, connectionId: string)
	self._connections[connectionId] = nil
end

--[=[
	Connects to the signal.

	```lua
	local signal = Signal.new()

	signal:Connect(function(message: string)
		print(message) -- "Hello, world!"
	end)

	signal:Fire("Hello, world!")
	```

	@method Connect
	@within Signal
	@param callback Callback<T...> -- The function to call when the signal is fired
	@return RBXScriptConnection -- The connection object that can be used to disconnect
]=]
function Signal.Connect<T...>(self: Signal<T...>, callback: Callback<T...>): RBXScriptConnection
	local connection: Connection<T...> = Connection.new(self, callback)

	self._connections[connection._connectionId] = connection

	-- Forcibly cast to RBXScriptConnection
	return (connection :: any) :: RBXScriptConnection
end

--[=[
	Connects to the signal and disconnects after the first fire.

	```lua
	local signal = Signal.new()

	signal:Once(function(message: string)
		print(message) -- "Hello, world!"
	end)

	signal:Fire("Hello, world!")
	```

	@method Once
	@within Signal
	@param callback Callback<T...> -- The function to call when the signal is fired
]=]
function Signal.Once<T...>(self: Signal<T...>, callback: Callback<T...>): RBXScriptConnection
	local connection: RBXScriptConnection

	connection = self:Connect(function(...)
		if not connection.Connected then
			return
		end

		connection:Disconnect()
		callback(...)
	end)

	return connection
end

--[=[
	Blocks the current thread until the signal is fired.

	```lua
	local signal = Signal.new()

	task.spawn(function()
		task.wait(1)
		signal:Fire("Hello, world!")
	end)

	local message = signal:Wait() -- Blocks until the signal is fired
	print(message) -- "Hello, world!"
	```

	@method Wait
	@within Signal
]=]
function Signal.Wait<T...>(self: Signal<T...>): T...
	local _coroutine = coroutine.running()
	local connection: RBXScriptConnection

	connection = self:Connect(function(...)
		if not connection.Connected then
			return
		end

		connection:Disconnect()
		task.spawn(_coroutine, ...)
	end)

	return coroutine.yield()
end

--[=[
	Disconnects all connections from the signal.

	`Destroy` is not necessary to call as the signal will be garbage collected when it is no longer referenced.

	@method Destroy
	@within Signal
	@tag Cleanup
]=]
function Signal.Destroy<T...>(self: Signal<T...>)
	self:_stopTimer()

	for _, connection in pairs(self._connections) do
		connection:Disconnect()
	end

	self._connections = {}

	if self.onDestroy then
		self.onDestroy()
		self.onDestroy = nil
	end
end

return Signal
