# PROJECT REPORT — Grid Walk Demo

## Risultato

Il progetto è una demo giocabile per **Godot 4.7.1 stable** con movimento a griglia in stile RPG classico. Il player si muove di una cella da 32 px alla volta, con interpolazione fluida, senza diagonali e senza deriva. Muri, alberi e rocce impediscono fisicamente il passaggio.

Il mondo statico è ora interamente editor-based:

- il `TileSet` è una risorsa persistente `.tres`;
- terreno, muri e oggetti sono celle già serializzate in `world.tscn`;
- `Tree` e `Rock` sono scene `.tscn` riutilizzabili;
- entrambe sono registrate nel `TileSet` come Scene Tiles;
- nessuno script genera la mappa quando si avvia il gioco.

## Come provarlo

1. Estrarre `Godot_v4.7.1-stable_win64.exe.zip`, se non è già stato fatto.
2. Aprire Godot e importare `ai_game/project.godot`.
3. Premere **F5**. `scenes/main.tscn` è già configurata come scena principale.
4. Muoversi con **WASD** oppure con le **frecce direzionali**.
5. Provare a camminare contro il bordo, il muro verticale, un albero o la roccia: il passo viene rifiutato. Il varco nel muro verticale è attraversabile.

Test da PowerShell, nella cartella `ai_game`:

```powershell
Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/test_runner.gd
```

## Struttura del progetto

```text
ai_game/
├─ project.godot
├─ assets/tiles/
│  ├─ grass.svg
│  └─ wall.svg
├─ resources/
│  ├─ world_tileset.tres        TileSet persistente e Scene Tiles
│  └─ ui_theme.tres
├─ scenes/
│  ├─ main.tscn                 scena avviabile
│  ├─ world.tscn                tre TileMapLayer già popolati
│  ├─ player.tscn
│  └─ props/
│     ├─ tree.tscn              StaticBody2D riutilizzabile
│     └─ rock.tscn              StaticBody2D riutilizzabile
├─ scripts/
│  └─ player.gd                 solo input e gameplay del player
└─ tests/
   └─ test_runner.gd
```

Non esiste più uno script `world.gd`: il world non ha bisogno di codice runtime.

## Editor-based world building

### Risorse e layer

Il TileSet è salvato in `resources/world_tileset.tres` ed è modificabile dal pannello TileSet di Godot. Contiene tre source:

1. source `0`: atlas del terreno `grass.svg`;
2. source `1`: atlas del muro `wall.svg`, con poligono di collisione;
3. source `2`: `TileSetScenesCollectionSource` contenente `Tree` e `Rock`.

Le celle sono salvate nella proprietà serializzata `tile_map_data` dei tre nodi di `scenes/world.tscn`:

- `Ground`: 280 celle di terreno, una mappa 20×14;
- `Obstacles`: 75 celle muro;
- `Props`: 3 Scene Tiles, due alberi e una roccia.

Queste celle esistono già nella scena su disco. La mappa è quindi visibile appena si apre `world.tscn`, prima di premere Play e senza eseguire `_ready()`.

### Modificare la mappa dall'editor

1. Aprire `scenes/world.tscn`.
2. Selezionare `Ground` per dipingere o cancellare il prato.
3. Nel pannello TileMap in basso scegliere la source del prato e usare lo strumento matita.
4. Selezionare `Obstacles`, scegliere la source muro e dipingere nuove celle bloccanti.
5. Selezionare `Props`, scegliere la source Scene Collection e selezionare `Tree` oppure `Rock` dalla palette.
6. Posizionare l'oggetto sulla cella desiderata.
7. Salvare la scena e premere F5.

Non serve modificare codice. Un nuovo muro usa immediatamente la collisione definita nel TileSet; un nuovo albero o una nuova roccia usa la collisione contenuta nella rispettiva scena.

Per aggiungere in futuro una `House`, si crea `house.tscn` con visuale e collisione, poi dal pannello TileSet si aggiunge la PackedScene alla source Scene Collection. Da quel momento compare nella stessa palette di `Tree` e `Rock`.

### Scene riutilizzabili e collisioni

`tree.tscn` e `rock.tscn` hanno come root un `StaticBody2D`, grafica composta da `Polygon2D` e un `CollisionShape2D`. Il `TileSetScenesCollectionSource` fa riferimento direttamente a queste due PackedScene. Le loro istanze vengono gestite dal nodo `Props` come vere Scene Tiles, non come figli aggiunti manualmente in `main.tscn`.

Le collisioni dei muri sono poligoni salvati in `world_tileset.tres`. Le collisioni degli oggetti complessi rimangono nelle scene riutilizzabili, che è il posto più appropriato. Non esistono liste hardcoded di coordinate bloccate.

## Refactoring from runtime generation

Prima del refactoring, `scripts/world.gd` era collegato a `World`. In `_ready()` chiamava `build_demo_map()`, eseguiva cicli e usava `set_cell()` per creare terreno e muri solo dopo l'avvio. Alberi e rocce erano PackedScene riutilizzabili, ma venivano istanziati manualmente come figli di `main.tscn` invece di essere disponibili nella palette del TileSet.

Il refactoring ha:

- serializzato tutte le celle direttamente in `world.tscn`;
- rimosso `world.gd` e ogni generazione statica runtime;
- aggiunto il layer persistente `Props`;
- aggiunto a `world_tileset.tres` un vero `TileSetScenesCollectionSource`;
- registrato `tree.tscn` e `rock.tscn` come Scene Tiles;
- sostituito gli oggetti manuali di `main.tscn` con celle Scene Tile;
- aggiornato i test per ispezionare `world.tscn` prima di aggiungerlo allo `SceneTree`.

La nuova soluzione soddisfa meglio la challenge perché la scena sul disco è la fonte del layout. L'editor può visualizzare e modificare la mappa senza avviare il gioco, e ciò che viene salvato è esattamente ciò che viene caricato a runtime.

## Scelte tecniche

Il player resta un `CharacterBody2D`. `try_step()` normalizza la direzione su un solo asse, calcola un target distante esattamente `tile_size` e usa `test_move()` prima di iniziare. La decisione di entrare nella cella deriva quindi dal motore fisico.

Durante un passo i nuovi input vengono ignorati. `move_toward()` produce posizioni intermedie fluide e, all'arrivo, il target viene assegnato esattamente per evitare deriva numerica. `tile_size` e `move_speed` sono proprietà esportate e configurabili dall'Inspector.

Il movimento non è stato riscritto durante il refactoring: sono cambiate soltanto la persistenza e la modalità di authoring del mondo.

## Concetti Godot utilizzati

- **Node**: elemento dell'albero della scena.
- **Scene/PackedScene**: albero salvato e riutilizzabile; player, world, Tree e Rock sono scene separate.
- **CharacterBody2D**: corpo controllato dal gameplay del player.
- **StaticBody2D**: corpo immobile usato dalle scene ostacolo.
- **TileMapLayer**: sistema moderno Godot 4.7.1 per dipingere celle.
- **TileSet**: risorsa condivisa per atlas, collisioni e palette.
- **TileSetScenesCollectionSource**: source che rende PackedScene posizionabili come tile.
- **Signal**: `step_started` e `step_completed` sono disponibili per future animazioni o suoni.

## Test

Ambiente eseguito: **Godot 4.7.1.stable.official.a13da4feb**.

Risultato del refactoring: **60 controlli superati, 0 fallimenti, exit code 0**.

La suite verifica:

- posizioni intermedie del movimento fluido;
- passi esatti verso destra, sinistra, alto e basso;
- allineamento finale e zero deriva dopo venti passi;
- blocco fisico di celle occupate;
- rifiuto di un secondo input durante il movimento;
- 280 celle Ground già serializzate;
- 75 celle Obstacles già serializzate;
- 3 celle Scene Tile già serializzate;
- assenza di script sul nodo World;
- presenza di una `TileSetScenesCollectionSource` con due scene;
- caricamento della main con i tre layer persistenti;
- collisione reale di una wall tile;
- collisione reale della Tree Scene Tile.

L'ispezione delle celle persistenti avviene **prima** di aggiungere `World` allo `SceneTree`: nessun `_ready()` o altro codice runtime può averle create durante quel test.

È stata inoltre eseguita una ricerca su `.gd`, `.tscn` e `.tres`: nel progetto consegnato non rimangono chiamate `set_cell`/`set_cells`, generatori `TileMapLayer`, creazione programmatica del TileSet o istanziazioni runtime usate per costruire il livello statico.

## Verifica finale

### VERIFICATO

- Versione Godot 4.7.1 e parsing delle risorse.
- Celle terreno, muri e props persistenti prima del runtime.
- TileSet `.tres` persistente e associato ai tre layer.
- `TileSetScenesCollectionSource` con `Tree` e `Rock`.
- Scene `.tscn` riutilizzabili con collisioni proprie.
- Collisioni effettive di muro e Tree Scene Tile.
- Movimento, fluidità, allineamento, input durante il passo e assenza di deriva.
- Suite completa: 60/60, exit code 0.

### IMPLEMENTATO MA NON VERIFICATO

- I clic manuali nell'interfaccia grafica dell'editor (selezione della palette, pennello e salvataggio) non sono stati pilotati dalla suite headless. La struttura necessaria è però stata caricata e verificata tramite le API Godot: tre `TileMapLayer`, TileSet associato, celle persistenti e Scene Collection con due elementi.
- La pressione fisica di WASD/frecce non è stata sintetizzata a livello di sistema operativo; `_read_direction()` contiene entrambi i set di tasti e il percorso di movimento invocato è coperto dai test.

### NON COMPLETATO

Nessun requisito noto.

## Problemi incontrati

La conversione iniziale è stata eseguita una sola volta con Godot per ottenere il formato binario `tile_map_data` corretto della versione 4.7.1. Lo strumento monouso non fa parte della consegna finale ed è stato rimosso insieme al vecchio generatore runtime. Un primo avvio nel sandbox non poteva accedere a `user://`; le verifiche finali sono state eseguite con normale accesso al profilo Windows.

## Possibili miglioramenti

Passi successivi naturali sono animazioni direzionali, camera, input buffer, NPC, porte/cambio mappa, erba alta e salvataggio. Non sono stati aggiunti perché fuori dallo scope del refactoring.
