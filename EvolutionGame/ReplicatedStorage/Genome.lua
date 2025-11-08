--!strict
-- Genome
-- A library for creating, mutating, and combining genetic information.

local Genome = {}

--[[
    Creates a new genome from a template.
    The template is a dictionary where keys are trait names.
    The value for each trait is another dictionary specifying its properties:
    {
        type = "number", "string",
        defaultValue = any,
        min = number (optional, for numbers),
        max = number (optional, for numbers),
        possibleValues = array (optional, for strings)
    }
]]
function Genome.create(template)
    local newGenome = {}
    for trait, properties in pairs(template) do
        newGenome[trait] = properties.defaultValue
    end
    return newGenome
end

-- Mutates a genome based on the template's rules.
function Genome.mutate(genome, template, mutationRate)
    local mutatedGenome = {}
    for trait, value in pairs(genome) do
        if math.random() < mutationRate then
            local props = template[trait]
            if props.type == "number" then
                local mutationAmount = (props.max - props.min) * 0.1 -- Mutate by up to 10% of the range
                local newValue = value + (math.random() * 2 - 1) * mutationAmount
                mutatedGenome[trait] = math.clamp(newValue, props.min, props.max)
            elseif props.type == "string" then
                -- Select a random new value from the possible options
                mutatedGenome[trait] = props.possibleValues[math.random(#props.possibleValues)]
            end
        else
            mutatedGenome[trait] = value
        end
    end
    return mutatedGenome
end

-- Combines two parent genomes.
function Genome.combine(genome1, genome2, template)
    local childGenome = {}
    for trait, value1 in pairs(genome1) do
        local value2 = genome2[trait]
        if value2 then
            local props = template[trait]
            if props.type == "number" then
                -- Average numeric traits
                childGenome[trait] = (value1 + value2) / 2
            elseif props.type == "string" then
                -- Randomly pick one of the parent's string-based traits
                childGenome[trait] = math.random() < 0.5 and value1 or value2
            end
        else
            childGenome[trait] = value1
        end
    end
    return childGenome
end

return Genome
