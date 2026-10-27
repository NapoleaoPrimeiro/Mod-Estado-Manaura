-- NO LAG 2.0 + FPS BOOSTER - CPU & AI LITE (Workshop 3766377228)
-- Portado para os namespaces do HOI4 1.19; valores existentes mais agressivos foram preservados.

--Game
NDefines.NGame.COMBAT_LOG_MAX_MONTHS = 3 --12
NDefines.NGame.MESSAGE_TIMEOUT_DAYS = 9					     	 -- WAS 60 	| less messages lying around at the top of your screen
NDefines.NGame.LAG_DAYS_FOR_LOWER_SPEED = 225 --10
NDefines.NGame.LAG_DAYS_FOR_PAUSE = 250 --25
NDefines.NGame.DECISION_ALERT_TIMEOUT_DAYS = 14 -- vanilla 30
NDefines.NGame.MISSION_REMOVE_FROM_INTERFACE_DEFAULT = 3 -- useless
NDefines.NResistance.GARRISON_LOG_MAX_MONTHS = 0 -- garrison log gets deleted after X months
NDefines.NGame.GAME_SPEED_SECONDS = { 0.35, 0.15, 0.10, 0.035, 0.0 } -- Velocidades 1-3 iguais ao SPOT; velocidades 4-5 preservadas

---Diplomacy
NDefines.NDiplomacy.DIPLOMACY_HOURS_BETWEEN_REQUESTS = 96 -- FPS Booster: reduz avaliações diplomáticas da IA
NDefines.NDiplomacy.GUARANTEE_COST = 12
NDefines.NDiplomacy.PEACE_SCORE_PER_PASS = 2.0
NDefines.NDiplomacy.TRUCE_PERIOD_AFTER_KICKING_FROM_FACTION = 0
NDefines.NDiplomacy.NUM_DAYS_TO_ENABLE_KICKING_NEW_MEMBERS_OF_FACTION = 0
NDefines.NDiplomacy.NUM_DAYS_TO_ENABLE_REINVITE_KICKED_NATIONS = 0
NDefines.NDiplomacy.FRONT_IS_DANGEROUS = 0
NDefines.NDiplomacy.LICENSE_ACCEPTANCE_SAME_FACTION = 30

--Effects
NDefines.NGraphics.WEATHER_DISTANCE_CUTOFF = 0
NDefines.NGraphics.WEATHER_DISTANCE_FADE_LENGTH = 0
NDefines.NGraphics.WEATHER_ZOOM_IN_CUTOFF = 0
NDefines.NGraphics.WEATHER_ZOOM_IN_FADE_LENGTH = 0
NDefines_Graphics.NGraphics.DRAW_REFRACTIONS_CUTOFF = 0
NDefines_Graphics.NGraphics.DRAW_FOW_CUTOFF = 0  --removes fog
NDefines_Graphics.NGraphics.DRAW_FOW_FADE_LENGTH = 0  --removes fog
NDefines_Graphics.NGraphics.DRAW_SHADOWS_CUTOFF = 0
NDefines_Graphics.NGraphics.DRAW_SHADOWS_FADE_LENGTH = 0
NDefines_Graphics.NGraphics.BLOOM_WIDTH = 0
NDefines_Graphics.NGraphics.BLOOM_SCALE = 0
NDefines_Graphics.NGraphics.BRIGHT_THRESHOLD = 0
NDefines_Graphics.NGraphics.EMISSIVE_BLOOM_STRENGTH = 0
NDefines_Graphics.NGraphics.DAY_NIGHT_FEATHER = 0.024

--Animation
NDefines_Graphics.NAirGfx.MAX_MISSILE_BOMBING_SCENARIOS = 0
NDefines_Graphics.NAirGfx.MAX_BOMBING_SCENARIOS = 0
NDefines_Graphics.NAirGfx.MAX_PATROL_SCENARIOS = 0
NDefines_Graphics.NAirGfx.MAX_DOGFIGHTS_SCENARIOS = 0
NDefines_Graphics.NAirGfx.MAX_TRANSPORT_SCENARIOS = 0
NDefines_Graphics.NAirGfx.BOMBERS_DIVISION_FACTOR = 200
NDefines_Graphics.NAirGfx.FIGHTERS_DIVISION_FACTOR = 200
NDefines_Graphics.NAirGfx.MISSILES_DIVISION_FACTOR = 200
NDefines_Graphics.NAirGfx.TRANSPORT_DIVISION_FACTOR = 200
NDefines_Graphics.NAirGfx.AIRPLANES_ANIMATION_GLOBAL_SPEED_PER_GAMESPEED = {0.3, 0.3, 0.3, 0.3, 0.3, 0.3}
NDefines_Graphics.NAirGfx.AIRPLANES_SMOOTH_INTERPOLATION_MOVE = 0.02 	-- How smooth is the movement interpolation.
NDefines_Graphics.NAirGfx.AIRPLANES_SMOOTH_INTERPOLATION_TURN = 0.02 	-- How smooth is the turning interpolation.
NDefines_Graphics.NMapMode.RADAR_ROTATION_SPEED = 0.0
NDefines_Graphics.NMapMode.AIR_RANGE_INDICATOR_ROTATION_SPEED = 0.0000

--Navy
NDefines.NNavy.CONVOY_LOSS_HISTORY_TIMEOUT_MONTHS = 1
NDefines.NNavy.NAVAL_COMBAT_RESULT_TIMEOUT_YEARS = 0.1
NDefines.NNavy.NAVAL_ACCIDENTS_DAYS_TO_LIVE = 30

--Country
NDefines.NCountry.EVENT_PROCESS_OFFSET = 40 --20; FPS Booster corrigido de NGame para NCountry
NDefines.NCountry.INTERPOLATED_FRONT_STEPS_SHORT = 1					-- Performance optimization
NDefines.NCountry.COUNTRY_SCORE_MULTIPLIER = 0 --score modifier that shows at end of game
NDefines.NCountry.ARMY_SCORE_MULTIPLIER = 0 --score modifier that shows at end of game
NDefines.NCountry.NAVY_SCORE_MULTIPLIER = 0 --score modifier that shows at end of game
NDefines.NCountry.AIR_SCORE_MULTIPLIER = 0 --score modifier that shows at end of game
NDefines.NCountry.INDUSTRY_SCORE_MULTIPLIER = 0 --score modifier that shows at end of game
NDefines.NCountry.PROVINCE_SCORE_MULTIPLIER = 0 --score modifier that shows at end of game

---AI
NDefines.NMilitary.GENERATE_AI_DIV_COMMAND_HISTORY_ENTRIES = false
NDefines.NAI.DAYS_BETWEEN_CHECK_BEST_TEMPLATE = 30
NDefines.NAI.REMOVE_OBSOLETE_TEMPLATE_DAYS = 90
NDefines.NAI.DAYS_BETWEEN_CHECK_BEST_DOCTRINE = 90
NDefines.NAI.RESEARCH_DAYS_BETWEEN_WEIGHT_UPDATE = 20
NDefines.NAI.REFIT_SHIP_RELUCTANCE = 90
NDefines.NAI.DAYS_BETWEEN_CHECK_BEST_EQUIPMENT = 30
NDefines.NAI.UPGRADE_DIVISION_RELUCTANCE = 14
NDefines.NAI.AI_OBJECTIVE_DEFAULT_TARGET_RECALC_DAYS = 7
NDefines.NAI.STRIKE_FORCE_TARGET_RECALC_DAYS = 7
NDefines.NRaids.MAX_STATE_TARGETS_TO_EVALUATE_PER_HOUR = 20
NDefines.NAI.EQUIPMENT_MARKET_BASE_MARKET_RATIO = 0.35
NDefines.NAI.DIPLOMACY_ACCEPT_ATTACHE_BASE = 100
NDefines.NAI.DIPLOMACY_ACCEPT_ATTACHE_OPINION_TRASHHOLD = 0
NDefines.NAI.DIPLOMACY_ACCEPT_ATTACHE_OPINION_PENALTY = 0
NDefines.NAI.GIVE_STATE_CONTROL_MIN_CONTROLLED = 0
NDefines.NAI.GIVE_STATE_CONTROL_MIN_CONTROL_DIFF = 0
NDefines.NAI.DIPLOMATIC_ACTION_RANDOM_FACTOR = 0.0
NDefines.NAI.AI_UPDATE_ROLES_FREQUENCY_HOURS = 112 -- vanilla 48; perfil rapido ja usado no pacote TFR 1.19

--Graphical Changes--
NDefines_Graphics.NMapIcons.STATES_PRIORITY_VICTORY_POINTS = 4
NDefines_Graphics.NGraphics.GRADIENT_BORDERS_THICKNESS_COUNTRY_LOW = 10.0 -- thickness in pixels -- 5
NDefines_Graphics.NGraphics.GRADIENT_BORDERS_COUNTRY_CENTER_THICKNESS = 1.0 -- The center gradient is linear 1/255 per pixel for this many pixels
NDefines_Graphics.NGraphics.GRADIENT_BORDERS_THICKNESS_COUNTRY_HIGH = 25.0
NDefines_Graphics.NGraphics.GRADIENT_BORDERS_THICKNESS_STATE = 45.0 --11
NDefines_Graphics.NGraphics.GRADIENT_BORDERS_THICKNESS_SUPPLY_AREA_A = 2.0 --2
NDefines_Graphics.NGraphics.GRADIENT_BORDERS_THICKNESS_SUPPLY_AREA_B = 15.0 --20
NDefines_Graphics.NGraphics.GRADIENT_BORDERS_THICKNESS_STRATEGIC_REGIONS = 50.0 --20
NDefines_Graphics.NGraphics.GRADIENT_BORDERS_OUTLINE_CUTOFF_STRATEGIC_REGIONS = 0.973
NDefines_Graphics.NGraphics.COUNTRY_COLOR_HUE_MODIFIER = 0.0 -- 0.0
NDefines_Graphics.NGraphics.COUNTRY_COLOR_SATURATION_MODIFIER = 0.7 -- 0.6
NDefines_Graphics.NGraphics.COUNTRY_COLOR_BRIGHTNESS_MODIFIER = 0.8 -- 0.8
NDefines_Graphics.NGraphics.CAMERA_ZOOM_SPEED = 50
NDefines_Graphics.NGraphics.CAMERA_ZOOM_KEY_SCALE = 0.02
NDefines_Graphics.NGraphics.CAMERA_ZOOM_SPEED_DISTANCE_MULT = 20.0

NDefines_Graphics.NGraphics.COMMANDGROUP_PRESET_COLORS_HSV = {
	0.0/360.0, 1.0, 0.75,	--red
	10.0/360.0, 1.0, 0.75,	--orange
	60.0/360.0, 1.0, 0.75,	--yellow
	120.0/360.0, 0.85, 0.75,	--green
	155.0/360.0, 1.0, 0.75,	--greenish
	180.0/360.0, 1.0, 0.75,	--turq
	220.0/360.0, 1.0, 0.75,	--blue
	260.0/360.0, 1.0, 0.85,	--dark purple
	330.0/360.0, 0, 0.75		--white
}

---Graphics
NDefines_Graphics.NGraphics.UNITS_DISTANCE_CUTOFF = 350
NDefines_Graphics.NGraphics.SHIPS_DISTANCE_CUTOFF = 350
NDefines_Graphics.NGraphics.UNIT_ARROW_DISTANCE_CUTOFF = 500
NDefines_Graphics.NGraphics.UNITS_ICONS_DISTANCE_CUTOFF = 500
NDefines_Graphics.NGraphics.NAVAL_COMBAT_DISTANCE_CUTOFF = 700
NDefines_Graphics.NGraphics.ADJACENCY_RULE_DISTANCE_CUTOFF = 1000
NDefines_Graphics.NGraphics.LAND_COMBAT_DISTANCE_CUTOFF = 600
NDefines_Graphics.NGraphics.SUPPLY_ICON_DISTANCE_CUTOFF = 7000
NDefines_Graphics.NGraphics.PROV_CONSTRUCTION_ICON_DISTANCE_CUTOFF = 350
NDefines_Graphics.NGraphics.STATE_CONSTRUCTION_ICON_DISTANCE_CUTOFF = 600
NDefines_Graphics.NGraphics.MAPICON_GROUP_PASSES = 5
NDefines_Graphics.NGraphics.RADAR_ICON_DISTANCE_CUTOFF = 500
NDefines_Graphics.NMapIcons.STRATEGIC_AIR_PRIORITY_AIR_MISSION = 290
NDefines_Graphics.NGraphics.CAPITAL_ICON_CUTOFF = 500						-- 1100 
NDefines_Graphics.NGraphics.DRAW_MAP_OBJECTS_CUTOFF = 250 					-- 550 
NDefines_Graphics.NGraphics.DRAW_DETAILED_CUTOFF = 500
NDefines_Graphics.NGraphics.MAP_BUILDINGS_SHRINK_DISTANCE = 100				-- 180
NDefines_Graphics.NGraphics.VICTORY_POINT_MAP_ICON_TEXT_CUTOFF = {250, 500, 750}  -- At what camera distance the VP name text disappears.
NDefines_Graphics.NGraphics.VICTORY_POINTS_DISTANCE_CUTOFF = {250, 500, 750}
NDefines_Graphics.NGraphics.MAP_ICONS_GROUP_CAM_DISTANCE = 100				--group moving and still units
NDefines_Graphics.NGraphics.MAP_ICONS_STATE_GROUP_CAM_DISTANCE = 325.0		--group into states
NDefines_Graphics.NGraphics.MAP_ICONS_STRATEGIC_GROUP_CAM_DISTANCE = 400		--group units into air regions
NDefines_Graphics.NGraphics.MAP_ICONS_STRATEGIC_AREA_HUGE = 220					--size limit for air region grouping
NDefines_Graphics.NGraphics.MAP_ICONS_STATE_HUGE = 100							--size limit for state grouping
NDefines_Graphics.NGraphics.MAPICON_GROUP_STRATEGIC_SIZE = 500
NDefines_Graphics.NGraphics.MAP_ICONS_GROUP_SPLIT_SELECTED_LIMIT = 10
NDefines_Graphics.NGraphics.MAP_ICONS_COARSE_COUNTRY_GROUPING_DISTANCE = 200
NDefines_Graphics.NGraphics.MAP_ICONS_COARSE_COUNTRY_GROUPING_DISTANCE_STRATEGIC = 0
NDefines_Graphics.NGraphics.AIRBASE_ICON_DISTANCE_CUTOFF = 600
NDefines_Graphics.NGraphics.NAVALBASE_ICON_DISTANCE_CUTOFF = 600
NDefines_Graphics.NGraphics.STRATEGIC_AIR_COLOR_BAD = {0.65, 0, 0, 1}
NDefines_Graphics.NGraphics.STRATEGIC_AIR_COLOR_GOOD = {0, 0.65, 0, 1}
NDefines_Graphics.NGraphics.STRATEGIC_AIR_COLOR_AVERAGE = {0.65, 0.65, 0, 1}
NDefines_Graphics.NGraphics.STRATEGIC_AIR_COLOR_NEUTRAL = {130.0/255, 130.0/255, 130.0/255, 1}
NDefines_Graphics.NGraphics.RESISTANCE_COLOR_GOOD = {0.0, 0.65, 0, 1}
NDefines_Graphics.NGraphics.RESISTANCE_COLOR_AVERAGE = {0.65, 0.65, 0, 1}
NDefines_Graphics.NGraphics.RESISTANCE_COLOR_BAD = {0.65, 0, 0, 1}	
NDefines_Graphics.NGraphics.STRATEGIC_NAVY_COLOR_MISSION = {0.65, 0.65, 0.0, 1}
NDefines_Graphics.NGraphics.STRATEGIC_NAVY_COLOR_NEUTRAL = {130.0/255, 130.0/255, 130.0/255, 1}
NDefines_Graphics.NGraphics.ROOT_FRONT_OFFSET = 2
NDefines_Graphics.NGraphics.BORDER_WIDTH = 1
