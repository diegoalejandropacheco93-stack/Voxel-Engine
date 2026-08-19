package states;

import backend.Highscore;
import backend.StageData;
import backend.WeekData;
import backend.Song;
import backend.Rating;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.text.FlxTextBorderStyle;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxSave;
import flixel.util.FlxColor;
import flixel.input.keyboard.FlxKey;
import flixel.animation.FlxAnimationController;
import flixel.tweens.FlxTween;
import flixel.tweens.misc.FlxEase;
import flixel.system.FlxSound;
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import openfl.events.KeyboardEvent;
import haxe.Json;

import cutscenes.DialogueBoxPsych;

import states.StoryMenuState;
import states.FreeplayState;
import states.editors.ChartingState;
import states.editors.CharacterEditorState;

import substates.PauseSubState;
import substates.GameOverSubstate;

#if !flash
import openfl.filters.ShaderFilter;
#end

import shaders.ErrorHandledShader;

import objects.VideoSprite;
import objects.Note.EventNote;
import objects.*;
import states.stages.*;
import states.stages.objects.*;

#if LUA_ALLOWED
import psychlua.*;
#else
import psychlua.LuaUtils;
import psychlua.HScript;
#end

#if HSCRIPT_ALLOWED
import psychlua.HScript.HScriptInfos;
import crowplexus.iris.Iris;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
#end

class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], ['Shit', 0.4], ['Bad', 0.5], ['Bruh', 0.6],
		['Meh', 0.69], ['Nice', 0.7], ['Good', 0.8], ['Great', 0.9],
		['Sick!', 1], ['Perfect!!', 1]
	];

	private var isCameraOnForcedPos:Bool = false;
	public var boyfriendMap:Map<String, Character> = new Map<String, Character>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();

	#if HSCRIPT_ALLOWED
	public var hscriptArray:Array<HScript> = [];
	#end

	public var BF_X:Float = 770; public var BF_Y:Float = 100;
	public var DAD_X:Float = 100; public var DAD_Y:Float = 100;
	public var GF_X:Float = 400; public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var playbackRate(default, set):Float = 1;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public static var curStage:String = '';
	public static var stageUI(default, set):String = "normal";
	public static var uiPrefix:String = "";
	public static var uiPostfix:String = "";
	public static var isPixelStage(get, never):Bool;

	@:noCompletion static function set_stageUI(value:String):String {
		uiPrefix = uiPostfix = "";
		if (value != "normal") {
			uiPrefix = value.split("-pixel")[0].trim();
			if (value == "pixel" || value.endsWith("-pixel")) uiPostfix = "-pixel";
		}
		return stageUI = value;
	}
	@:noCompletion static function get_isPixelStage():Bool return stageUI == "pixel" || stageUI.endsWith("-pixel");

	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var spawnTime:Float = 2000;

	public var inst:FlxSound;
	public var vocals:FlxSound;
	public var opponentVocals:FlxSound;

	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Character = null;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	public var camFollow:FlxObject;
	private static var prevCamFollow:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var opponentStrums:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var playerStrums:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash> = new FlxTypedGroup<NoteSplash>();

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health(default, set):Float = 1;
	public var combo:Int = 0;

	public var healthBar:Bar;
	public var timeBar:Bar;
	var songPercent:Float = 0;

	public var ratingsData:Array<Rating> = Rating.loadDefault();
	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var guitarHeroSustains:Bool = false;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;
	public var pressMissDamage:Float = 0.05;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;
	public var voxelWatermarkTxt:FlxText; // VOXEL ENGINE WATERMARK

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;
	public static var daPixelZoom:Float = 6;
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if DISCORD_ALLOWED
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	var keysPressed:Array<Int> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	public static var instance:PlayState;
	#if LUA_ALLOWED public var luaArray:Array<FunkinLua> = []; #end

	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	private var luaDebugGroup:FlxTypedGroup<psychlua.DebugLuaText>;
	#end
	public var introSoundsSuffix:String = '';

	private var keysArray:Array<String>;
	public var songName:String;
	public var startCallback:Void->Void = null;
	public var endCallback:Void->Void = null;

	private static var _lastLoadedModDirectory:String = '';
	public static var nextReloadAll:Bool = false;

	override public function create()
	{
		_lastLoadedModDirectory = Mods.currentModDirectory;
		Paths.clearStoredMemory();
		
		// --- VOXEL ENGINE OPTIMIZATION: Agressive RAM Clean ---
		if(nextReloadAll || ClientPrefs.data.agressiveRAMClean)
		{
			Paths.clearUnusedMemory();
			Language.reloadPhrases();
			if (ClientPrefs.data.agressiveRAMClean) {
				#if cpp cpp.NativeGc.run(true); cpp.NativeGc.run(true); #end
				openfl.system.System.gc();
			}
		}
		nextReloadAll = false;

		startCallback = startCountdown;
		endCallback = endSong;
		instance = this;

		PauseSubState.songName = null;
		playbackRate = ClientPrefs.getGameplaySetting('songspeed');

		keysArray = ['note_left', 'note_down', 'note_up', 'note_right'];

		if(FlxG.sound.music != null) FlxG.sound.music.stop();

		healthGain = ClientPrefs.getGameplaySetting('healthgain');
		healthLoss = ClientPrefs.getGameplaySetting('healthloss');
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill');
		practiceMode = ClientPrefs.getGameplaySetting('practice');
		cpuControlled = ClientPrefs.getGameplaySetting('botplay');
		guitarHeroSustains = ClientPrefs.data.guitarHeroSustains;

		camGame = initPsychCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		// --- VOXEL ENGINE OPTIMIZATION: Render Scale ---
		if (ClientPrefs.data.enableRenderScale) {
			FlxG.game.stage.quality = openfl.display.StageQuality.LOW;
		} else {
			FlxG.game.stage.quality = openfl.display.StageQuality.BEST;
		}

		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);

		persistentUpdate = true;
		persistentDraw = true;

		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;

		GameOverSubstate.resetVariables();
		songName = Paths.formatToSongPath(SONG.song);
		if(SONG.stage == null || SONG.stage.length < 1)
			SONG.stage = StageData.vanillaSongStage(Paths.formatToSongPath(Song.loadedSongName));

		curStage = SONG.stage;
		var stageData:StageFile = StageData.getStageFile(curStage);
		defaultCamZoom = stageData.defaultZoom;

		stageUI = "normal";
		if (stageData.stageUI != null && stageData.stageUI.trim().length > 0)
			stageUI = stageData.stageUI;
		else if (stageData.isPixelStage == true) 
			stageUI = "pixel";

		BF_X = stageData.boyfriend[0]; BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0]; GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0]; DAD_Y = stageData.opponent[1];

		if(stageData.camera_speed != null) cameraSpeed = stageData.camera_speed;
		boyfriendCameraOffset = stageData.camera_boyfriend != null ? stageData.camera_boyfriend : [0, 0];
		opponentCameraOffset = stageData.camera_opponent != null ? stageData.camera_opponent : [0, 0];
		girlfriendCameraOffset = stageData.camera_girlfriend != null ? stageData.camera_girlfriend : [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GY...