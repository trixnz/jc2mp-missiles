Just Cause 2: Multiplayer - Missiles
==============

A **```WORK IN PROGRESS```** API for creating projectiles inside of JC2-MP.

Usage
==============

Projectiles can be created using the global ```EntityManager``` object. An example of a Half-Life 2 style rocket launcher has been provided in ```FireTests.lua```.

To fire a 'set it and forget it' missile in a single direction, the following code would be used:
```Lua
EntityManager:CreateEntity('Missile', {
	origin = Camera:GetPosition(),
	angle = Camera:GetAngle()
})
```
