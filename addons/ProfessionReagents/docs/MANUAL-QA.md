# Pruebas en WoW: Forever

La matriz se evaluó por lectura del código de interfaz del build **70938**. Cada comprobación visual, de persistencia y de combate sigue pendiente en una sesión del juego. [Blizzard_UIPanels_Game](https://github.com/Gethe/wow-ui-source/tree/bebcb6bf309cf41b41bd74f8ca651e6a105b2676/Interface/AddOns/Blizzard_UIPanels_Game)

## Contextos

Prueba un ingrediente y un objeto de control en cada contexto al que tengas acceso. Comprueba que el recuadro conserve las líneas nativas y que la sección aparezca una sola vez al mover el cursor, reabrir y actualizar el objeto.

| Contexto | Evaluación de la ruta nativa | Prueba manual |
| --- | --- | --- |
| Bolsas | `ContainerFrame` usa `SetBagItem` | Pasa el cursor sobre lino en bolsa unificada e individual |
| Inventario equipado | `PaperDollFrame` Camelot llama a `ItemUtil.DisplayEquipSlotTooltip` | Equipa Cindercloth Cloak (14044) y pasa el cursor por la ranura |
| Banco personal | `BankFrame` Camelot usa `SetBagItem` | Deposita y consulta una barra de cobre en el banco |
| Banco de hermandad | `Blizzard_GuildBankUI` tiene ruta `SetGuildBankItem`. La disponibilidad depende del servidor y del acceso del personaje | Si la interfaz se abre, consulta un ingrediente en una pestaña accesible. Si el banco no está disponible, registra el reino y su modalidad |
| Casa de subastas | Las tarjetas nativas usan `SetHyperlink` o `SetItemKey` | Consulta cobre en la lista de resultados, en el detalle y en la pestaña de venta. Las mascotas enjauladas con tooltip de mascota usan otra ruta |
| Comerciantes | `MerchantFrame` usa `SetMerchantItem` y `SetBuybackItem` | Consulta un vial que venda un NPC y una entrada de recompra |
| Botín | `LootFrame` usa `SetLootItem` y hay un accesor separado para tiradas | Con botín automático desactivado, consulta carne de jabalí y, si aplica, un objeto de tirada |
| Recompensas de misiones | `QuestInfo` usa `SetQuestItem` y `SetQuestLogItem` | Consulta una recompensa que sea ingrediente en el registro y en el diálogo de entrega |
| Enlaces del chat | `ItemRefTooltip` procesa el enlace con `GetHyperlink` | Enlaza el propio lino en un canal privado y abre el enlace. Ciérralo y vuelve a abrirlo |
| Comercio entre jugadores | `TradeFrame` llama a `SetTradePlayerItem` y `SetTradeTargetItem` | Efectúa la comprobación de tooltip en ambos lados de la ventana, sin completar el intercambio |
| Profesiones | `Blizzard_ProfessionsTemplates` usa `SetRecipeReagentItem` y `SetItemByID` | Consulta un ingrediente y un producto que también sea ingrediente. Los tooltips de receta que llegan como hechizos quedan fuera |
| Correo | `MailFrame` usa `SetInboxItem` y `SetSendMailItem` | Consulta una mena adjunta en la bandeja de entrada y en el formulario de envío |
| Comparación | El gestor de comparación llama a `ProcessInfo` con los datos del objeto equipado. Las líneas de diferencias de atributos o controles de Blizzard pueden ir después de la sección | Compara Cindercloth Cloak (14044) con otra capa. Confirma que cada sección identifique el objeto de su propio recuadro y que no se duplique al alternar comparaciones |

Otros paneles con el mismo procesador y tipo de objeto pueden mostrar la sección. Los paneles que presentan una moneda, mascota, hechizo, unidad o texto sin datos de objeto quedan fuera del hook. [Procesador de tooltips](https://github.com/Gethe/wow-ui-source/blob/bebcb6bf309cf41b41bd74f8ca651e6a105b2676/Interface/AddOns/Blizzard_SharedXMLGame/Tooltip/TooltipDataHandler.lua) · [Comparación](https://github.com/Gethe/wow-ui-source/blob/bebcb6bf309cf41b41bd74f8ca651e6a105b2676/Interface/AddOns/Blizzard_SharedXMLGame/Tooltip/TooltipComparisonManager.lua)

## Materiales y expectativas

Estos conjuntos salen del índice generado a partir de LibProfessionDB 1.10.0 para Forever. Se fijan en las pruebas automatizadas por ItemID para detectar cambios en los datos. Los nombres de profesión aquí corresponden a esES.

| Ejemplo | ItemID | Profesiones esperadas |
| --- | ---: | --- |
| Paño de lino | 2589 | Costura, Herrería, Ingeniería, Primeros auxilios |
| Paño de lana | 2592 | Costura, Ingeniería, Primeros auxilios |
| Cuero ligero | 2318 | Costura, Desollar, Herrería, Ingeniería, Peletería |
| Barra de cobre | 2840 | Herrería, Ingeniería, Minería, Peletería |
| Mena de cobre | 2770 | Minería |
| Flor de paz | 2447 | Alquimia, Botánica, Cocina, Primeros auxilios |
| Hojaplata | 765 | Alquimia, Botánica |
| Polvo extraño | 10940 | Encantamiento, Herrería, Peletería |
| Carne de jabalí | 769 | Cocina |
| Pez crudo (Raw Brilliant Smallfish) | 6291 | Cocina, Pesca |
| Pez crudo (Raw Longjaw Mud Snapper) | 6289 | Cocina |
| Malaquita | 774 | Herrería, Ingeniería |
| Pólvora fabricada (Rough Blasting Powder) | 4357 | Ingeniería |
| Capa equipable (Cindercloth Cloak) | 14044 | Peletería |
| Objeto de control (Worn Shortsword) | 25 | Tooltip original |

## Secuencia de aceptación

1. Instala el ZIP y comprueba que **Profession Reagents** aparezca con el icono de paño de lana en la lista de addons. Habilítalo y entra con un personaje sin profesiones aprendidas. Confirma que `/pr status` indique `16001`, método `TooltipDataProcessor.AddTooltipPostCall`, **2.485 de 2.517** recetas, **588** materiales y **12** profesiones.
2. Comprueba la tabla de materiales antes de hablar con un instructor o abrir la ventana de una profesión. Activa `/console scriptErrors 1` durante la prueba para observar errores Lua.
3. Abre **Opciones > Addons > Profession Reagents**. Comprueba que la primera casilla se llame **Visible** y que al pasar el cursor sobre cada casilla se muestre su descripción. Cambia las cuatro casillas y vuelve a abrir el tooltip. Comprueba que los comandos actualicen las mismas opciones y que las casillas reflejen los cambios. Usa los valores predeterminados de la categoría actual. Las listas largas conservan una profesión por línea.
4. Mantén el cursor sobre un objeto pendiente de cargar, si lo encuentras, hasta que aparezcan sus datos. Alterna rápidamente entre dos objetos y reabre varias veces el mismo enlace. Repite con un objeto en combate.
5. Verifica la persistencia de los ajustes tras `/reload` y después de cerrar sesión. Cambia el idioma del cliente y comprueba el orden, el encabezado en ambos modos y las opciones traducidas. Por ejemplo, el lino muestra **Costura** en esES y **Sastrería** en esMX. En ambos el encabezado es **Utilizado en:**.
6. Repite con los addons de bolsas o tooltips que uses normalmente. Anota el build, locale, reino, la ventana, el ItemID y el error Lua cuando corresponda.
