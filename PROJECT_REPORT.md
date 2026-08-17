# PROJECT REPORT — Grid Walk Demo

## Risultato

È stata realizzata una piccola demo giocabile per **Godot 4.7.1 stable** con movimento a griglia in stile RPG classico. Il player si muove di una cella da 32 px per volta, con interpolazione fluida, senza diagonali né deriva. Muri tile-based, alberi e rocce impediscono fisicamente il passaggio.

La mappa usa il sistema moderno di Godot 4.7.1: due nodi `TileMapLayer` condividono un `TileSet`; il layer del terreno usa tile attraversabili e quello degli ostacoli usa tile con poligoni di collisione. `Tree` e `Rock` sono scene riutilizzabili istanziate nella scena principale.

## Come provarlo

1. Estrarre, se necessario, `Godot_v4.7.1-stable_win64.exe.zip`.
2. Aprire Godot e importare `ai_game/project.godot`.
3. Premere **F6/F5**: `scenes/main.tscn` è già configurata come scena principale.
4. Muovere il personaggio con **WASD** oppure con le **frecce direzionali**.
5. Provare a camminare contro il bordo, il muro verticale, un albero o la roccia: il passo viene rifiutato. Il varco nel muro verticale è attraversabile.

Da PowerShell, nella cartella `ai_game`, i test si avviano con:

```powershell
Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/test_runner.gd
```

## Struttura del progetto

```text
ai_game/
├─ project.godot                 configurazione e main scene
├─ assets/tiles/                 semplici texture SVG locali
├─ resources/
│  ├─ world_tileset.tres         TileSet, atlas e collisioni dei muri
│  └─ ui_theme.tres              tema minimale dell'HUD
├─ scenes/
│  ├─ main.tscn                  demo avviabile
│  ├─ player.tscn                CharacterBody2D del giocatore
│  ├─ world.tscn                 Ground + Obstacles TileMapLayer
│  └─ props/{tree,rock}.tscn     scene statiche riutilizzabili
├─ scripts/
│  ├─ player.gd                  input, passi, movimento e collision query
│  └─ world.gd                   layout compatto della demo
└─ tests/test_runner.gd          suite funzionale headless senza addon
```

## Scelte tecniche

### Player e movimento

Il player è un `CharacterBody2D`, il nodo Godot 4 adatto a un corpo controllato dal gioco. `try_step()` normalizza sempre la direzione su un solo asse, calcola un target distante esattamente `tile_size` e usa `test_move()` prima di iniziare. In questo modo la decisione di entrare nella cella deriva dal motore fisico, non da una lista di coordinate bloccate.

Durante un passo i nuovi input vengono ignorati. È la soluzione più semplice e prevedibile per una demo: non sono possibili passi parziali, inversioni a metà cella o diagonali. `move_toward()` produce posizioni intermedie visivamente fluide; all'arrivo viene assegnato il target esatto. `snapped_to_grid()` allinea il punto iniziale al centro delle celle (`16, 48, 80, ...`). `tile_size` e `move_speed` sono proprietà esportate e configurabili dall'Inspector.

### Collisioni

Il `TileSet` possiede un physics layer. Il tile muro contiene un poligono quadrato che occupa la cella intera. Le scene `Tree` e `Rock` hanno come root uno `StaticBody2D` con `CollisionShape2D`. La stessa query `CharacterBody2D.test_move()` blocca quindi uniformemente tile e scene posizionabili.

### Mappa e scene riutilizzabili

`World` contiene `Ground` e `Obstacles`, entrambi `TileMapLayer`, l'equivalente moderno del vecchio nodo `TileMap`. La piccola disposizione dimostrativa è generata da `world.gd` tramite `set_cell()`, così il layout resta leggibile; lo stesso `TileSet` è immediatamente disponibile nell'editor per dipingere o ampliare i layer. Alberi e rocce sono normali `PackedScene` trascinabili e duplicabili nell'editor.

Questa separazione mantiene il progetto piccolo: movimento, mondo e oggetti riutilizzabili hanno responsabilità distinte, senza introdurre sistemi o dipendenze non necessari.

## Godot

- **Node**: elemento base dell'albero della scena; comportamento e composizione nascono dai nodi figli.
- **Scene**: albero di nodi salvato e riutilizzabile. Main, player, world, alberi e rocce sono scene separate.
- **CharacterBody2D**: corpo controllabile del player; espone query di collisione coerenti col motore fisico.
- **Collisioni**: `CollisionShape2D` definisce le forme di player/props; il physics layer del `TileSet` definisce i muri.
- **TileMapLayer**: sistema tile-based moderno usato da Godot 4.7.1. I layer separano terreno e ostacoli.
- **TileSet**: risorsa condivisa che associa texture, coordinate atlas e collisioni alle tile.
- **Scene riutilizzabili**: `tree.tscn` e `rock.tscn` si possono trascinare più volte nel livello.
- **Signal**: `step_started` e `step_completed` sono esposti dal player per future animazioni, suoni o gameplay.

## Test

Ambiente rilevato ed eseguito: **Godot 4.7.1.stable.official.a13da4feb**.

Comando finale eseguito:

```powershell
Godot_v4.7.1-stable_win64_console.exe --headless --path ai_game --script res://tests/test_runner.gd
```

Risultato finale: **55 controlli superati, 0 fallimenti, exit code 0**. La suite verifica:

- presenza di posizioni intermedie durante un passo fluido;
- destra, sinistra, alto e basso, una tile esatta;
- allineamento finale in ogni direzione;
- blocco di una cella occupata e posizione invariata;
- zero deriva dopo venti passi consecutivi;
- rifiuto del secondo input durante un passo;
- creazione del terreno 20×14 e dei muri tramite `TileMapLayer`;
- collisione reale del tile muro del `TileSet`;
- istanze `Tree`/`Rock` e collisione reale dell'albero.

La scena principale è stata inoltre avviata direttamente in headless per 10 frame: **exit code 0 e nessun errore in output**.

## Verifica dei criteri di accettazione

| # | Stato | Evidenza |
|---|---|---|
| 1 | **IMPLEMENTATO** | `_read_direction()` legge WASD e frecce. Non sono stati sintetizzati eventi tastiera del sistema operativo in headless. |
| 2 | **VERIFICATO** | I test nelle quattro direzioni controllano uno spostamento esatto di 32 px. |
| 3 | **VERIFICATO** | Il test campiona una posizione intermedia diversa da partenza e target. |
| 4 | **VERIFICATO** | Allineamento controllato dopo ogni direzione e dopo venti passi. |
| 5 | **VERIFICATO** | Verificati blocker generico, tile muro reale e scena Tree reale. |
| 6 | **VERIFICATO** | La main crea 280 celle Ground e celle Obstacles su `TileMapLayer`. |
| 7 | **VERIFICATO** | Main istanzia `Tree` e `Rock`; verificata anche la collisione Tree. |
| 8 | **VERIFICATO** | `run/main_scene` configurata; avvio diretto headless pulito. |
| 9 | **VERIFICATO** | Suite interna eseguita: 55/55, exit code 0. |
| 10 | **VERIFICATO** | Import, parsing e avvio main completati; avvio finale senza errori. |

**NON COMPLETATO:** nessun requisito. L'unico aspetto non verificato tramite automazione è la pressione fisica dei tasti, mentre il percorso di movimento che tali tasti invocano è coperto dalla suite.

## Problemi incontrati

Il download iniziale era un archivio `.exe.zip`, quindi Godot è stato estratto in una cartella temporanea per i test. Il primo run nel sandbox non poteva scrivere `user://logs` e il binario terminava in modo anomalo; impostando inizialmente un log nella cartella progetto è stato possibile importare gli SVG. La verifica definitiva è stata poi eseguita con accesso normale al profilo Windows: sia la main sia i test sono terminati puliti. Nessun workaround ambientale è richiesto quando il progetto viene aperto normalmente dall'utente.

## Possibili miglioramenti

Passi successivi naturali sarebbero animazioni direzionali, una camera che segue il player, un piccolo input buffer, NPC e interazioni, porte/cambio mappa, erba alta e salvataggio. Non sono stati aggiunti perché fuori dallo scope della challenge.
