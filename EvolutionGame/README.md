# Evolution Game

## Overview

This project is a Roblox game that simulates the processes of evolution. It features a procedurally generated world where different forms of life, including plants, animals, and eventually intelligent NPCs, interact and evolve over time. The simulation is built on a modular, service-based architecture and is designed to be highly extensible.

## Core Features

*   **Procedural World Generation**: The world is generated using multiple layers of Perlin noise to create realistic continents, mountains, rivers, and biomes.
*   **Genetic Evolution**: Plants and animals possess a genome that determines their physical and behavioral traits. These genomes can be mutated and combined through reproduction, allowing species to adapt and evolve.
*   **Dynamic Ecosystem**: All life forms interact with each other and their environment. Animals compete for food, plants spread seeds, and NPCs gather resources.
*   **Intelligent NPCs**: The simulation includes human NPCs who do not evolve genetically but through the acquisition of knowledge. They can form tribes, discover new technologies, and build a society.
*   **Service-Based Architecture**: The codebase is organized into distinct services (`NatureService`, `AnimalService`, `NPCService`, etc.), making it easy to manage and extend different aspects of the simulation.
*   **Time and Lighting System**: A global `TimeService` manages the day/night cycle, seasons, and simulation speed, while a `LightingService` provides dynamic atmospheric effects.

## Project Structure

The project is organized into the following main directories within the `EvolutionGame` folder:

*   `ReplicatedStorage`: Contains modules that need to be accessible to both the server and the client, such as the `Genome` library and `WorldUtil` functions.
*   `ServerScriptService`: This is the heart of the simulation, containing all the core services and class modules.
    *   **Services**: `NatureService`, `AnimalService`, `NPCService`, `TimeService`, `LightingService`.
    *   **Classes**: `Animal`, `NPC`, `Plant`, `Tree`.
    *   **Modules**: `Pathfinding`, `Main` (the entry point).
*   `StarterPlayer/StarterPlayerScripts`: Contains client-side scripts, such as the UI controller for changing the game speed.

## Setup and Usage

1.  **Open in Roblox Studio**: Open the `EvolutionGame` directory as a project in Roblox Studio.
2.  **Run the Simulation**: Simply run the game from the Studio. The `Main.lua` script in `ServerScriptService` will automatically start the world generation and begin the simulation.
3.  **Control the Speed**: A button on the top-right of the screen allows you to cycle through different simulation speeds (0.1x, 1x, 10x, 100x), so you can observe the evolution at your own pace.

## How it Works

The simulation begins with the `Main.lua` script, which initializes all the services in the correct order. The `NatureService` procedurally generates the terrain and spawns the initial flora. Once the world is ready, the `AnimalService` and `NPCService` spawn the first creatures.

From there, the `TimeService` drives the simulation with a continuous `tick` event. On each tick, every entity in the game (plants, animals, NPCs) updates its state according to its internal logic and AI, leading to emergent behaviors and the gradual evolution of the ecosystem.
