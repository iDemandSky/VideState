const Vide = require("@packages/Vide")
const VideState = require("@VideState")

-- Times one operation at a time, so a slow part can be found. Every measurement runs `ROUNDS` rounds of
-- `iterations` calls, throws the first round away as a warm-up, and prints the median and the fastest round in
-- microseconds for one call.
const ROUNDS = 5

const STATE_NAMES = {
    "Idle",
    "A",
    "B",
    "C",
}

local nameCounter = 0

-- A rule name that was never used before, because a name is registered when the rule is made.
const function uniqueName(prefix: string): string
    nameCounter += 1

    return `{prefix}{nameCounter}`
end

const function createStates()
    local states = {}

    for index, name in STATE_NAMES do
        states[name] = {
            opacity = Vide.source(index - 1),
            size = Vide.source(UDim2.fromScale(index - 1, index - 1)),
        }
    end

    return states
end

const function createRule(name: string?)
    return VideState.rule({
        opacity = VideState.float(),
        size = VideState.udim2(),
    }, {
        name = name or uniqueName("BenchRule"),
    })
end

-- A rule with many fields of different schemas, for the cost of validating a state.
const function createWideRule()
    local fields = {}

    for index = 1, 10 do
        fields[`number{index}`] = VideState.float()
        fields[`color{index}`] = VideState.color3()
    end

    return VideState.rule(fields, {
        name = uniqueName("BenchWide"),
    })
end

const function createWideStates()
    local states = {}

    for _, name in STATE_NAMES do
        local values = {}

        for index = 1, 10 do
            values[`number{index}`] = Vide.source(index)
            values[`color{index}`] = Vide.source(Color3.new(index / 10, 0, 0))
        end

        states[name] = values
    end

    return states
end

const function measure(group: string, name: string, iterations: number, work: (index: number) -> ())
    local rounds: { number } = {}

    for round = 1, ROUNDS do
        local began = os.clock()

        for index = 1, iterations do
            work(index)
        end

        local elapsed = os.clock() - began

        if round > 1 then
            table.insert(rounds, elapsed / iterations * 1e6)
        end
    end

    table.sort(rounds)

    print(
        string.format(
            "[bench] %s, %s: median %.2f us, fastest %.2f us (%d calls per round)",
            group,
            name,
            rounds[math.ceil(#rounds / 2)],
            rounds[1],
            iterations
        )
    )
end

-- Makes `count` handlers and lets `connect` add its connections to each one.
const function createHandlers(rule: any, count: number, connect: (handler: any) -> ())
    local handlers = {}

    for _ = 1, count do
        local handler = rule.new(createStates(), "Idle")

        connect(handler)
        table.insert(handlers, handler)
    end

    return handlers
end

const function destroyAll(handlers: { any })
    for _, handler in handlers do
        handler.destroy()
    end
end

return table.freeze({
    measure = measure,
    uniqueName = uniqueName,
    createStates = createStates,
    createRule = createRule,
    createWideRule = createWideRule,
    createWideStates = createWideStates,
    createHandlers = createHandlers,
    destroyAll = destroyAll,
})
