-- Zenith Mobile installer/updater for OTClient Redemption (Android/Desktop).
-- Loaded by the one-line console bootstrap from a public Git repository.

local BOT_NAME = "Zenith Mobile"
local BOT_ROOT = "/bot/" .. BOT_NAME
local PACKAGE_NAME = "ZenithMobile.zip"
local MANIFEST_FILE = BOT_ROOT .. "/.zenith_managed.json"
local PROTECTED_PREFIXES = {
  "storage/",
  "cavebot_configs/",
  "targetbot_configs/",
  "vBot_configs/",
}

local baseUrl = "https://raw.githubusercontent.com/CaduGTXD/Zenith-Mobile/main/"

local function log(text)
  print("[Zenith Mobile] " .. tostring(text))
end

local function isProtected(relativePath)
  for _, prefix in ipairs(PROTECTED_PREFIXES) do
    if relativePath:sub(1, #prefix) == prefix then
      return true
    end
  end
  return false
end

local function normalizeRelativePath(path)
  path = tostring(path or ""):gsub("\\", "/"):gsub("^/+", "")

  -- Accept both a rootless package and archives wrapped in a folder.
  local marker = BOT_NAME .. "/"
  local markerPos = path:find(marker, 1, true)
  if markerPos then
    path = path:sub(markerPos + #marker)
  end

  path = path:gsub("^%./", "")
  if path == "" or path:find("..", 1, true) then
    return nil
  end
  return path
end

local function ensureDirectory(path)
  local current = ""
  for part in path:gmatch("[^/]+") do
    current = current .. "/" .. part
    if not g_resources.directoryExists(current) then
      g_resources.makeDir(current)
    end
    if not g_resources.directoryExists(current) then
      error("Nao foi possivel criar o diretorio: " .. current)
    end
  end
end

local function ensureParent(filePath)
  local parent = filePath:match("^(.*)/[^/]+$")
  if parent and parent ~= "" then
    ensureDirectory(parent)
  end
end

local function readOldManifest()
  if not g_resources.fileExists(MANIFEST_FILE) then
    return {}
  end

  local ok, decoded = pcall(function()
    return json.decode(g_resources.readFileContents(MANIFEST_FILE))
  end)
  if not ok or type(decoded) ~= "table" then
    return {}
  end
  return decoded
end

local function removeOldManagedFiles()
  for _, relativePath in ipairs(readOldManifest()) do
    if type(relativePath) == "string" and not isProtected(relativePath) then
      local fullPath = BOT_ROOT .. "/" .. relativePath
      if g_resources.fileExists(fullPath) then
        g_resources.deleteFile(fullPath)
      end
    end
  end
end

local function writePackage(files)
  if type(files) ~= "table" then
    error("O pacote baixado nao e um arquivo ZIP valido.")
  end

  local normalized = {}
  local hasLoader = false

  for archivePath, contents in pairs(files) do
    local relativePath = normalizeRelativePath(archivePath)
    if relativePath and type(contents) == "string" then
      normalized[relativePath] = contents
      if relativePath == "_Loader.lua" then
        hasLoader = true
      end
    end
  end

  if not hasLoader then
    error("_Loader.lua nao foi encontrado no pacote Zenith Mobile.")
  end

  ensureDirectory(BOT_ROOT)
  removeOldManagedFiles()

  local managed = {}
  for relativePath, contents in pairs(normalized) do
    local fullPath = BOT_ROOT .. "/" .. relativePath
    local preserveExisting = isProtected(relativePath) and g_resources.fileExists(fullPath)

    if not preserveExisting then
      ensureParent(fullPath)
      g_resources.writeFileContents(fullPath, contents)
      if not g_resources.fileExists(fullPath) then
        error("Falha ao gravar: " .. fullPath)
      end
    end

    if not isProtected(relativePath) then
      table.insert(managed, relativePath)
    end
  end

  table.sort(managed)
  g_resources.writeFileContents(MANIFEST_FILE, json.encode(managed, 2))
end

local function activateBot()
  if not g_game or not g_game.isOnline or not g_game.isOnline() then
    log("Instalado. Entre no personagem e ative o bot Zenith Mobile.")
    return
  end

  local settings = g_settings.getNode("bot") or {}
  local index = g_game.getCharacterName() .. "_" .. g_game.getClientVersion()
  settings[index] = settings[index] or {}
  settings[index].config = BOT_NAME
  settings[index].enabled = true
  g_settings.setNode("bot", settings)
  g_settings.save()

  scheduleEvent(function()
    if modules.game_bot and modules.game_bot.refresh then
      modules.game_bot.refresh()
      log("Instalado, atualizado e iniciado com sucesso.")
    else
      log("Instalado. Reabra o cliente para iniciar o Zenith Mobile.")
    end
  end, 100)
end

if not HTTP or not HTTP.download then
  error("Este cliente nao possui HTTP.download.")
end
if not g_resources or not g_resources.decompressArchive then
  error("Este cliente nao possui g_resources.decompressArchive.")
end

local packageUrl = baseUrl .. PACKAGE_NAME .. "?t=" .. tostring(g_clock.millis())
local previousTimeout = HTTP.timeout
HTTP.timeout = math.max(tonumber(HTTP.timeout) or 2, 30)

log("Baixando o pacote...")
HTTP.download(packageUrl, "zenith_mobile_package.zip", function(path, checksum, err)
  if err then
    log("Falha no download: " .. tostring(err))
    return
  end

  local archivePath = "/downloads/" .. tostring(path)
  local ok, result = pcall(function()
    local files = g_resources.decompressArchive(archivePath)
    writePackage(files)
    activateBot()
  end)

  if not ok then
    log("Falha na instalacao: " .. tostring(result))
  end
end)

HTTP.timeout = previousTimeout
