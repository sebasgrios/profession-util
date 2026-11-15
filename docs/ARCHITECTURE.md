# Estructura y flujo de trabajo

Profession Util agrupa proyectos de addons en un solo repositorio. Cada addon mantiene su identidad, sus requisitos del cliente y su ciclo de distribución. Las herramientas de la raíz usan esa estructura para localizar el código y generar los ZIP.

```text
addons/
  ProfessionReagents/
    src/
      ProfessionReagents.toc
      Core/
      Config/
      Database/
      Locales/
      Services/
      UI/
    scripts/        Generación y manifiesto de datos de este addon
    tests/          Pruebas con Lua 5.1
    docs/           Arquitectura, datos, validación manual y publicación
    README.md
    CHANGELOG.md
docs/               Arquitectura del repositorio y contexto de trabajo
scripts/            Validación y empaquetado
dist/               ZIP generados, fuera de Git
.cache/             Herramientas locales y descargas verificadas, fuera de Git
```

## Validar y empaquetar

Para desarrollar, usa PowerShell 7+, Lua 5.1, Luacheck y StyLua. Los jugadores reciben un ZIP listo para extraer.

```powershell
# Validar todos los addons registrados en addons/
pwsh -File scripts/validate.ps1

# Validar un addon y volver a generar sus datos para compararlos
pwsh -File scripts/validate.ps1 -Addon ProfessionReagents -VerifyData

# Crear el ZIP y comprobar sus entradas y hashes
pwsh -File scripts/package.ps1 -Addon ProfessionReagents
pwsh -File scripts/package.ps1 -Addon ProfessionReagents -Verify
```

El validador ejecuta `tests/run.lua` cuando existe y le pasa la ruta de `src/` como primer argumento. Aplica Luacheck y StyLua al proyecto. Con `-VerifyData`, ejecuta `scripts/update-data.ps1` del addon si está presente y le pasa `-Lua` y `-Verify`. Las herramientas se pueden indicar por ruta con `-Lua`, `-Luacheck` y `-StyLua`.

El empaquetador toma la versión de `<NombreInterno>.toc` y verifica las rutas de los archivos Lua o XML que declara. Crea `dist/<NombreInterno>-<Versión>.zip` con una sola carpeta superior `<NombreInterno>/`. Incluye todo `src/`, incluidos los recursos referenciados desde Lua o XML. Si el addon lleva `src/LICENSE.txt`, se incluye ese archivo. Para los demás, se incluye la licencia MIT de la raíz como `LICENSE.txt`. Los avisos de terceros que deban distribuirse van en `src/`.

`scripts/package.ps1` sin `-Addon` empaqueta Profession Reagents. `scripts/update-data.ps1` en la raíz conserva el acceso al generador de Profession Reagents. Las fuentes descargadas de ese addon están en `.cache/ProfessionReagents/`.

## Añadir un addon

1. Elige un nombre interno estable y crea `addons/<NombreInterno>/src/<NombreInterno>.toc`. Define título, versión `major.minor.patch`, nivel de interfaz y archivos de carga según el cliente objetivo. Coordina el nombre de la carpeta instalada, del TOC y del namespace. Da nombres propios a SavedVariables y comandos para evitar colisiones.
2. Coloca el código y los recursos de ejecución en `src/`. Usa la API del cliente objetivo y documenta cualquier dependencia. Los addons pueden evolucionar de forma independiente. Si una pieza de código pasa a compartirse, decide cómo la recibirá el jugador cuando solo instale uno de los ZIP.
3. Añade el README y registra el addon en el índice de la raíz. Documenta fuentes y licencias aplicables, verificaciones automatizadas y pasos manuales de ese addon.
4. Ejecuta `validate.ps1 -Addon <NombreInterno>` y genera y verifica el ZIP con `package.ps1`. Comprueba en su cliente objetivo los comportamientos que dependan de la interfaz.

Para preparar una publicación, usa el ZIP y el changelog del addon seleccionado. Profession Reagents cuenta con texto para la ficha de CurseForge en inglés y español. [Descripción para CurseForge](../addons/ProfessionReagents/docs/CURSEFORGE.md)
