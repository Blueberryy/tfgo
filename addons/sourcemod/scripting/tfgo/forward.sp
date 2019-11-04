static GlobalForward g_forwardBombPlanted;
static GlobalForward g_forwardBombDetonated;
static GlobalForward g_forwardBombDefused;

void Forward_AskLoad()
{
	g_forwardBombPlanted = new GlobalForward("TFGO_OnBombPlanted", ET_Ignore, Param_Cell, Param_Cell);
	g_forwardBombDetonated = new GlobalForward("TFGO_OnBombDetonated", ET_Ignore, Param_Cell);
	g_forwardBombDetonated = new GlobalForward("TFGO_OnBombDefused", ET_Ignore, Param_Cell, Param_Cell);
}

void Forward_BombPlanted(int team, ArrayList cappers)
{
	Call_StartForward(g_forwardBombPlanted);
	Call_PushCell(team);
	Call_PushCell(cappers);
	Call_Finish();
}

void Forward_BombDetonated(int team)
{
	Call_StartForward(g_forwardBombDetonated);
	Call_PushCell(team);
	Call_Finish();
}

void Forward_BombDefused(int team, ArrayList cappers)
{
	Call_StartForward(g_forwardBombDefused);
	Call_PushCell(team);
	Call_PushCell(cappers);
	Call_Finish();
}