--!strict
-- Crée une instance avec ses propriétés et ses enfants : New("TextLabel", { Text = "…" }, { enfants… }).
-- La propriété Parent est appliquée en dernier.
local function New(className: string, props: { [string]: any }, children: { Instance }?): any
	local instance = Instance.new(className) :: any
	for key, value in props do
		if key ~= "Parent" then
			instance[key] = value
		end
	end
	if children then
		for _, child in children do
			child.Parent = instance
		end
	end
	if props.Parent then
		instance.Parent = props.Parent
	end
	return instance
end

return New
