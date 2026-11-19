const Types = require("@VideState/Types")

-- Rule metadata keyed by name; a name can only be registered once
local rules = {} :: { [string]: Types.RuleMetaData<string> }

const function checkDuplicatedName(name: string)
    if rules[name] then
        error(("Duplicate rule name: %s"):format(name))
    end
end

local api = {}

function api.register(metaData: Types.RuleMetaData<string>)
    checkDuplicatedName(metaData.name)

    rules[metaData.name] = table.freeze({
        name = metaData.name,
        description = metaData.description,
        tags = metaData.tags,
        allowedStateNames = metaData.allowedStateNames,
    }) :: Types.RuleMetaData<string>
end

function api.get(name: string): Types.RuleMetaData<string>?
    return rules[name]
end

return table.freeze(api)
