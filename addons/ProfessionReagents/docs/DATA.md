# Datos de recetas de Forever

El ZIP de Profession Reagents incluye el índice derivado de **LibProfessionDB 1.10.0**, publicado por Pimptasty. La versión analizada tiene su propio `ProfessionDB_Camelot.toc` con `Interface: 16001` y carga `Data/Forever/_core`, generado con los archivos del producto `wowf` para el build público **1.60.1.70938**. El archivo `LICENSE` del ZIP declara MIT y su aviso se conserva como `LICENSE-LibProfessionDB.txt`. [Publicación de LibProfessionDB](https://www.curseforge.com/wow/addons/libprofessiondb/files/9619259)

El generador carga el `LibStub.lua`, `LibProfessionDB-1.0.lua` y los doce archivos de profesiones `LoadCore` de esa publicación. Comprueba `GetGameVersion() == "Forever"`, `IsReady()` y `Count()`. `Iterate()` devuelve el SkillLineID, el SpellID de la receta y su entrada. `GetReagents(professionID, recipeID)` devuelve el mapa `ItemID → cantidad`. El generador lee esas tablas y crea su propio mapa de materiales. La librería, el addon anfitrión y sus dependencias (Ace3 y VersionCheck) quedan fuera del proceso de carga en el juego.

Se incluyeron **2.485 recetas con ingredientes** de las **2.517 entradas** de la fuente. Las otras 32 carecen de ingredientes indexables. Resultaron **588 ItemID**, **12 profesiones** y **99 conjuntos distintos** de profesiones. Las doce profesiones se verificaron por SkillLineID, incluidas **Botánica / Herboristería** (182), **Desollar / Desuello** (393) y **Pesca** (356). Por ejemplo, la receta de Pesca 1229745 consume el ItemID 6291. Las relaciones de recolección y los productos de receta quedan fuera del índice salvo que el mismo objeto aparezca como ingrediente en otra receta.

Los nombres de profesión y los iconos provienen de `DisplayName_lang` y `SpellIconFileID` de la tabla `SkillLine` del mismo build. La exportación `enGB` coincide con `enUS`. La exportación `itIT` de Forever devuelve nombres ingleses en ese build, así que para los nombres italianos se usa el glosario oficial de Blizzard. [SkillLine](https://wago.tools/db2/SkillLine?build=1.60.1.70938) · [Guía oficial de WoW en italiano](https://worldofwarcraft.blizzard.com/it-it/news/23090134/manuale-base-di-wow-classic-per-nuovi-giocatori)

## Disponibilidad en los reinos

La inclusión de una receta indica que LibProfessionDB la extrajo de los datos de Forever. El conjunto cubre las recetas de instructores, libros, reputación y especializaciones presentes en la fuente, sin consultar lo aprendido por el personaje. No se comprobó individualmente que cada receta pueda conseguirse actualmente en los reinos. El servidor puede restringir disponibilidad por fase, facción, especialización, reputación o reglas del reino.

LibProfessionDB documenta observaciones directas de instructores y de vendedores de Favor del mercader de la Alianza. Cuando faltan datos de Forever, su biblioteca puede marcar como prestados de Vanilla algunos requisitos, fuentes e indicadores de recetas nunca implementadas. El índice usa únicamente los ingredientes de `Data/Forever/_core`, por lo que esas marcas y fuentes de adquisición no intervienen. [Notas de la versión 1.10.0](https://www.curseforge.com/wow/addons/libprofessiondb/files/9619259)

## Actualizar el índice

1. Revisa la licencia y los archivos de una nueva publicación oficial de LibProfessionDB con datos de Forever. Actualiza el manifiesto con la publicación, el build, el recuento, el catálogo de profesiones y los SHA-256. Revisa la correspondencia de `LoadCore` y `GetReagents` si cambió la API de la librería. [Manifiesto de datos](../scripts/data-source.json)
2. Desde la raíz del repositorio, ejecuta `pwsh -File addons/ProfessionReagents/scripts/update-data.ps1` con Lua 5.1 en PATH. El script comprueba los hashes, usa `.cache/ProfessionReagents/`, lee la edición Camelot y escribe el índice y el aviso de licencia en `addons/ProfessionReagents/src/`.
3. Revisa el diff del índice y actualiza las pruebas y la documentación según la fuente. Ejecuta `pwsh -File scripts/validate.ps1 -Addon ProfessionReagents -VerifyData`. `-VerifyData` regenera los ficheros y compara sus contenidos con los del repositorio.
