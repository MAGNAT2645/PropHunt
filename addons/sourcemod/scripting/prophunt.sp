#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <StaticProps>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "PropHunt Neu", 
	author = "Mikusch", 
	description = "A modern PropHunt plugin for Team Fortress 2", 
	version = "1.0.0", 
	url = "https://github.com/Mikusch/PropHunt"
}

public void OnPluginStart()
{
	RegAdminCmd("ph_debug", ConCmd_DebugBox, ADMFLAG_GENERIC);
}

public Action ConCmd_DebugBox(int client, int args)
{
	float pos[3];
	if (!GetClientAimPosition(client, pos))
		return;
	
	int total = GetTotalNumberOfStaticProps();
	for (int i = 0; i < total; i++)
	{
		// Ignore non-solid props
		SolidType_t solid_type;
		if (!StaticProp_GetSolidType(i, solid_type) || solid_type == SOLID_NONE)
			continue;
		
		float mins[3], maxs[3];
		if (!StaticProp_GetWorldSpaceBounds(i, mins, maxs))
			continue;
		
		// Check whether we pointed at the current prop
		if (!IsPointWithin(pos, mins, maxs))
			continue;
		
		char name[PLATFORM_MAX_PATH];
		if (!StaticProp_GetModelName(i, name, sizeof(name)))
			continue;
		
		SetPropModel(client, name);
		
		// Exit out after we find a valid prop
		break;
	}
}

void SetPropModel(int client, const char[] model)
{
	PrintToChat(client, "You have chosen: %s", model);
	
	SetVariantString(model);
	AcceptEntityInput(client, "SetCustomModel");
	
	// TODO: Move this somewhere else
	SetVariantInt(1);
	AcceptEntityInput(client, "SetForcedTauntCam");
	
	int wearable = MaxClients + 1;
	while ((wearable = FindEntityByClassname(wearable, "tf_wearable*")) != -1)
	{
		int owner = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
		if (owner != -1)
			TF2_RemoveWearable(owner, wearable);
	}
}

bool GetClientAimPosition(int client, float pos[3])
{
	float eyePosition[3], eyeAngles[3];
	GetClientEyePosition(client, eyePosition);
	GetClientEyeAngles(client, eyeAngles);
	
	if (TR_PointOutsideWorld(eyePosition))
		return false;
	
	Handle trace = TR_TraceRayFilterEx(eyePosition, eyeAngles, MASK_VISIBLE, RayType_Infinite, TraceFilterEntity, client);
	TR_GetEndPosition(pos, trace);
	delete trace;
	
	return true;
}

public bool TraceFilterEntity(int entity, int mask, any data)
{
	return entity != data;
}

bool IsPointWithin(float point[3], float corner1[3], float corner2[3])
{
	float field1[2];
	float field2[2];
	float field3[2];
	
	if (FloatCompare(corner1[0], corner2[0]) == -1)
	{
		field1[0] = corner1[0];
		field1[1] = corner2[0];
	}
	else
	{
		field1[0] = corner2[0];
		field1[1] = corner1[0];
	}
	if (FloatCompare(corner1[1], corner2[1]) == -1)
	{
		field2[0] = corner1[1];
		field2[1] = corner2[1];
	}
	else
	{
		field2[0] = corner2[1];
		field2[1] = corner1[1];
	}
	if (FloatCompare(corner1[2], corner2[2]) == -1)
	{
		field3[0] = corner1[2];
		field3[1] = corner2[2];
	}
	else
	{
		field3[0] = corner2[2];
		field3[1] = corner1[2];
	}
	
	if (point[0] < field1[0] || point[0] > field1[1])
	{
		return false;
	}
	else if (point[1] < field2[0] || point[1] > field2[1])
	{
		return false;
	}
	else if (point[2] < field3[0] || point[2] > field3[1])
	{
		return false;
	}
	else
	{
		return true;
	}
}