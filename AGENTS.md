# Guía para trabajar en Profession Util

El repositorio está preparado para alojar varios addons relacionados con profesiones de World of Warcraft. El primer proyecto es **Profession Reagents**. Lee el contexto para conocer las decisiones del usuario y el estado real de las pruebas. [Contexto del proyecto](docs/PROJECT-CONTEXT.md) · [Estructura del repositorio](docs/ARCHITECTURE.md)

- Un addon vive en `addons/<NombreInterno>/`. Su carpeta `src/` contiene el TOC y los archivos que se instalan. Consulta el README y los documentos de ese addon antes de cambiar su comportamiento. [Profession Reagents](addons/ProfessionReagents/README.md)
- Mantén las pruebas, las herramientas de generación y los documentos junto al addon que los usa. Usa `scripts/` en la raíz para validación y empaquetado compartidos.
- Para tocar recetas, traducciones de profesiones o APIs, consulta las fuentes del cliente correspondiente. En Profession Reagents, el índice de Forever es generado. Actualiza el manifiesto o el generador si cambia la fuente. [Datos](addons/ProfessionReagents/docs/DATA.md) · [API y arquitectura](addons/ProfessionReagents/docs/ARCHITECTURE.md)
- La instalación para jugadores se explica en pasos de interfaz y archivos. Los comandos de desarrollo van en su propia sección. Usa la matriz manual para verificar la experiencia en el juego y distingue esos resultados de las pruebas con mocks. [Pruebas en Forever](addons/ProfessionReagents/docs/MANUAL-QA.md)

Ejecuta estos comandos desde la raíz con PowerShell 7+, Lua 5.1, Luacheck y StyLua disponibles.

```powershell
pwsh -File scripts/validate.ps1 -Addon ProfessionReagents -VerifyData
pwsh -File scripts/package.ps1 -Addon ProfessionReagents
pwsh -File scripts/package.ps1 -Addon ProfessionReagents -Verify
```

`-VerifyData` usa las fuentes fijadas del addon. Para validar el código con el índice que ya está en el repositorio, ejecuta `validate.ps1` sin esa opción.
