local _, addon = ...

addon.locales.esMX = setmetatable({
    reset = "Se restableció la configuración predeterminada.",
}, { __index = addon.locales.esES })
