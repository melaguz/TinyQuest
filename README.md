# Grid Walk Demo

Piccola demo Godot 4.7.1 di movimento tile-based in stile RPG classico. Il mondo è salvato direttamente in `scenes/world.tscn`: tre `TileMapLayer` persistenti usano `resources/world_tileset.tres`, inclusa una Scene Tile palette con `Tree` e `Rock`.

Aprire `project.godot` con Godot e premere **F6/F5**. Muoversi con **WASD** o le **frecce**.

Per modificare il livello senza codice, aprire `scenes/world.tscn` e dipingere sui layer `Ground`, `Obstacles` o `Props` dal pannello TileMap.

Test headless:

```powershell
Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/test_runner.gd
```
