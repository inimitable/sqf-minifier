/*
GetSafePos = { ?pos, ?min_dist, ?max_dist, ?dist_from_nearest, ?water_allowed, ?slope_max -> pos
	params [
		["_pos", position player],
		["_mind", 10],
		["_maxd", 200],
		["_away", 5],
		["_water", 0],
		["_slope", 0.1]
	];
	[_pos, _mind, _maxd, _away, _water, _slope] call BIS_fnc_findSafePos;
};

GetSafePosGround = { ?pos --> pos
	params [
		["_pos", position player]
	];
	[_pos, 5, 35, 5, 0, 0.35] call BIS_fnc_findSafePos;
};

GetSafePosAir = { ?pos --> _pos
	params [
		["_pos", position player]
	];
	[_pos, 10, 200, 10, 0, 0.1] call BIS_fnc_findSafePos;
};

DeleteVehicleWhenEmpty = { // vehicle, delay  --> void
	// Deletes a vehicle when it has been empty for at least a certain amount of time.
	params [
		"_veh",
		["_delay", 60]
	];
	[_veh] spawn {
		private _vehicle = param [0, objNull];
		waitUntil {
			if (count ((crew vehicle _veh) select {alive _x}) isEqualTo 0) then {
				_time = diag_tickTime + _delay;
					
				waitUntil {
					diag_tickTime > _time || count (crew vehicle _veh select {alive _x}) > 0
				};
					
				if (diag_tickTime > _time && {count (crew vehicle _veh select {alive _x}) isEqualTo 0}) exitWith {
					deleteVehicle _veh;
				};
			};
			!isNull _veh
		};
	};
};
*/
TempMarker = { // pos, name, ?style, ?duration  --> void
	// Makes a temporary marker on the map.
	params [
		"_pos",
		"_name",
		["_style", "hd_dot"],
		["_duration", 60]
	];
	private _marker = createMarker [_name,_pos];
	_marker setMarkerShape "ICON";
	_marker setMarkerType _style;
	[_marker, _duration] spawn {sleep (_this select 1); deleteMarker (_this select 0);}
};

GetPosLookingAt = { // ?max_dist, ?default_pos --> void
	// Gets the position a player is currently *looking* at (not necessarily aiming at).
	params [
		["_max_dist", 750],
		["_default_pos", player getPos [25,getDir player]]
	];
	private _ins = lineIntersectsSurfaces [
		AGLToASL positionCameraToWorld [0,0,0], 
		AGLToASL positionCameraToWorld [0,0,_max_dist], 
		player
	];
	if (count _ins == 0) then {
		_default_pos
	} else {
		_ins select 0 select 0
	};
};

PointsAround = { // center, ?number, ?distance, ?angle_offset --> array
	// Returns a number of positions equidistant from a center position.
	params [
		"_center",
		["_num", 4],
		["_dist", 10],
		["_offset", 0]
	];
	private _spacing = 360 / _num;
	private _points = [];
	private _i = 0;
	for [{_i=_offset}, {_i < 360}, {_i = _i + _spacing}] do {
		_points pushBack ((_center getPos [_dist, _i]) vectorDiff _center);
	};
	_points;
};

DeleteObjectAfter = { // object, ?delay --> void
	// Deletes an object after a certain amount of time has elapsed.
	params [
		"_object",
		["_delay", 60]
	];
	[_object, _delay] spawn {sleep (_this select 1); deleteVehicle (_this select 0)};
};

DeleteManyAfter = { // objects, ?delay --> void
	// Deletes many objects after a certain amount of time has elapsed.
	params [
		"_objs",
		["_delay", 60]
	];
	{
		[_x, _delay] spawn {sleep (_this select 1); deleteVehicle (_this select 0)};
	} forEach _objs;
};

rev_reviveUnit = { // unit, medic --> void
	private ["_unit", "_medic"];
	_unit = _this select 0;
	_medic = _this select 1;
	if (isPlayer _unit) then {	
		[] remoteExec ["rev_resetCamera", _unit];	
		[_unit, false] remoteExec ["setUnconscious", _unit];		
		[_unit, true] remoteExec ["allowDamage", _unit];
		[_unit, false] remoteExec ["setCaptive", _unit];		
	} else {
		if (local _unit) then {
			_unit setUnconscious false;			
			_unit allowDamage true;
			_unit setCaptive false;
		} else {
			[_unit, false] remoteExec ["setUnconscious", _unit];		
			[_unit, true] remoteExec ["allowDamage", _unit];
			[_unit, false] remoteExec ["setCaptive", _unit];
		};
	};
	[(format ["CroScript: Unit %1 is revived by medic %2", _unit, _medic])] remoteExec ["diag_log", 2];
	_unit setDamage 0;
	_unit setVariable ["rev_downed", false, true];
	_unit setVariable ["rev_beingAssisted", false, true];
	_unit setVariable ["rev_beingRevived", false, true];
	_unit setVariable ["rev_dragged", false, true];

};
PosToGround = { // pos -> pos
	params [
		"_pos"
	];
	_pos = [(_pos select 0), (_pos select 1), 0];
	_pos;
};




DisableStamina = { // --> void
	// Disables stamina for all units in a player's group.
	{
		_x enableStamina false;
		_x forceWalk false;
		_x allowSprint true;
	} forEach units group player;
};


SpawnVehicle = { // classname, ?pos, ?markername, ?markertype  -->  vehicle
	// Spawns a vehicle at a specified position and creates a temporary group-visible marker showing where it is.
	params [
	"_veh",
	["_pos", call GetPosLookingAt],
	["_mname", "Vehicle"],
	["_mtype", "hd_dot"]
	];
	private _obj = createVehicle [_veh, _pos, [], 0, "CAN_COLLIDE"];
	[_pos, _mname, _mtype] call TempMarker;
	_obj
};


SpawnHeli = { // ?classname, ?pos  -->  void
	// Spawns a helicopter at a specified position and creates a temporary group-visible marker showing where it is.
	params [
	["_veh", "I_Heli_light_03_unarmed_F"],
	["_pos", call GetPosLookingAt]
	];
	[_veh, _pos, "Heli", "c_air"] call SpawnVehicle;
};


SpawnPlane = { // ?classname, ?pos  -->  void
	// Spawns a plane at a specified position and creates a temporary group-visible marker showing where it is.
	params [
	["_veh", "I_C_Plane_Civil_01_F"],
	["_pos", call GetPosLookingAt]
	];
	[_veh, _pos, "Plane", "c_plane"] call SpawnVehicle;
};


SpawnTruck = { // ?classname, ?pos  -->  void
	// Spawns a truck at a specified position and creates a temporary group-visible marker showing where it is.
	params [
	["_veh", "I_C_Offroad_02_unarmed_F"],
	["_pos", call GetPosLookingAt]
	];
	[_veh, _pos, "Car", "c_car"] call SpawnVehicle;
};


SpawnGarage = { // ?pos, ?cleanup_after_x_seconds  -->  object
	// Creates a Garage object (can spawn any vehicle at this) which optionally removes itself after a certain amount of time.
	params [
		["_pos", [60] call GetPosLookingAt],
		["_cleanup", 180]
	];
	// make a helipad
	new_helipad = createVehicle ["Land_HelipadCivil_F", _pos, [], 0, "CAN_COLLIDE"]; 

	// make some lights around the helipad
	private _posts = [];
	{
		private _newpost = createVehicle ["PortableHelipadLight_01_red_F", _pos, [], 0, "CAN_COLLIDE"]; 
		_newpost attachTo [new_helipad, _x];
		_posts pushBack _newpost;
	} foreach ([_pos, 6, 8] call PointsAround);

	private _console_pos = ((position player) vectorDiff _pos);
	_console_pos = [vectorNormalized _console_pos, 10] call BIS_fnc_vectorMultiply;
	_console_pos = [(_console_pos select 0), (_console_pos select 1), (_console_pos select 2) - 3.3];
	private _console_dir = (player getDir new_helipad);
	hint (format ["%1", _console_pos]);
	
	private _console = createVehicle ["Land_InfoStand_V2_F", _console_pos, [], 0, "CAN_COLLIDE"];

	_console attachTo [new_helipad,_console_pos];
	_console setDir _console_dir;
	
	_console addAction ["Open Garage", {
		["Open", [ true, new_helipad ]] call BIS_fnc_garage;
	}];

	// trigger cleanup when done
	if (_cleanup > 0) then {
		_posts pushBack new_helipad;
		_posts pushBack _console;
		[_posts, _cleanup] call DeleteManyAfter;
	};

	// return the garage object
	new_helipad;
};


SpawnArsenal = { // ?box_classname, ?cleanup_delay  -->  object
	// Creates an Arsenal box (can spawn any vehicle at this) which optionally removes itself after a certain amount of time.
	params [
		["_class", "Land_MetalCase_01_large_F"],
		["_cleanup", 180]
	];

	private _pos = ((getpos player) getPos [5, getDir player]);

	if (!isNil "_pos") then {
		private _box = createVehicle [_class, _pos, [], 0, "CAN_COLLIDE"];
		["AmmoboxInit", [_box, true]] call BIS_fnc_arsenal;
		[_pos, "Arsenal", "b_support"] call TempMarker;
		if (_cleanup > 0) then {
			[_box, 180] call DeleteObjectAfter;
		};
		// return the box object
		_box;
	};
};


ReviveAll = {  //  -->  void
	// Revives all downed members of a player's squad.
	private _string = selectRandom [
		"Are we to give up so easily? Up, my allies! Up, and to war! Huzzah!",
		"Compatriots! Kinsmen! Harken to me! Arise, and do battle with the enemy!",
		"What ho, friends? Our country needs us! Let us grapple with our foe anew!",
		"Be strong, my friends! Pick yourselves up and resume your righteous struggle!"
	];
	[player, _string] remoteExec ["groupChat", 0];
	{
		// fix bug where ai sometimes become unresponsive after being revived while alive
		if (_x getVariable "rev_downed") then {
			[_x, player] call rev_reviveUnit;
		};
	} forEach units group player;
};



AllEnemies = {  //  -->  void
	// Returns a list of all units enemy to the player.
	private _retn = [];
	{
		private _notAlly = side _x != playerSide;
		private _notCiv = side _x != civilian;
		if (_notAlly && _notCiv) then {
			_retn pushBackUnique _x;
		} 
	} forEach allUnits;
	_retn;
};


RevealNear = {  // ?unit, ?dist  -->  number_of_enemies
	params [
		["_unit", player],
		["_dist", 500]
	];
	private _enemies = call AllEnemies;
	{
		if (_unit distance _x < _dist) then {
			_unit reveal _x;
		};
	} forEach _enemies;
	count _enemies;
};


ShowCache = {  //  -->  void
	private _types = ["Box_Syndicate_WpsLaunch_F", "Box_Syndicate_Wps_F", "Box_IED_Exp_F", "Box_FIA_Ammo_F", "Box_FIA_Support_F", "Box_FIA_Wps_F"];
	private _boxes = entities [_types, [], true, true];
	{
		if (player distance _x < 500) then {
			private _pos = [getPos _x select 0, getpos _x select 1, (getpos _x select 2) + 150];
			private _thing = "Sign_Arrow_Large_F" createVehicle _pos;
			// Force the position to be set correctly
			_thing setPos _pos;
			[_thing, 180] call DeleteObjectAfter;
		};
	} foreach _boxes;
};

player createDiarySubject ["Functions", "Functions"];
player createDiaryRecord ["Functions", ["Show Cache", "<execute expression='call ShowCache'>Execute</execute>"]];
player createDiaryRecord ["Functions", ["Spawn Heli", "<execute expression='call SpawnHeli'>Execute</execute>"]];
player createDiaryRecord ["Functions", ["Spawn Truck", "<execute expression='call SpawnTruck'>Execute</execute>"]];
player createDiaryRecord ["Functions", ["Spawn Garage", "<execute expression='call SpawnGarage'>Execute</execute>"]];
player createDiaryRecord ["Functions", ["Create Arsenal", "<execute expression='call SpawnArsenal'>Execute</execute>"]];
player createDiaryRecord ["Functions", ["Revive All Units", "<execute expression='call ReviveAll'>Execute</execute>"]];
player createDiaryRecord ["Functions", ["Disable Stamina All Units", "<execute expression='call DisableStamina'>Execute</execute>"]];