--!strict

--- A library for creating, mutating, and combining genetic information.
-- The Genome module provides a set of functions to handle the genetic data of entities
-- within the simulation. It uses a template-based system to define the structure and
-- constraints of different genomes.
local Genome = {}

--- Creates a new genome based on a provided template.
-- This function initializes a genome with default values specified in the template.
-- The template defines the structure and constraints for each genetic trait.
-- @param template table A dictionary where keys are trait names and values are tables
--                      defining the trait's properties (type, defaultValue, min, max, possibleValues).
-- @return table The newly created genome with traits set to their default values.
function Genome.create(template)
    local newGenome = {}
    for trait, properties in pairs(template) do
        newGenome[trait] = properties.defaultValue
    end
    return newGenome
end

--- Mutates a genome's traits based on a mutation rate and template rules.
-- For each trait, a random chance determines if a mutation occurs.
-- Numeric traits are adjusted by a random amount within a defined range.
-- String traits are randomly swapped with another possible value from the template.
-- @param genome table The original genome to mutate.
-- @param template table The genome template that defines the rules and constraints for each trait.
-- @param mutationRate number A value between 0 and 1 representing the chance of a mutation for each trait.
-- @return table The new, potentially mutated genome.
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

--- Combines two parent genomes to create a new child genome.
-- This function simulates genetic crossover. Numeric traits are averaged between the parents.
-- String-based traits are randomly inherited from one of the two parents.
-- @param genome1 table The first parent's genome.
-- @param genome2 table The second parent's genome.
-- @param template table The genome template to reference trait types.
-- @return table The resulting child genome.
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
