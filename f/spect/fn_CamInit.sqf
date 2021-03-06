// Spectator Script
_this spawn {

_unit = [_this, 0, player,[objNull]] call BIS_fnc_param;
_oldUnit = [_this, 1, objNull,[objNull]] call BIS_fnc_param;
_forced = [_this, 4, false,[false]] call BIS_fnc_param;
_isJIP = false;

if (isNil "f_var_JIP_Spectate") then {
    f_var_JIP_Spectate = false
};

// if they are jip, these are null
if(isNull _unit ) then {
    _unit = cameraOn;_isJIP=true;
};

// escape the script if you are not a seagull unless forced
if (typeof _unit != "seagull" && (isnull _oldUnit && (!f_var_JIP_Spectate || time < 10)) || !hasInterface) ExitWith { ["F_ScreenSetup"] call BIS_fnc_blackIn;};

// ==========================================================================

if(!isnil "BIS_fnc_feedback_allowPP") then {
  // disable death effects
  BIS_fnc_feedback_allowPP = false;
};

if(_isJIP) then {
  ["F_ScreenSetup",false] call BIS_fnc_blackOut;
};

[]spawn {
    uiSleep 2;
    ["F_ScreenSetup"] call BIS_fnc_blackIn;
};

// disable PA clientside caching
if (!isnil "handle_pacaching1") then {
    [handle_pacaching1] call CBA_fnc_removePerFrameHandler;
    [handle_pacaching2] call CBA_fnc_removePerFrameHandler;
    {
        {
            _x hideobject false; _x enablesimulation true;
        } foreach units _x;
    } foreach allgroups;
};

// Create a Virtual Unit to act as our player to make sure we get to keep
// Draw3D
if(isNil "f_cam_VirtualCreated") then {
    // Get a position in which to create the virtual unit
    _pos = [random(5),random(5),random(3) + 5 + (count alldeadmen) * 5];
    createCenter sideLogic;
    _newGrp = createGroup sideLogic;
    _newUnit = _newGrp createUnit ["VirtualCurator_F", _pos, [], 0, "NONE"];
    _newUnit allowDamage false;
    _newUnit hideObjectGlobal true;
    _newUnit enableSimulationGlobal false;
    _newUnit setpos _pos;
    selectPlayer _newUnit;
    waituntil{player == _newUnit};
    deleteVehicle _unit;
    f_cam_VirtualCreated = true;
};

// ==========================================================================
// Set spectator mode for radio system
[player, true] call TFAR_fnc_forceSpectator;

// ==========================================================================
_listBox = 2100;
lbClear _listBox;
// set inital values.
#include "macros.hpp"
f_cam_controls = [F_CAM_HELPFRAME,F_CAM_HELPBACK,F_CAM_MOUSEHANDLER,F_CAM_UNITLIST,F_CAM_MODESCOMBO,F_CAM_SPECTEXT,F_CAM_SPECHELP,F_CAM_HELPCANCEL,F_CAM_HELPCANCEL,F_CAM_MINIMAP,F_CAM_FULLMAP,F_CAM_BUTTIONFILTER,F_CAM_BUTTIONTAGS,F_CAM_BUTTIONTAGSNAME,F_CAM_BUTTIONFIRSTPERSON,F_CAM_DIVIDER];
f_cam_units = [];
f_cam_players = [];
f_cam_startX = 0;
f_cam_startY = 0;
f_cam_detlaX = 0;
f_cam_detlaY = 0;
f_cam_zoom = 0;
f_cam_hideUI = false;
f_cam_map_zoom = 0.5;
f_cam_mode = 0;
f_cam_toggleCamera = false;
f_cam_playersOnly = false;
f_cam_toggleTags = true;
f_cam_ads = false;
f_cam_nvOn = false;
f_cam_tiBHOn = false;
f_cam_tiWHOn = false;
f_cam_tagsEvent = -1;
f_cam_mShift = false;
f_cam_freecamOn = false;
f_cam_toggleTagsName = true;
f_cam_mapMode = 0;
f_cam_MouseButton = [false,false];
f_cam_mouseCord = [0.5,0.5];
f_cam_mouseDeltaX = 0.5;
f_cam_mouseDeltaY = 0.5;
f_cam_mouseLastX = 0.5;
f_cam_mouseLastY = 0.5;
f_cam_angleYcached = 0;
f_cam_angleX = 0;
f_cam_tracerOn = false;
f_cam_angleY = 60;
f_cam_ctrl_down = false;
f_cam_shift_down = false;
f_cam_freecam_buttons = [false,false,false,false,false,false];
f_cam_forcedExit = false;
// 0 = ALL, 1 = BLUFOR , 2 = OPFOR, 3 = INDFOR , 4 = Civ
f_cam_sideButton = 0;
f_cam_sideNames = ["All Sides","Blufor","Opfor","Indfor","Civ"];
// ==========================================================================
// Colors
f_cam_blufor_color = [BLUFOR] call bis_fnc_sideColor;
f_cam_opfor_color = [OPFOR] call bis_fnc_sideColor;
f_cam_indep_color = [independent] call bis_fnc_sideColor;
f_cam_civ_color = [civilian] call bis_fnc_sideColor;
f_cam_empty_color = [sideUnknown] call bis_fnc_sideColor;
// ==========================================================================
f_cam_listUnits = [];
f_cam_ToggleFPCamera = {
    f_cam_toggleCamera = !f_cam_toggleCamera;
    
    if(f_cam_toggleCamera) then {
        f_cam_mode = 1; //(view)
        f_cam_camera cameraEffect ["terminate", "BACK"];
        f_cam_curTarget switchCamera "internal";
    } else {
        f_cam_mode = 0;
        f_cam_camera cameraEffect ["internal", "BACK"];
    };
    
    call F_fnc_ReloadModes;
};

f_cam_GetCurrentCam = {
    _camera = f_cam_camera;
    switch(f_cam_mode) do {
        case 0:    {    _camera = f_cam_camera; };    // Standard
        case 1:    {    _camera = cameraOn;};         // FP
        case 3:    {    _camera = f_cam_freecamera;}; // Freecam
    };
    _camera
};

// set camera mode (default)
f_cam_cameraMode = 0;

// =======================================================================
// create the UI
createDialog "f_spec_dialog";
// add keyboard events
// hide minimap
((findDisplay 9228) displayCtrl 1350) ctrlShow false;
((findDisplay 9228) displayCtrl 1350) mapCenterOnCamera false;
// hide big map
((findDisplay 9228) displayCtrl 1360) ctrlShow false;
((findDisplay 9228) displayCtrl 1360) mapCenterOnCamera false;
f_cam_helptext = "<t color='#EAA724'><br />Hold right-click to pan the camera<br />Use the scroll wheel or numpad+/- to zoom in and out.<br />Use ctrl + rightclick to fov zoom<br /><br />Press H to show and close the help window.<br />Press M to toggle between no map,minimap and full size map.<br />T for switching on tracers on the map<br/>Space to switch to freecam <br/>Press H to close this window</t>";
((findDisplay 9228) displayCtrl 1310) ctrlSetStructuredText parseText (f_cam_helptext);
// create the camera and set it up.
f_cam_camera = "camera" camCreate [position _oldUnit select 0,position _oldUnit select 1,3];
f_cam_fakecamera = "camera" camCreate [position _oldUnit select 0,position _oldUnit select 1,3];
f_cam_curTarget = _oldUnit;
f_cam_freecamera = "camera" camCreate [position _oldUnit select 0,position _oldUnit select 1,3];
f_cam_camera camCommit 0;
f_cam_fakecamera camCommit 0;
f_cam_camera cameraEffect ["internal","back"];
f_cam_camera camSetTarget f_cam_fakecamera;
f_cam_MouseMoving = false;
cameraEffectEnableHUD true;
showCinemaBorder false;
f_cam_fired = [];
{
    _event = _x addEventHandler ["fired",{f_cam_fired = f_cam_fired - [objNull];f_cam_fired pushBack (_this select 6)}];
    _x setVariable ["f_cam_fired_eventid",_event];
} foreach (allunits + vehicles);
// ==========================================================================
// spawn sub scripts
call f_fnc_ReloadModes;
lbSetCurSel [2101,0];
f_cam_freeCam_script = [] spawn F_fnc_FreeCam;
f_cam_updatevalues_script = [] spawn F_fnc_UpdateValues;
["f_spect_tags", "onEachFrame", {_this call F_fnc_DrawTags}] call BIS_fnc_addStackedEventHandler;
};

// vim: sts=-1 ts=4 et sw=4
