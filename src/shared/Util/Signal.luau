--!strict
-- Signal minimal : connect(handler) renvoie une fonction de déconnexion, fire(...) appelle les handlers.

export type Signal = {
	_handlers: { (...any) -> () },
	connect: (self: Signal, handler: (...any) -> ()) -> () -> (),
	fire: (self: Signal, ...any) -> (),
}

local Signal = {}

local function connect(self: Signal, handler: (...any) -> ()): () -> ()
	table.insert(self._handlers, handler)
	return function()
		local index = table.find(self._handlers, handler)
		if index then
			table.remove(self._handlers, index)
		end
	end
end

local function fire(self: Signal, ...: any)
	for _, handler in table.clone(self._handlers) do
		handler(...)
	end
end

function Signal.new(): Signal
	return {
		_handlers = {},
		connect = connect,
		fire = fire,
	}
end

return Signal
