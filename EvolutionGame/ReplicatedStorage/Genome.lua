--!strict
-- Genome
-- A library for creating, mutating, and combining genetic information.

local Genome = {}

-- Creates a new genome from a template.
-- The template is a dictionary where keys are trait names and values are default numbers.
function Genome.create(template)
    local newGenome = {}
    for trait, value in pairs(template) do
        newGenome[trait] = value
    end
    return newGenome
end

-- Mutates a genome. Each trait has a chance to be slightly altered.
function Genome.mutate(genome, mutationRate, mutationAmount)
    local mutatedGenome = {}
    for trait, value in pairs(genome) do
        if math.random() < mutationRate then
            mutatedGenome[trait] = value + (math.random() * 2 - 1) * mutationAmount
        else
            mutatedGenome[trait] = value
        end
    end
    return mutatedGenome
end

-- Combines two parent genomes to create a new one for an offspring.
-- This simple model just averages the parents' traits.
function Genome.combine(genome1, genome2)
    local childGenome = {}
    for trait, value1 in pairs(genome1) do
        local value2 = genome2[trait]
        if value2 then
            childGenome[trait] = (value1 + value2) / 2
        else
            childGenome[trait] = value1 -- Fallback if parent 2 is missing a trait
        end
    end
    return childGenome
end

return Genome
