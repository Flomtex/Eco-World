# Eco-World: Optimized Ecosystem Simulation

## Overview
This is a streamlined version of the Eco-World simulation, optimized for simplicity, maintainability, and ecosystem dynamics.

## Architecture Changes

### Before Optimization
- **782 lines** across 13 files
- Complex A* pathfinding system (86 lines)
- Over-engineered state machines (201 lines)
- FOV-based creature sensing (88 lines)
- Mixed responsibilities across multiple files

### After Optimization 
- **~200 lines** across key files (75% reduction)
- Simple movement toward targets
- Clean hunger/wander state system
- Distance-based sensing
- Clear separation of concerns

## Key Components

### SimplifiedCreature.gd (78 lines)
- Basic creature AI with hunger-driven behavior
- Simple movement and obstacle avoidance
- Energy management and death mechanics

### Species System
- **Herbivore**: Fast, eats plants, can reproduce
- **Carnivore**: Slower but stronger, hunts herbivores
- Both species have distinct behaviors and appearances

### EcosystemManager.gd (87 lines)
- Centralized ecosystem control
- Automatic plant regrowth
- Population dynamics (reproduction)
- Multi-species spawning

### SimplifiedTerrainMap.gd (47 lines)
- Essential terrain functions only
- Efficient walkability checks
- Simple coordinate conversions

## Ecosystem Features

### Food Chain
- Plants → Herbivores → Carnivores
- Two plant types: regular plants (25 energy) and fruit trees (40 energy)
- Carnivores get 60 energy from hunting

### Population Dynamics
- Herbivores reproduce when they have 150+ energy
- Automatic population limits prevent overcrowding
- Creatures die if they run out of energy

### Environment
- Plants regrow every 6 seconds up to a maximum of 30
- 30% chance for fruit trees vs regular plants
- Real-time ecosystem statistics display

## Benefits of Optimization

1. **Maintainability**: Much easier to understand and modify
2. **Performance**: Simpler algorithms mean better performance
3. **Extensibility**: Easy to add new species and behaviors
4. **Ecosystem Focus**: Emphasis on interactions rather than complex individual behaviors

## Adding New Species

To add a new creature type:

1. Create a script extending `SimplifiedCreature`
2. Override `_ready()` to set species-specific stats
3. Override `_seek_food()` for custom feeding behavior
4. Add to appropriate groups for ecosystem tracking
5. Create a scene file and add to EcosystemManager

## Future Enhancements

- Seasonal cycles affecting plant growth
- Territorial behaviors
- Pack hunting for carnivores
- Plant spreading and seed dispersal
- Environmental hazards and safe zones