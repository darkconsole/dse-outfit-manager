ScriptName dse_om_EffectManageTarget extends ActiveMagicEffect

dse_om_QuestController Property Main Auto

Event OnEffectStart(Actor Who, Actor Caster)
	Main.ActorRegister(Who)
	Return
EndEvent
