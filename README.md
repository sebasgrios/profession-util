# Profession Util

Profession Util es un repositorio de addons para las profesiones de World of Warcraft. El primero, **Profession Reagents**, muestra qué profesiones usan un objeto como ingrediente cuando pasas el cursor sobre él. Así puedes decidir qué materiales guardar o vender, aunque tu personaje no haya aprendido esas profesiones.

## Instalar Profession Reagents

1. Cierra el juego si está abierto. Descarga el ZIP de **Assets** y descomprímelo. [Última release de Profession Reagents](https://github.com/sebasgrios/profession-util/releases/latest)
2. En Battle.net, selecciona **World of Warcraft: Forever**. En el engranaje junto a **Jugar**, elige **Mostrar en el Explorador**.
3. Abre `_forever_`, entra en `Interface` y luego en `AddOns`. Copia allí la carpeta `ProfessionReagents` que extrajiste del ZIP.
4. Abre el juego y activa **Profession Reagents** en la lista de addons de la pantalla de selección de personaje.

## Addons

| Addon | Función | Cliente |
| --- | --- | --- |
| [Profession Reagents](addons/ProfessionReagents/README.md) | Consulta las profesiones que usan un objeto y ajusta su presentación desde Opciones > Addons | WoW: Forever 1.60.1 (`16001`) |

## Desarrollo

Cada addon tiene su propio código instalable, documentación, versión y pruebas. Los scripts de la raíz validan todos los addons o trabajan con uno de ellos mediante `-Addon`. Los ZIP se generan en `dist/`. [Estructura y flujo de trabajo](docs/ARCHITECTURE.md)

Si retomas el repositorio por primera vez, empieza por la guía de agentes y el contexto del proyecto. [Guía para agentes](AGENTS.md) · [Contexto y decisiones del proyecto](docs/PROJECT-CONTEXT.md)

El código propio usa la licencia MIT. [Licencia](LICENSE)
