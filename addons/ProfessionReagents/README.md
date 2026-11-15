# Profession Reagents

**Profession Reagents** es un addon gratuito para **World of Warcraft: Forever**. Al pasar el cursor sobre un objeto, muestra qué profesiones lo usan como ingrediente. Así puedes decidir qué materiales guardar o vender, aunque tu personaje no haya aprendido esas profesiones.

## Instalación

1. Cierra el juego si está abierto. Descarga el paquete ZIP y descomprímelo. [Descargar Profession Reagents 1.0.0](https://raw.githubusercontent.com/sebasgrios/profession-util/main/packages/ProfessionReagents/ProfessionReagents-1.0.0.zip)
2. En Battle.net, selecciona **World of Warcraft: Forever**. Haz clic en el engranaje junto a **Jugar** y elige **Mostrar en el Explorador**.
3. Dentro de `_forever_`, abre `Interface` y luego `AddOns`. Copia allí la carpeta `ProfessionReagents` que extrajiste del ZIP.
4. Abre el juego. En la pantalla de selección de personaje, abre la lista de addons y comprueba que **Profession Reagents** esté activado.

## Uso y ajustes

Para probarlo, pasa el cursor sobre una **Mena de cobre**. En español verás **Utilizado en:** y debajo **Minería**.

En **Opciones > Addons > Profession Reagents**, usa **Visible** para mostrar u ocultar la sección «Utilizado en:». Pasa el cursor por encima de cada casilla para ver qué hace. También puedes cambiar los ajustes desde el chat.

El addon detecta automáticamente el idioma de WoW. Incluye alemán, chino simplificado y tradicional, coreano, español de España y Latinoamérica, francés, inglés, italiano, portugués de Brasil y ruso. Es compatible con Forever 1.60.1 (interfaz `16001`).

| Comando | Acción |
| --- | --- |
| `/pr` | Muestra la ayuda |
| `/pr on` / `/pr off` | Habilita o deshabilita el addon |
| `/pr icons` | Alterna los iconos |
| `/pr compact` | Alterna el modo compacto |
| `/pr debug` | Alterna el diagnóstico |
| `/pr status` | Muestra versión, build, base de datos, recuentos y método de tooltip |
| `/pr reset` | Restablece las preferencias |

Las preferencias se guardan para toda la cuenta de este cliente. Los cambios se aplican al volver a abrir o reconstruir el tooltip.

## Datos y validación

El índice contiene **588 materiales** usados por **12 profesiones**. Se generó a partir de 2.517 recetas de LibProfessionDB 1.10.0 para Forever, de las cuales 2.485 tienen ingredientes. Los datos del cliente pueden incluir recetas cuya disponibilidad en un reino o fase todavía está por confirmar. [Fuente, licencia y actualización](docs/DATA.md)

La validación automatizada usa Lua 5.1 y mocks. La matriz de contextos y las pruebas pendientes en una sesión de juego están en el [plan manual](docs/MANUAL-QA.md).

Para validar y empaquetar, instala PowerShell 7, Lua 5.1, Luacheck y StyLua. Ejecuta los siguientes comandos desde la raíz del repositorio.

```powershell
pwsh -File scripts/validate.ps1 -Addon ProfessionReagents -VerifyData
pwsh -File scripts/package.ps1 -Addon ProfessionReagents
pwsh -File scripts/package.ps1 -Addon ProfessionReagents -Verify
```

`-VerifyData` usa los archivos fijados de CurseForge y wago.tools. Sin esa opción, la validación usa los datos incluidos y funciona sin conexión. Los scripts admiten rutas explícitas a `-Lua`, `-Luacheck` y `-StyLua` según corresponda.

El ZIP de GitHub se publica como paquete. La release contiene las notas de versión y el enlace al ZIP. Para CurseForge, usa el ZIP generado en `dist/` y marca **Forever (1.60.1)**. [Última release](https://github.com/sebasgrios/profession-util/releases/latest) · [Texto para CurseForge en inglés y español](docs/CURSEFORGE.md)

El código propio usa la licencia MIT. El paquete incluye el aviso de LibProfessionDB. [Licencia MIT](../../LICENSE) · [Aviso de LibProfessionDB](src/LICENSE-LibProfessionDB.txt) · [Arquitectura y referencias de la API](docs/ARCHITECTURE.md)
