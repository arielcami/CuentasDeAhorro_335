--		Ariel Camilo / 24 de Mayo 2023

NPC_ID = 00000 --> Asigna el ID del NPC que correrá este Script.

	i = {} --iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii  > Iconos
		i._1 = '|TInterface\\Icons\\inv_misc_coin_01:35:35:-21|t'
		i._2 = '|TInterface\\Icons\\inv_misc_key_05:35:35:-21|t'
		i._3 = '|TInterface\\Icons\\spell_shadow_sacrificialshield:35:35:-21|t'
		i._4 = '|TInterface\\Icons\\inv_gauntlets_16:35:35:-21|t'
		i._5 = '|TInterface\\Icons\\inv_misc_note_05:35:35:-21|t' 
		i._6 = '|TInterface\\Icons\\inv_misc_note_02:35:35:-21|t'--iiiiiiiiiiiiiiiiiiiiiiiii

	function CC(A)  local f=A --------> Función para colocar la coma en números mayores a 3 cifras.
  		while true do f, k = string.gsub(f, "^(-?%d+)(%d%d%d)", '%1,%2') --> Ej: 1,250
    	if (k==0) then break end end
  		return f
  	end--------------------------------------------------------------------------------------------

  	function Goss(a,b,c,d,e,f,g) a:GossipMenuAddItem(b,c,d,e,f,g) end --> Para ahorrar espacio

local function Click(e,P,U) --ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo

	local g, na = P:GetGUIDLow(), P:GetName()

	Q = CharDBQuery("SELECT `player` FROM `aa_cajero` WHERE `player` = '"..g.."'")

	P:GossipClearMenu()

	if Q then		
		Goss(P, 8, i._1.."Realizar un depósito", 10, 1, true, "¿Cuanto oro deseas depositar?")
		Goss(P, 8, i._4.."Retirar oro", 10, 2, true, "¿Cuanto oro deseas retirar?")
		Goss(P, 8, i._5.."Consultar balance", 10, 3)
		Goss(P, 8, i._6.."Hacer una transferencia", 20, 20, true, "Escribe el nombre del beneficiario.")
		Goss(P, 8, i._3.."Cerrar mi cuenta", 40, 40, false, "¿Confirmas eliminar la cuenta a nombre de "..na.."? El coste son 20g.")
	else 
		Goss(P, 0, i._2.."Abrir una cuenta de ahorros!", 99, 99, false, "¿Deseas abrir una cuenta de ahorros? El coste son 5g.")
	end
	P:GossipSendMenu(1,U,MenuId)
end--oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo

local function MenuClick(e,P,U,S,I,C)     N, g, coin = P:GetName(), P:GetGUIDLow(), P:GetCoinage() --xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
	
	-- Para ahorrar espacio...
	local function gc() P:GossipComplete() end
	local function bc(a) P:SendBroadcastMessage(a) end

	if S==40 and I==40 then--Para eliminar una cuenta -------------------------------------------------------------------------------------
		dbq = CharDBQuery("SELECT `money` FROM `aa_cajero` WHERE `player` = "..g.."")  	--> Valida si el jugador tiene oro guardado.
		tiene = dbq:GetInt32(0)

		if tiene >= 1 then 
			bc("|cffff0000Error: |rPara poder eliminar tu cuenta, esta debe estar vacía.") gc()
		else 
			if coin >= 200000 then 
				CharDBExecute("DELETE FROM `aa_cajero` WHERE `player` = "..g.."")
				bc("|cff1e7d21Pagas 20g por motivo de cierre de cuenta.")
				bc('|cff00ff00Información: |rCuenta a nombre de "|cff00ff00'..N..'|r" ha sido eliminada.') P:ModifyMoney(-200000) gc()
			else 
				bc("|cffff0000Error: |rNo tienes suficiente oro para pagar.") gc()
			end			
		end
		return
	end -----------------------------------------------------------------------------------------------------------------------------------

	q=CharDBQuery("SELECT `money` FROM `aa_cajero` WHERE `player` = "..g.."") --> Recupera la cantidad de Oro que tiene el jugador en DB.

	local function Num(code) --> Asegurarnos que la entrada sea siempre un número entero, de lo contrario hacer Cero. ---
		n=tonumber(code)
		if n==nil then return 0 end
		if n<=0 then return 0 end
		if n<1 then return 0 end
		if n>=1 then 
			n=math.floor(n) return n
		end
	end------------------------------------------------------------------------------------------------------------------

	if S==10 and I==3 then C=3 end --> Cuando se consulta balance, hacer que C valga 3.

	if S==99 and I==99 then --Al clickear "Abrir una cuenta de ahorros" ---------------------------------------------
		if coin >= 50000 then
			CharDBExecute("INSERT IGNORE INTO `aa_cajero` (`name`, `player`,`money`) VALUES ('"..N.."',"..g..", 0)")
			P:ModifyMoney(-50000)
			bc("|cff1e7d21Pagas 5g por motivo de apertura de cuenta.")
			bc('|cff00ff00Información: |rCuenta a nombre de "|cff00ff00'..N..'|r" aperturada correctamente!')
		else 
			bc("|cffff0000Error: |rNo tienes oro suficiente para aperturar una cuanta de ahorros.")
		end
		gc()
		return
	end--------------------------------------------------------------------------------------------------------------

	if S==20 and I==20 then   P:GossipClearMenu() --Al clikcear "Hacer una transferencia" ---------------------------------------------------------------

		CharDBExecute("UPDATE `aa_cajero` SET `send` = '"..C.."' WHERE `player` = "..g.."") --> Guarda nombre del destinatario en la DB del que envía.
		Q=CharDBQuery("SELECT * FROM `aa_cajero` WHERE `name` = '"..C.."'") --> Valida si existe un registro con el nombre que se ha entrado.
		
		if Q then  --> Si existe registro...
			if string.lower(C) == string.lower(N) then --> Convierte a minúsculas el nombre introducido y el nombre del jugador, y los compara.
				bc("|cffff0000Error: |rNo puedes transferirte dinero a ti mismo.") gc() return				 
			end 
			P:GossipMenuAddItem(0, i._1..'Transferir oro a: '..string.upper(C), 50, 50, true, "Escribe el monto en números positivos enteros.")
			bc('|cff00ff00Información: |rSe encontró el jugador "|cff00ff00'..C..'|r"')
			P:GossipSendMenu(1,U,MenuId)
		else --> Si NO existe registro...
			bc('|cffff0000Error: |rNo se encontró ninguna cuenta a nombre de "|cffff0000'..C..'|r".') 
			gc()
		end
		return
	end--------------------------------------------------------------------------------------------------------------------------------------------------

	if S==50 and I==50 then -- Al clickear "Transferir oro a: FULANO" --------------------------------------------------------------------------------
		if Num(C)>=1 then --> Si la entrada es un número entero positivo...		
			Qu = CharDBQuery("SELECT `money` FROM `aa_cajero` WHERE `player` = "..g.."") --> Recupera la cantidad de oro que tiene el jugador en DB.
			moneyDB = Qu:GetInt32(0) --> Guarda la cantidad en la variable moneyDB

			if moneyDB >= Num(C) then --> Si la cantidad de oro que tiene el jugador en DB, es mayor o igual a la cantidad que desea enviar...
				quer = CharDBQuery("SELECT `send` FROM `aa_cajero` WHERE `player` = "..g.."")  Send = quer:GetString(0)
				CharDBExecute("UPDATE `aa_cajero` SET `money` = `money`-"..Num(C).." WHERE `player` = "..g.."")
				CharDBExecute("UPDATE `aa_cajero` SET `money` = `money`+"..Num(C).." WHERE `name` = '"..Send.."'")
				bc('|cff00ff00Información: |rTransferencia exitosa a |cff00ff00'..Send..'|r con valor de |cff00ff00$ '..CC( Num(C) )..' G|r!') 
				bc('|cffffd1f4Tu nuevo balance es: |cff00aeff$'..( CC(q:GetInt32(0)-Num(C))))
				gc()
				CharDBExecute("UPDATE `aa_cajero` SET `send` = NULL WHERE `player` = "..g.."")
									
				local P_destino = GetPlayerByName( Send )
									
				if P_destino then --> Eviar este anuncio al beneficiario solo si está conectado... 
					P_destino:SendBroadcastMessage("|cff00ff00Información: |rHas recibido una transferencia de "
					.."|cff00ff00"..P:GetName().."|r con valor de |cff00ff00$"..Num(C).."G")
				end				

			else --> Si quiere enviar más del dinero que tiene guardado...
				bc('|cffff0000Error: |rNo posees esa cantidad en tus ahorros.') gc()
			end
		else --> Si la entrada No es un número entero positivo...
			bc("|cffff0000Error: |rUsa solo números enteros positivos.") gc()
		end
		return
	end-------------------------------------------------------------------------------------------------------------------------

	if Num(C)==0 then --Si la entrada es incorrecta (letra, número negativo)-------------------------------------------------------------
		bc('|cffff0000Error: |rIngresa solo números enteros positivos.') return gc()
	else --> Si la entrada es correcta...
		N=Num(C)  Gold=N*10000 
		if S==10 then--------------------------------------------------------------------------------------------------------------------
			if I==1 then --> Realizar un depósito...							
				if coin>=Gold then
					CharDBExecute("UPDATE `aa_cajero` SET `money` = `money` + "..N.." WHERE `player`="..g.."")					
					bc('|cffffd1f4¡Depósito realizado! Tu nuevo balance es: |cff00aeff$'..( CC(q:GetInt32(0)+N) ).."|cffffd1f4.") gc()
					P:ModifyMoney(-Gold)
				else
					bc('|cffff0000Error: |rNo tienes esa cantidad de oro.') return gc()
				end
			end				
			if I==2 then --> Retirar oro
				if Gold+coin>=2000000000 then --> Si (Retiro + Oro en inventario) es igual o mayor a 200K... 
					bc("|cffff2b2bSi realizas este retiro acabarás con más de 200,000 de oro, "
						.."lo cual no es recomendable. Divide tu retiro en retiros más pequeños.") return gc()
				else --> Si no llega a sumar 200K...
					if N>q:GetInt32(0) then --> Si quiere retirar más de lo que tiene ahorrado...
						bc('|cffff0000Error: |rNo posees esa cantidad en tus ahorros.') return gc()
					else --> Si el retiro es menor a la cantidad ahorrada...
						CharDBExecute("UPDATE `aa_cajero` SET `money` = `money` - "..N.." WHERE `player`="..g.."")
						bc('|cffffd1f4¡Retiro realizado! Tu nuevo balance es: |cff00aeff$'..( CC(q:GetInt32(0)-N) ).."|cffffd1f4.") gc()
						P:ModifyMoney(Gold)
					end
				end
			end
			if I==3 then --> Consultar balance.							
				bc("|cffffd1f4Tu cuenta de ahorros: |cff00aeff$"..( CC(q:GetInt32(0))).."")
				return
				Click(e,P,U)
			end			
		end	-----------------------------------------------------------------------------------------------------------------------------
	end	---------------------------------------------------------------------------------------------------------------------------------
end--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

local function ElunaReload(ev)-- Se ejecuta cada vez que Eluna Lua Engine hace reload. -----------------
	CharDBExecute("CREATE TABLE IF NOT EXISTS `aa_cajero` ("
		.."`name` VARCHAR(16), "
		.."`player` MEDIUMINT UNSIGNED NOT NULL UNIQUE, "
		.."`money` INT UNSIGNED, "
		.."`send` VARCHAR(16) DEFAULT NULL)")
end-----------------------------------------------------------------------------------------------------

RegisterCreatureGossipEvent(NPC_ID, 1, Click)  RegisterCreatureGossipEvent(NPC_ID, 2, MenuClick)  RegisterServerEvent(33, ElunaReload) 
