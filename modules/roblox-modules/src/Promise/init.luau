--[=[
	@class Promise

	Lightweight Promise class for asynchronous operations.

	```lua
	local promise: typeof(Promise.Promise)? -- Blank variable to allow rejection during a waterfall

	promise = Promise.new(function(resolve, reject)
		task.wait(1)
		resolve(0)
	end):andThen(function(num)
		return num + 1
	end):andThen(function(num)
		promise:reject("error")
	end):catch(function(err)
		warn(err)
	end):finally(function(num)
		print("finally", promise.status)

		if promise.status ~= "rejected" then
			print(num)
		end
	end) :: Promise.Promise
	```

	Install with wally by adding the following to your `wally.toml`:
	```toml
	Promise = "dig1t/promise@1.1.3"
	```
]=]
local Promise = {}
Promise.__index = Promise

--[=[
	@type Callback (...any) -> ()
	@within Promise
]=]
export type Callback = (...any) -> ()

export type Promise = typeof(setmetatable(
	{} :: {
		_fulfillmentCallbacks: { Callback },
		_rejectionCallbacks: { Callback },
		_onFinalizedCallback: Callback?,
		_resultArgs: { [any]: any },
		_executor: PromiseExecutor,
		_running: boolean,
		status: string?,
		promise: boolean,
	},
	Promise
))

--[=[
	@interface PromiseExecutor
	@within Promise
	@field resolve Callback -- Resolves the promise
	@field reject Callback -- Rejects the promise
]=]
export type PromiseExecutor = (resolve: Callback, reject: Callback) -> ()

--[=[
	Current status of the promise

	@prop statusType table
	@within Promise
]=]
Promise.statusType = {
	pending = "pending", -- The promise is waiting for a result
	fulfilled = "fulfilled", -- The promise was fulfilled successfully
	rejected = "rejected", -- The promise was rejected
}

--[=[
	Constructs a new Promise instance.

	```lua
	Promise.new(function(resolve, reject)
		task.wait(1)
		resolve(0)
	end)
	```

	@param executor function -- The function to call when the promise is created.
	@return Promise
]=]
function Promise.new(executor: PromiseExecutor): Promise
	assert(typeof(executor) == "function", "Must give a function to make a promise")

	local self = setmetatable({}, Promise) :: Promise

	self._fulfillmentCallbacks = {}
	self._rejectionCallbacks = {}
	self._resultArgs = {}
	self._running = false
	self.promise = true

	self._executor = executor
	self.status = Promise.statusType.pending

	return self
end

--- Creates a new promise that resolves when all of the promises in the given table have resolved.
function Promise.all(promises: { Promise? }): Promise
	return Promise.new(function(resolve: Callback, reject: Callback)
		local results = {}
		local totalPromises = 0
		local promisesResolved = 0
		local currentTasks = {}
		local rejected = false

		for _, _ in promises do
			totalPromises += 1
		end

		for index: number, promise: Promise? in promises do
			if not promise then
				continue
			end

			local taskId = #currentTasks + 1

			currentTasks[taskId] = task.spawn(function()
				local success: boolean, res: string = promise:await()

				results[index] = res
				promisesResolved += 1
				currentTasks[taskId] = nil

				if not success then
					-- Cancel all other tasks
					for _, _task: thread in pairs(currentTasks) do
						task.cancel(_task)
					end

					if not rejected then
						rejected = true
						reject(res)
					end

					return
				end

				if promisesResolved == totalPromises then
					resolve(results)
				end
			end)
		end
	end)
end

--- Creates a new promise that is resolved.
function Promise.resolve(result: any): Promise
	return Promise.new(function(resolve: Callback)
		resolve(result)
	end)
end

--- Creates a new promise that is rejected.
function Promise.reject(result: any): Promise
	return Promise.new(function(_, reject: Callback)
		reject(result)
	end)
end

--- Returns a new promise and the resolvers for the promise.
function Promise.withResolvers(): (Promise, Callback, Callback)
	local promise: Promise = Promise.new(function() end)

	return promise,
		function(resolve: Callback)
			return promise:_resolve(resolve)
		end,
		function(reject: Callback)
			return promise:_reject(reject)
		end
end

--[=[
	Runs the Promise executor.

	```lua
	Promise:_run()
	```

	@method _run
	@within Promise
	@ignore
]=]
function Promise._run(self: Promise)
	if self.status ~= Promise.statusType.pending or self._running then
		return
	end

	self._running = true

	-- Results
	local resolveResult: any
	local rejectionResult: any

	-- Resolvers
	local resolve = function(...)
		resolveResult = self:_resolve(...)
	end

	local reject = function(...)
		rejectionResult = self:_reject(...)
	end

	local success: boolean, err: any = pcall(self._executor, resolve, reject)

	if not success and self.status == Promise.statusType.pending then
		self:_reject(err)
	end

	if resolveResult then
		self:_resolve(resolveResult)
	end

	if rejectionResult then
		self:_reject(rejectionResult)
	end

	return
end

--[=[
	Resolves a promise with tuple parameters.

	```lua
	Promise:resolve(...)
	```

	@ignore
	@method _resolve
	@within Promise
	@param ... any -- The tuple parameters to resolve the promise with.
]=]
function Promise._resolve(self: Promise, ...)
	if self.status ~= Promise.statusType.pending then
		warn(
			string.format(
				"Cannot resolve a promise %s",
				self.status == Promise.statusType.rejected and "after rejection"
					or "more than once"
			)
		)

		return
	end

	self._resultArgs = { ... }

	local lastRes = self._resultArgs or {} -- Start the callbacks with the initial resolution tuple

	if not self._fulfillmentCallbacks or #self._fulfillmentCallbacks == 0 then
		self.status = Promise.statusType.fulfilled

		if self._onFinalizedCallback then
			self._onFinalizedCallback(unpack(lastRes))
		end

		return
	end

	for _, fn in self._fulfillmentCallbacks do
		-- Set lastRes to the returned argument from the last callback.
		lastRes = { fn(unpack(lastRes)) }

		if self.status ~= Promise.statusType.pending then
			break
		end
	end

	if self.status == Promise.statusType.pending then
		self.status = Promise.statusType.fulfilled
	end

	-- If defined, last result will be passed to the finally event.
	if self._onFinalizedCallback then
		self._onFinalizedCallback(unpack(lastRes))
	end
end

--[=[
	Rejects a promise with tuple parameters.

	```lua
	Promise:reject(errorMessage)
	```

	@ignore
	@method _reject
	@within Promise
	@param ... any -- The tuple parameters to reject the promise with.
]=]
function Promise._reject(self: Promise, ...)
	if self.status ~= Promise.statusType.pending then
		warn(
			string.format(
				"Cannot reject a promise %s",
				self.status == Promise.statusType.fulfilled and "after fulfillment"
					or "more than once"
			)
		)

		return
	end

	self.status = Promise.statusType.rejected
	self._resultArgs = { ... }

	if self._rejectionCallbacks then
		for _, fn in self._rejectionCallbacks do
			fn(...)
		end
	end

	if self._onFinalizedCallback then
		self._onFinalizedCallback(...)
	end

	return
end

--[=[
	Resolves a promise with tuple parameters.

	Called when the promise is fulfilled, if there are multiple fulfillment callbacks
	then the result of the last callback will waterfall into the next callback, if the promise rejects during the
	callback waterfall, then it will stop waterfalling.

	The first callback will begin with the arguments from the resolution callback.

	The promise can be rejected until the last fulfillment callback is called.

	```lua
	Promise:resolve(...)
	```

	@method andThen
	@within Promise
	@param executor function -- The function to call when the promise is fulfilled.
	@return Promise
]=]
function Promise.andThen(self: Promise, executor: Callback): Promise
	assert(typeof(executor) == "function", "Must give a function to resolve")

	if self.status == Promise.statusType.pending then
		self:_run()
	end

	if self.status == Promise.statusType.fulfilled then
		executor(unpack(self._resultArgs))

		return self
	end

	self._fulfillmentCallbacks[#self._fulfillmentCallbacks + 1] = executor

	return self
end

--[=[
	Called when the Promise is rejected.


	@method catch
	@within Promise
	@param callback function -- The function to call when the Promise is rejected.
	@return Promise
]=]
function Promise.catch(self: Promise, callback: Callback): Promise
	assert(typeof(callback) == "function", "Must give a function to catching errors")

	if self.status == Promise.statusType.pending then
		self:_run()
	end

	if self.status == Promise.statusType.rejected then
		callback(unpack(self._resultArgs))

		return self
	end

	self._rejectionCallbacks[#self._rejectionCallbacks + 1] = callback

	return self
end

--[=[
	Similar to andThen, finally will always be called at the end of the Promise
	and can only be set once, if the Promise is rejected then the callback run with return no parameters

	```lua
	Promise:resolve(...)
	```


	@method finally
	@within Promise
	@param callback function -- The function to call when the promise is fulfilled.
	@return Promise
]=]
function Promise.finally(self: Promise, callback: Callback): Promise
	assert(not self._onFinalizedCallback, "Only one finally callback can be used")
	assert(
		typeof(callback) == "function",
		"Must give a function for the finally callback"
	)

	if self.status == Promise.statusType.pending then
		self:_run()
	end

	if
		self.status == Promise.statusType.fulfilled
		or self.status == Promise.statusType.rejected
	then
		callback(unpack(self._resultArgs))

		return self
	end

	self._onFinalizedCallback = callback

	return self
end

--[=[
	Awaits the promise and returns the result.

	```lua
	local success: boolean, result: any = Promise:await()
	```

	@method await
	@within Promise
	@return boolean -- Whether the promise was fulfilled or not.
	@return any -- The result of the promise.
]=]
function Promise.await(self: Promise): (boolean, any)
	if self.status == Promise.statusType.pending then
		local _coroutine = coroutine.running()
		local suspended = false

		self:finally(function()
			if not suspended then
				return
			end

			task.spawn(_coroutine)
		end):catch(function() end)

		if self.status == Promise.statusType.pending then
			suspended = true
			coroutine.yield()
		end
	end

	return self.status == Promise.statusType.fulfilled, unpack(self._resultArgs)
end

--[=[
	Destroys the Promise instance.

	```lua
	Promise:destroy()
	```

	@method destroy
	@within Promise
]=]
function Promise.destroy(self: Promise)
	for key: any, _ in pairs(self) do
		self[key] = nil
	end
end

--[=[
	Alias for promise:destroy()

	@method Destroy
	@within Promise
	@tag Cleanup
]=]
function Promise.Destroy(self: Promise)
	self:destroy()
end

return Promise
