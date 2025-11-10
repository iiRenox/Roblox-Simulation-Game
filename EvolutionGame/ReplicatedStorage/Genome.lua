--!strict

--- A library for creating, mutating, and combining genetic information.
-- The Genome module provides a set of functions to handle the genetic data of entities
-- within the simulation. It uses a template-based system to define the structure and
-- constraints of different genomes, supporting complex inheritance and mutation rules.
local Genome = {}

-- A registry of allele functions that determine how traits are combined.
local Alleles = {
	--- Averages the numeric traits of two parents.
	average = function(value1, value2)
		return (value1 + value2) / 2
	end,
	--- Inherits trait from parent 1.
	fromParent1 = function(value1, _)
		return value1
	end,
	--- Inherits trait from parent 2.
	fromParent2 = function(_, value2)
		return value2
	end,
	--- Inherits 70% from parent 1 and 30% from parent 2.
	blend7030_P1 = function(value1, value2)
		return value1 * 0.7 + value2 * 0.3
	end,
	--- Inherits 30% from parent 1 and 70% from parent 2.
	blend7030_P2 = function(value1, value2)
		return value1 * 0.3 + value2 * 0.7
	end
}

--- Creates a new genome based on a provided template.
-- This function initializes a genome with default values specified in the template.
-- @param template table A dictionary where keys are trait names and values are tables
--                      defining the trait's properties (type, defaultValue, etc.).
-- @return table The newly created genome.
function Genome.create(template)
	local newGenome = {}
	for trait, properties in pairs(template) do
		newGenome[trait] = properties.defaultValue
	end
	return newGenome
end

--- Mutates a genome's traits based on the genome's own mutation chance.
-- For each trait, a random chance determines if a mutation occurs.
-- @param genome table The original genome to mutate.
-- @param template table The genome template that defines the rules and constraints.
-- @return table The new, potentially mutated genome.
function Genome.mutate(genome, template)
	local mutatedGenome = {}
	local mutationRate = genome.mutationChance or 0.02 -- Fallback to default if not in genome

	for trait, value in pairs(genome) do
		if math.random() < mutationRate then
			local props = template[trait]
			if props.type == "number" then
				local mutationAmount = (props.max - props.min) * 0.1 -- Mutate by up to 10%
				local newValue = value + (math.random() * 2 - 1) * mutationAmount
				mutatedGenome[trait] = math.clamp(newValue, props.min, props.max)
			elseif props.type == "string" then
				mutatedGenome[trait] = props.possibleValues[math.random(#props.possibleValues)]
			elseif props.type == "allele" then
				-- Get all allele function names from the Alleles table
				local alleleNames = {}
				for name, _ in pairs(Alleles) do table.insert(alleleNames, name) end
				mutatedGenome[trait] = alleleNames[math.random(#alleleNames)]
			else
				mutatedGenome[trait] = value
			end
		else
			mutatedGenome[trait] = value
		end
	end
	return mutatedGenome
end

--- Combines two parent genomes to create a new child genome using specified alleles.
-- The inheritanceAllele gene determines the function used for combining numeric traits.
-- @param genome1 table The first parent's genome.
-- @param genome2 table The second parent's genome.
-- @param template table The genome template to reference trait types.
-- @return table The resulting child genome.
function Genome.combine(genome1, genome2, template)
	local childGenome = {}
	-- The inheritance strategy is determined by the allele of the first parent.
	local inheritanceAlleleName = genome1.inheritanceAllele or "average"
	local combinationFunc = Alleles[inheritanceAlleleName] or Alleles.average

	for trait, value1 in pairs(genome1) do
		local value2 = genome2[trait]
		if value2 then
			local props = template[trait]
			if props.type == "number" then
				childGenome[trait] = combinationFunc(value1, value2)
			elseif props.type == "string" or props.type == "allele" then
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
