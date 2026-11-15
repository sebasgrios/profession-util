# Contexto y decisiones del proyecto

## Punto de partida

La primera petición fue crear un addon completo e instalable para WoW: Forever que muestre qué profesiones usan un objeto como ingrediente. La especificación definió **Profession Reagents** como nombre comercial y `ProfessionReagents` como nombre interno. El repositorio `profession-util` se organizó después para poder incorporar otros addons de profesiones. Profession Reagents es el único addon implementado.

El cliente objetivo de Profession Reagents es **World of Warcraft: Forever 1.60.1**, interfaz `16001`, tipo de juego `camelot`. La implementación y las decisiones de API se verificaron contra el build `1.60.1.70938`. Cada addon futuro debe documentar su propia compatibilidad. [Evidencia del cliente y API](../addons/ProfessionReagents/docs/ARCHITECTURE.md)

## Comportamiento que pidió el usuario

- Buscar por `ItemID` y mostrar las profesiones que consumen el objeto en alguna receta. Esto incluye comida, pescado y componentes fabricados cuando el índice los relaciona con una receta. La profesión que obtiene un objeto solo se muestra si alguna de sus recetas también lo consume.
- Entregar datos utilizables desde la primera instalación. El alcance incluye recetas de profesiones aprendidas o desconocidas, y de instructores, libros, reputación, especializaciones y Forever cuando aparecen en la fuente. La disponibilidad actual en los reinos puede diferir del catálogo del cliente.
- Ampliar el tooltip nativo de objeto con una sección discreta, nombres blancos, encabezado dorado e iconos oficiales. Cada profesión se muestra una vez y en orden del idioma. Cuando el objeto carece de relaciones, el tooltip conserva sus líneas originales. La lista compacta cabe en una línea cuando su longitud lo permite.
- Usar **«Utilizado en:»** en esES y esMX, en ambos modos, con su equivalente traducido en los demás idiomas. Detectar el idioma mediante `GetLocale()`. El addon incluye alemán, chino simplificado y tradicional, coreano, ambos españoles, francés, inglés, italiano, portugués de Brasil y ruso. `enGB` y los idiomas sin traducción usan `enUS`.
- Mostrar el icono de **paño de lana** (`INV_Fabric_Wool_01`) en la lista de addons. Este icono es parte de los metadatos del TOC. Los iconos de profesión del tooltip vienen de `SkillLine`.
- Permitir cambiar las cuatro preferencias desde **Opciones > Addons > Profession Reagents** o mediante `/pr`. Las casillas y los comandos comparten `ProfessionReagentsDB`. De fábrica, el addon y los iconos están activados, y el modo compacto y la depuración están desactivados.
- Llamar **Visible** a la primera casilla en español y mostrar al pasar el cursor una descripción localizada del efecto de cada opción.
- Mantener una introducción breve sobre la utilidad del addon y colocar la instalación a continuación. El usuario instala con Battle.net, el explorador de archivos y la lista de addons. Los pasos de instalación se mantienen libres de comandos.

El alcance de 1.0.0 es identificar profesiones en el tooltip. Los precios, la rentabilidad, el farmeo, las listas de recetas, la gestión de otros personajes, la telemetría y los servicios de red quedaron fuera de esa versión.

## Datos y código de 1.0.0

El idioma y la disponibilidad en un reino son independientes de la relación entre ingredientes y recetas. El índice generado contiene **588 ItemID**, **12 profesiones** y **2.485 recetas con ingredientes** de **2.517 entradas** de LibProfessionDB 1.10.0. Se usa su edición Forever para generar el índice, y el ZIP distribuye el resultado y el aviso MIT. Las fuentes, comprobaciones y hashes están documentados junto al addon. [Origen y actualización de datos](../addons/ProfessionReagents/docs/DATA.md)

El runtime usa el namespace privado del addon y prepara el índice una vez. El camino principal es `TooltipDataProcessor.AddTooltipPostCall` para `Enum.TooltipDataType.Item`. `OnTooltipCleared` permite añadir de nuevo la sección cuando Blizzard reconstruye el mismo tooltip. El código omite tooltips prohibidos, valores secretos y entradas sin un objeto identificable. [Módulos, hooks y fuentes de la API](../addons/ProfessionReagents/docs/ARCHITECTURE.md)

El apartado de configuración usa las casillas nativas de Blizzard y conserva `/pr`, `/pr on`, `/pr off`, `/pr icons`, `/pr compact`, `/pr debug`, `/pr status` y `/pr reset`. Para instalar, el ZIP contiene `ProfessionReagents/ProfessionReagents.toc` y se extrae en `World of Warcraft/_forever_/Interface/AddOns/`. El código propio usa MIT. [Guía para jugadores](../addons/ProfessionReagents/README.md)

## Validación y pendientes

Se comprobó el build mediante el ejecutable de la instalación local y se leyeron los archivos de interfaz de Blizzard para evaluar los contextos de tooltip. La suite con mocks cubre el índice, los idiomas, ambos modos, las preferencias nativas, los comandos y el ciclo de vida del tooltip. El empaquetado verifica los archivos y sus hashes. Las releases de GitHub y CurseForge se dejaron preparadas mediante scripts y textos de publicación.

Sigue pendiente una prueba en una sesión real de Forever. El plan cubre la aparición del icono, el panel de opciones, la persistencia, el comportamiento en combate y los contextos de objetos. En comparaciones, Blizzard puede añadir las líneas de diferencias de atributos después de la sección del addon. La disponibilidad del banco de hermandad depende del reino y de los permisos del personaje. [Matriz y plan manual](../addons/ProfessionReagents/docs/MANUAL-QA.md)

Para retomar el proyecto, usa el README del addon para su comportamiento visible, la arquitectura para sus puntos de entrada y el manifiesto fijado para reproducir el índice. Cuando el cliente o los datos cambien, vuelve a verificar el build, el TOC y las APIs que usa el addon. [Manifiesto de datos](../addons/ProfessionReagents/scripts/data-source.json) · [Flujo de desarrollo](ARCHITECTURE.md)
