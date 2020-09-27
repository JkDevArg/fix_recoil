#define PLUGIN_NAME "Fix Recoil"
#define PLUGIN_VERSION "0.1"
#define PLUGIN_AUTHOR "VEN"

#include <amxmodx>
#include <fakemeta>
#include <cstrike>
#include <xs>

#define MAX_CLIENTS 32
new g_normal_trace[MAX_CLIENTS + 1]
new bool:g_fix_punchangle[MAX_CLIENTS + 1]

new g_fwid
new g_max_clients

new const g_guns_events[][] = {
    "events/awp.sc",
    "events/g3sg1.sc",
    "events/ak47.sc",
    "events/scout.sc",
    "events/m249.sc",
    "events/m4a1.sc",
    "events/sg552.sc",
    "events/aug.sc",
    "events/sg550.sc",
    "events/m3.sc",
    "events/xm1014.sc",
    "events/usp.sc",
    "events/mac10.sc",
    "events/ump45.sc",
    "events/fiveseven.sc",
    "events/p90.sc",
    "events/deagle.sc",
    "events/p228.sc",
    "events/glock18.sc",
    "events/mp5n.sc",
    "events/tmp.sc",
    "events/elite_left.sc",
    "events/elite_right.sc",
    "events/galil.sc",
    "events/famas.sc"
}

new g_guns_eventids_bitsum

public plugin_precache() {
    g_fwid = register_forward(FM_PrecacheEvent, "fwPrecacheEvent", 1)
}

public fwPrecacheEvent(type, const name[]) {
    for (new i = 0; i < sizeof g_guns_events; ++i) {
        if (equal(g_guns_events[i], name)) {
            g_guns_eventids_bitsum |= (1<<get_orig_retval())
            return FMRES_HANDLED
        }
    }

    return FMRES_IGNORED
}

public plugin_init() {
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)

    unregister_forward(FM_PrecacheEvent, g_fwid, 1)

    register_forward(FM_PlaybackEvent, "fwPlaybackEvent")
    register_forward(FM_PlayerPostThink, "fwPlayerPostThink", 1)
    register_forward(FM_TraceLine, "fwTraceLine")

    g_max_clients = global_get(glb_maxClients)
}

public fwPlaybackEvent(flags, invoker, eventid) {
    if (!(g_guns_eventids_bitsum & (1<<eventid)) || !(1 <= invoker <= g_max_clients))
        return FMRES_IGNORED

    g_fix_punchangle[invoker] = true

    return FMRES_HANDLED
}

public fwPlayerPostThink(id) {
    if (g_fix_punchangle[id] && cs_get_user_team(id) == CS_TEAM_CT) {
        g_fix_punchangle[id] = false
        set_pev(id, pev_punchangle, Float:{0.0, 0.0, 0.0})
        return FMRES_HANDLED
    }

    return FMRES_IGNORED
}

public fwTraceLine(const Float:start[3], const Float:dest[3], ignore_monsters, id, ptr) {
    if (!(1 <= id <= g_max_clients))
        return FMRES_IGNORED

    if (!g_normal_trace[id]) {
        g_normal_trace[id] = ptr
        return FMRES_HANDLED
    }

    new silah = get_user_weapon(id);
    if (ptr == g_normal_trace[id] || ignore_monsters != DONT_IGNORE_MONSTERS || !is_user_alive(id) || silah == CSW_KNIFE)

    return FMRES_IGNORED

    fix_recoil_trace(id, start, ptr)

    return FMRES_SUPERCEDE
}

public client_connect(id) {
    g_normal_trace[id] = 0
}

fix_recoil_trace(id, const Float:start[], ptr) {
    static Float:dest[3]
    pev(id, pev_v_angle, dest)
    engfunc(EngFunc_MakeVectors, dest)
    global_get(glb_v_forward, dest)
    xs_vec_mul_scalar(dest, 9999.0, dest)
    xs_vec_add(start, dest, dest)
    engfunc(EngFunc_TraceLine, start, dest, DONT_IGNORE_MONSTERS, id, ptr)
}

