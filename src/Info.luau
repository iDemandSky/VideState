const Types = require("@VideState/Types")

-- Rule metadata keyed by name; a name can only be registered once
local rules = {} :: { [string]: Types.RuleMetadata<string> }

const function checkDuplicatedName(name: string)
    if rules[name] then
        error(("Duplicate rule name: %s"):format(name))
    end
end

local api = {}

function api.register(metadata: Types.RuleMetadata<string>)
    checkDuplicatedName(metadata.name)

    rules[metadata.name] = table.freeze({
        name = metadata.name,
        description = metadata.description,
        tags = metadata.tags,
        allowedStateNames = metadata.allowedStateNames,
    }) :: Types.RuleMetadata<string>
end

function api.get(name: string): Types.RuleMetadata<string>?
    return rules[name]
end

return table.freeze(api)
