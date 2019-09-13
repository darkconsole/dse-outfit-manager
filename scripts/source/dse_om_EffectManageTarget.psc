ScriptName dse_om_EffectManageTarget extends ActiveMagicEffect

dse_om_QuestController Property Main Auto

Event OnEffectStart(Actor Who, Actor Caster)
		
	Actor Target = Game.GetCurrentCrosshairRef() As Actor

	If(Target != None)
		Who = Target
	EndIf

	Main.Hello(Who)

	Return
EndEvent
