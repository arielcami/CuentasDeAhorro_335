local inter = "|TInterface\\Icons\\%s:%d:%d:%d|t";
local icons = {
	"achievement_boss_cthun",      		-- 1
	"spell_magic_polymorphchicken", 	-- 2
	"inv_misc_coin_01",            		-- 3
	"inv_gauntlets_24",            		-- 4
	"inv_misc_note_05",            		-- 5
	"inv_enchant_formulagood_01",  		-- 6
	"spell_shadow_sealofkings",    		-- 7
	"spell_shadow_sacrificialshield", 	-- 8
	"inv_misc_coin_02",            		-- 9
	"inv_misc_groupneedmore",      		-- 10
	"inv_letter_15",               		-- 11
	"inv_misc_questionmark",       		-- 12
	"inv_misc_key_12",             		-- 13
	"ability_druid_nourish",       		-- 14
}

-- Formatear Iconos --
local ic = function(selection)
	return string.format(inter, icons[selection], 45, 45, -22)
end

-- Añadir Menús --
local function addOption(txt, send, int, box, boxTxt, obj)
	if (box == nil) and (boxTxt == nil) then
		obj:GossipMenuAddItem(0, txt, send, int)
		return
	else
		obj:GossipMenuAddItem(0, txt, send, int, box, boxTxt)
	end
end

-- Enviar Mensajes --
local function msg(int, p, txt)
	local raw = (int == 1) and "|cff00ff00" or "|cffff0000"
	p:SendBroadcastMessage(raw .. txt)
end

-- Añadir Comas a Números --
local function addCommaToNumber(number)
	local f, k = number, 0;
	while true do
		f, k = string.gsub(f, "^(-?%d+)(%d%d%d)", '%1,%2')
		if (k == 0) then
			break
		end
	end
	return f
end

-- Filtrar Strings de Entrada --
local function scapeCharactersFoundIn(inputString)
	local allowedCharacters = { "'", "`", '"', '\\', ";", "/", "~", "(", ")", ' ', "<", ">", "%", "&", "|", "*", "?", "#" }

	for i = 1, #inputString do
		local character = inputString:sub(i, i)

		for _, allowedChar in ipairs(allowedCharacters) do
			if character == allowedChar then
				return true
			end
		end
	end
	return false
end

-- Asegurar parseo de números de entrada --
local safeConvertToNumber = function(input_message)
	local isSafe = false
	local convertAttepmt = tonumber(input_message)
	if convertAttepmt then
		isSafe = true
	else
		isSafe = false
	end
	return isSafe
end

-- => Booleano para indicar números positivos --
local amountIsPositiveAndInteger = function(amount)
	return (amount >= 1) and true or false
end

--// -----------------------------------------------------------------------------------------------------------------
local npcId = 60003
local beneficiaryName = nil
local beneficiaryGuid = nil
local passwordForThisIteration = nil

local function on_hello(e, P, Npc)
	local query = CharDBQuery("SELECT `has_account` FROM `atm` WHERE `player_guid` = " .. P:GetGUIDLow())
	local playerHasAccount = (query:GetUInt8(0) == 1) and true or false

	P:GossipClearMenu()

	if playerHasAccount then
		addOption(ic(1) .. "Ingresar a mi cuenta", 1, 0, true, "Ingresa tu contraseña", P)
		addOption(ic(2) .. "Olvidé mi contraseña", 124, 124, false, "Tienes que responder tu pregunta de seguridad.", P)
	else
		addOption(ic(10) .. "Abrir una cuenta de ahorros.", 2, 0, true, "Añade una pregunta de seguridad para tu cuenta.",
			P)
	end
	P:GossipSendMenu(1, Npc)
end


local function on_menu_click(e, P, Npc, Send, Int, code)
	local guid, name = P:GetGUIDLow(), P:GetName()

	--// OLVIDÉ MI CONTRASEÑA //--
	if (Send == 124 and Int == 124) then
		local query = "SELECT `secret_question` FROM `atm` WHERE `player_guid` = " .. guid
		local Q = CharDBQuery(query)
		local ans = Q:GetString(0)
		P:GossipClearMenu()
		P:GossipMenuAddItem(0, ic(12) .. "Respode: |cff0049b0" .. ans, 151, 150, true, "Escribe la respuesta")
		P:GossipSendMenu(1, Npc)
	end
	if (Send + Int == 301) then
		local query = "SELECT `secret_answer` FROM `atm` WHERE `player_guid` = " .. guid
		local Q = CharDBQuery(query)
		local ans_from_db = string.lower(Q:GetString(0))
		local lower_code = string.lower(code)

		if (ans_from_db == lower_code) then
			P:GossipClearMenu()
			msg(1, P, "¡Respuesta correcta!")
			addOption(ic(14) .. "Crear nueva contraseña", 4, 0, true, "Escribe tu contraseña nueva", P)
			P:GossipSendMenu(1, Npc)
		else
			msg(2, P, "Respuesta incorrecta...")
			P:GossipComplete()
		end
	end

	--// CREACIÓN DE CUENTAS //--
	if (Send == 2) then
		local raw = "UPDATE `atm` SET `secret_question` = '%s' WHERE `player_guid` = %d"
		CharDBExecute(string.format(raw, code, guid))
		P:GossipClearMenu()
		addOption(ic(12) .. "Responder: |cff002aff" .. code, 3, 0, true, "Ahora escribe la respuesta a esa pregunta", P)
		P:GossipSendMenu(1, Npc)
	end
	if (Send == 3) then
		local raw = "UPDATE `atm` SET `secret_answer` = '%s' WHERE `player_guid` = %d"
		CharDBExecute(string.format(raw, code, guid))
		msg(1, P, "¡Listo!")
		msg(1, P, "La respuesta es: " .. code)
		msg(1, P, "Guárdala y no la compartas.")
		P:GossipClearMenu()
		addOption(ic(13) .. "Crear una contraseña", 4, 0, true, "Escribe tu contraseña", P)
		P:GossipSendMenu(1, Npc)
	end
	if (Send == 4) then
		if not scapeCharactersFoundIn(code) then
			local rawQuery =
			"UPDATE `atm` SET `has_account` = 1, `player_name` = '%s', `player_password` = '%s' WHERE `player_guid` = %d"
			CharDBExecute(string.format(rawQuery, name, code, guid))
			msg(1, P, "¡Contraseña creada!")
			msg(1, P, "Contraseña: |cffffffff" .. code)
		else
			P:SendBroadcastMessage("|cffff0000Esa contraseña contiene caracteres no permitidos.")
		end
		P:GossipComplete()
	end

	--// LOGIN CON UNA CUENTA CREADA - MENÚ //--
	if (Send == 1) then
		local rawQuery = string.format("SELECT `player_password` FROM `atm` WHERE `player_guid` = %d", guid)
		local getPassFromDB = CharDBQuery(rawQuery)
		local savedPassword = getPassFromDB:GetString(0)

		if (code == savedPassword) then
			P:GossipClearMenu()
			if not passwordForThisIteration then
				msg(1, P, "¡Bienvenido a tu cuenta, " .. name .. "!")
			end
			passwordForThisIteration = code;
			addOption(ic(3) .. "Depositar oro", 0, 1, true, "Escribe la cantidad que quieres depositar.", P)
			addOption(ic(4) .. "Retirar oro", 0, 2, true, "Escribe la cantidad que vas a retirar.", P)
			addOption(ic(5) .. "Consultar balance", 0, 3, nil, nil, P)
			addOption(ic(6) .. "Transferir oro a jugador", 0, 4, true, "Ingresa el nombre del beneficiario", P)
			addOption(ic(7) .. "Cambiar mi contraseña", 0, 5, true, "Ingresa tu contraseña actual", P)
			addOption(ic(8) .. "Cerrar mi cuenta", 999, 999, nil, nil, P)
			P:GossipSendMenu(1, Npc)
		else
			msg(2, P, "ERROR: Contraseña incorrecta.")
			P:GossipComplete()
		end
	end

	--// DEPOSITAR ORO //--
	if (Int == 1) then
		if safeConvertToNumber(code) then
			local str2Number = tonumber(code)
			local moneyToBeDeposited = math.floor(str2Number)
			local playerGold = math.floor(P:GetCoinage() / 10000)

			if amountIsPositiveAndInteger(moneyToBeDeposited) then
				if moneyToBeDeposited > playerGold then
					msg(2, P, "ERROR: No tienes esa cantidad de oro. Intenta otra vez.")
				else
					local preparedQuery = string.format("UPDATE `atm` SET `gold` = `gold` + %d WHERE `player_guid` = %d",
						moneyToBeDeposited, guid)
					CharDBExecute(preparedQuery)
					P:ModifyMoney(-moneyToBeDeposited * 10000)
					msg(1, P, "¡Depósito realizado!")
				end
			else
				msg(2, P, "ERROR: Ingresa solo números enteros positivos.")
			end
		else
			msg(2, P, "ERROR: Ingresa un número entero positivo.")
		end
		on_menu_click(e, P, Npc, 1, 0, passwordForThisIteration)
	end

	--// RETIRAR ORO //--
	if (Int == 2) then
		if safeConvertToNumber(code) then
			local rawQuery = string.format("SELECT `gold` FROM `atm` WHERE `player_guid` = %d", guid)
			local savedGold = CharDBQuery(rawQuery):GetUInt32(0)
			local moneyToWithdraw = math.floor(tonumber(code))
			local playerCurrentGold = math.floor(P:GetCoinage() / 10000)

			if amountIsPositiveAndInteger(moneyToWithdraw) then
				if (moneyToWithdraw > savedGold) then
					P:SendBroadcastMessage("|cffff0000ERROR: No tienes esa cantidad en tus ahorros.")
				else
					if (moneyToWithdraw + playerCurrentGold > 214000) then
						P:SendBroadcastMessage(
							"|cffff0000ERROR: Si realizas este retiro superarás los 214,000 de oro, esto puede hacer que pierdas todo tu dinero.")
						on_menu_click(e, P, Npc, 1, 0, passwordForThisIteration)
						return
					end
					local toCopper = moneyToWithdraw * 10000
					local updateAnt = string.format("UPDATE `atm` SET `gold` = `gold` - %d WHERE `player_guid` = %d",
						moneyToWithdraw, guid)
					CharDBExecute(updateAnt)
					P:ModifyMoney(toCopper)
					P:SendBroadcastMessage("|cff00ff00¡Retiro realizado!")
				end
			else
				msg(2, P, "ERROR: Ingresa solo números enteros positivos.")
			end
		else
			P:SendBroadcastMessage("|cffff0000ERROR: Ingresa un número entero positivo.")
		end
		on_menu_click(e, P, Npc, 1, 0, passwordForThisIteration)
	end

	--// CONSULTAR BALANCE --//
	if (Int == 3) then
		local rawQuery = string.format("SELECT `gold` FROM `atm` WHERE `player_guid` = %d", guid)
		local savedGold = CharDBQuery(rawQuery):GetUInt32(0)
		local balance = addCommaToNumber(tostring(savedGold))
		P:SendBroadcastMessage("|cff00ff00Balance disponible: |cffff9900$ " .. balance .. " G")
		on_menu_click(e, P, Npc, 1, 0, passwordForThisIteration)
	end

	--// TRASFERIR ORO A OTRO JUGADOR //--
	if (Int == 4) then
		if not scapeCharactersFoundIn(code) then
			beneficiaryName = code
			local rawQuery = "SELECT `has_account`, `player_guid` FROM `atm` WHERE `player_name` = '%s'"
			local beneficiaryHasAccount; -- Bool
			local query = CharDBQuery(string.format(rawQuery, code))

			if query then
				beneficiaryHasAccount = (query:GetUInt8(0) == 1) and true or false
			else
				beneficiaryHasAccount = false
			end

			local nameIsDiffrentThanSender = (string.lower(code) ~= string.lower(P:GetName())) and true or false

			if not nameIsDiffrentThanSender then
				msg(2, P, "ERROR: No puedes enviarte dinero a ti mismo.")
				on_menu_click(e, P, Npc, 1, 0, passwordForThisIteration)
				return
			end

			if (beneficiaryHasAccount) and (nameIsDiffrentThanSender) then
				local upperName = beneficiaryName:gsub("^%l", string.upper)
				beneficiaryGuid = query:GetUInt8(1)
				--P:SendBroadcastMessage("|cff00ff00Se encontró una cuenta a nombre de |cff0062ff" .. string.upper(beneficiaryName) .. "|r.")
				P:GossipClearMenu()
				addOption(ic(9) .. "Click para enviar a |cff0062ff" .. upperName .. "|r.", 5, 0, true,
					"Escribe la cantidad que transferirás a |cff0062ff" .. upperName .. "|r.", P)
				P:GossipSendMenu(1, Npc)
				return
			else
				msg(2, P, "No se encontró una cuenta ligada a ese nombre.")
				on_menu_click(e, P, Npc, 1, 0, passwordForThisIteration)
			end
		else
			msg(2, P, "ERROR: Has ingresado caracteres no permitidos.")
			on_menu_click(e, P, Npc, 1, 0, passwordForThisIteration)
		end
	end
	if (Send == 5) then
		if safeConvertToNumber(code) then
			local transferAmount = tonumber(code)
			local upperName = beneficiaryName:gsub("^%l", string.upper)

			if amountIsPositiveAndInteger then
				local amountFlored = math.floor(transferAmount)
				local raw = "UPDATE `atm` SET `gold` = `gold` %s %d WHERE `player_guid` = %d"
				local raw2 = "SELECT `gold` FROM `atm` WHERE `player_guid` = " .. guid
				local getSavedGold = CharDBQuery(raw2)

				local senderMoneyInDB = getSavedGold:GetUInt32(0)
				local subtract = string.format(raw, "-", amountFlored, guid)
				local add = string.format(raw, "+", amountFlored, beneficiaryGuid)

				if (amountFlored <= senderMoneyInDB) then
					CharDBExecute(subtract)
					CharDBExecute(add)
					P:SendBroadcastMessage(
						"|cff00ff00¡Se enviaron |cffff9900" .. addCommaToNumber(amountFlored)
						.. " G|cff00ff00 a la cuenta de |cff0062ff" .. upperName .. "|cff00ff00!")
				else
					P:SendBroadcastMessage("|cffff0000ERROR: No cuentas con esa cantidad en tu cuenta.")
					on_menu_click(e, P, Npc, 0, 4, beneficiaryName)
					return
				end
			else
				--ERROR
				msg(2, P, "ERROR: Ingresa números enteros positivos.")
			end
			on_menu_click(e, P, Npc, 1, 0, passwordForThisIteration)
			return
		else
			msg(2, P, "ERROR: Has ingresado caracteres no permitidos.")
			on_menu_click(e, P, Npc, 0, 4, beneficiaryName)
		end
	end

	--// CAMBIAR CONTRASEÑA //--
	if (Int == 5) then
		local isPasswordCorrect = function(playerGUID, passwordAttempt)
			local query = string.format(
				"SELECT COUNT(*) FROM `atm` WHERE `player_guid` = %d AND `player_password` = '%s'", playerGUID,
				passwordAttempt)
			local result = CharDBQuery(query)
			if result then
				return (result:GetUInt32(0) > 0) -- Si se encuentra una coincidencia, devuelve verdadero
			else
				return false -- Si no se pudo ejecutar la consulta, devuelve falso
			end
		end

		local passwordsMatch = isPasswordCorrect(guid, code) -- => Bool

		if passwordsMatch then
			P:GossipClearMenu()
			P:GossipMenuAddItem(0, ic(14) .. "Ingresar nueva contraseña", 0, 6, true, "Escribe tu nueva contraseña")
			P:GossipSendMenu(1, Npc)
		else
			-- Password incorrecta
			msg(2, P, "ERROR: La contraseña es incorrecta.")
			on_menu_click(e, P, Npc, 0, 1, passwordForThisIteration)
		end
	end
	if (Send == 0 and Int == 6) then
		if scapeCharactersFoundIn(code) then
			P:SendBroadcastMessage("|cffff0000ERROR: Esa contraseña contiene caracteres no permitidos.")
			on_menu_click(e, P, Npc, 0, 5, passwordForThisIteration) -- Menú anterior (Int == 5)
		else
			CharDBExecute(string.format("UPDATE `atm` SET `player_password` = '%s' WHERE `player_guid` = %d", code,
				guid))
			P:SendBroadcastMessage("|cff00ff00¡Contraseña Cambiada!")
			P:SendBroadcastMessage("|cff00ff00Nueva contraseña: |cff00ffff" .. code)
			P:SendBroadcastMessage("|cff00ff00No compartas tu contraseña con nadie.")
			P:GossipComplete()
		end
	end

	--// CERRAR CUENTA //--
	if (Send == 999 and Int == 999) then
		local checkGold_Q = "SELECT `gold` FROM `atm` WHERE `player_guid` = %d"
		local Gold_Query = CharDBQuery(string.format(checkGold_Q, guid))
		local gold_in_DB = Gold_Query:GetUInt32(0)

		if (gold_in_DB > 0) then
			msg(2, P, "ERROR: Debes retirar todo el dinero en la cuenta antes de poder borrarla.")
			on_menu_click(e, P, Npc, 1, 0, passwordForThisIteration)
		else
			local deleteAcc_Q =	"UPDATE `atm` SET `has_account` = 0, `player_password` = '', `gold` = 0, `secret_question` = '', `secret_answer` = '' WHERE `player_guid` = %d"
			CharDBExecute(string.format(deleteAcc_Q, guid))
			msg(1, P, "Cuenta cerrada satisfactoriamente")
			P:GossipComplete()
		end
	end
end

local function on_eluna_reload(E)
	local create = "CREATE TABLE IF NOT EXISTS `ATM` "
	local u = "UNSIGNED"
	local v = "VARCHAR(100)"

	local raw = string.format(
		"%s(`player_guid` INT %s UNIQUE, `has_account` TINYINT %s, `player_name` %s, `player_password` %s, `gold` BIGINT %s, `secret_question` %s, `secret_answer` %s)"
		, create, u, u, v, v, u, v, v)
	CharDBExecute(raw)
end

local function on_player_login(ev, P)
	CharDBExecute(string.format(
		"INSERT IGNORE INTO `ATM` (`player_guid`,`has_account`,`player_name`,`player_password`,`gold`,`secret_question`,`secret_answer`) VALUES (%d, 0,'','', 0,'','')",
		P:GetGUIDLow()))
end

local function on_player_logout(ev, P)
	CharDBExecute('DELETE FROM `atm` WHERE `has_account` = 0 AND `player_guid` = ' .. P:GetGUIDLow())
end

RegisterCreatureGossipEvent(npcId, 1, on_hello)
RegisterCreatureGossipEvent(npcId, 2, on_menu_click)
RegisterServerEvent(33, on_eluna_reload)
RegisterPlayerEvent(3, on_player_login)
RegisterPlayerEvent(4, on_player_logout)
