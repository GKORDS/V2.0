# Winona Remote Full Map Range Mod

This repository contains a Don't Starve Together mod that upgrades Winona's Handy Remote.

## Features

* Extends the remote's targeting circle to cover the entire map.
* Removes the distance restriction for commanding Winona's Catapults, letting you trigger them from anywhere in the world.

## Installation

1. Copy the contents of this repository into your `mods` directory for Don't Starve Together.
2. Ensure the folder name begins with `workshop-` or rename it appropriately for local mods.
3. Enable the mod on both the server and all clients (the mod is marked as required for everyone).

## Notes

* The mod automatically calculates the map's diagonal to determine the range. It defaults to a very large radius if world data is not yet available.
* No configuration options are exposed at the moment. If you need a specific radius, the logic can be updated inside `modmain.lua`.