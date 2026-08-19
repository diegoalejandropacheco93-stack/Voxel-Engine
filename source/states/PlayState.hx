package states;

import backend.Highscore;
import backend.StageData;
import backend.WeekData;
import backend.Song;
import backend.Rating;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.animation.FlxAnimationController;
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
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		// Stage Switch
		switch (curStage) {
			case 'stage': new StageWeek1(); case 'spooky': new Spooky();
			case 'philly': new Philly(); case 'limo': new Limo();
			case 'mall': new Mall(); case 'mallEvil': new MallEvil();
			case 'school': new School(); case 'schoolEvil': new SchoolEvil();
			case 'tank': new Tank(); case 'phillyStreets': new PhillyStreets();
			case 'phillyBlazin': new PhillyBlazin();
		}
		
		if(isPixelStage) introSoundsSuffix = '-pixel';

		if (!stageData.hide_girlfriend) {
			if(SONG.gfVersion == null || SONG.gfVersion.length < 1) SONG.gfVersion = 'gf';
			gf = new Character(0, 0, SONG.gfVersion);
			startCharacterPos(gf);
			gfGroup.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);

		boyfriend = new Character(0, 0, SONG.player1, true);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		
		if(stageData.objects != null && stageData.objects.length > 0) {
			var list:Map<String, FlxSprite> = StageData.addObjectsToState(stageData.objects, !stageData.hide_girlfriend ? gfGroup : null, dadGroup, boyfriendGroup, this);
			for (key => spr in list)
				if(!StageData.reservedNames.contains(key))
					variables.set(key, spr);
		} else {
			add(gfGroup); add(dadGroup); add(boyfriendGroup);
		}
			
		var camPos:FlxPoint = FlxPoint.get(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if(gf != null) {
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		uiGroup = new FlxSpriteGroup();
		comboGroup = new FlxSpriteGroup();
		noteGroup = new FlxTypedGroup<FlxBasic>();
		add(comboGroup);
		add(uiGroup);
		add(noteGroup);

		Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;
		var showTime:Bool = (ClientPrefs.data.timeBarType != 'Disabled');
		
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = updateTime = showTime;
		if(ClientPrefs.data.downScroll) timeTxt.y = FlxG.height - 44;
		if(ClientPrefs.data.timeBarType == 'Song Name') timeTxt.text = SONG.song;

		timeBar = new Bar(0, timeTxt.y + (timeTxt.height / 4), 'timeBar', function() return songPercent, 0, 1);
		timeBar.scrollFactor.set();
		timeBar.screenCenter(X);
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		uiGroup.add(timeBar);
		uiGroup.add(timeTxt);

		noteGroup.add(strumLineNotes);
		generateSong();
		noteGroup.add(grpNoteSplashes);

		camFollow = new FlxObject();
		camFollow.setPosition(camPos.x, camPos.y);
		camPos.put();
		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.snapToTarget();

		healthBar = new Bar(0, FlxG.height * (!ClientPrefs.data.downScroll ? 0.89 : 0.11), 'healthBar', function() return health, 0, 2);
		healthBar.screenCenter(X);
		healthBar.leftToRight = false;
		healthBar.scrollFactor.set();
		reloadHealthBarColors();
		uiGroup.add(healthBar);

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		uiGroup.add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		uiGroup.add(iconP2);

		scoreTxt = new FlxText(0, healthBar.y + 40, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		uiGroup.add(scoreTxt);

		botplayTxt = new FlxText(400, healthBar.y - 90, FlxG.width - 800, Language.getPhrase("Botplay").toUpperCase(), 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		uiGroup.add(botplayTxt);

		// --- VOXEL ENGINE: WATERMARK ---
		if (ClientPrefs.data.voxelWatermark) {
			voxelWatermarkTxt = new FlxText(10, FlxG.height - 24, 0, "Voxel Engine v" + MainMenuState.voxelEngineVersion, 16);
			voxelWatermarkTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			voxelWatermarkTxt.scrollFactor.set();
			uiGroup.add(voxelWatermarkTxt);
		}

		// Aplicar HUD Transparencias (Voxel Engine)
		reloadHUDVisibility();

		uiGroup.cameras = [camHUD];
		noteGroup.cameras = [camHUD];
		comboGroup.cameras = [camHUD];

		startingSong = true;

		if(eventNotes.length > 0) {
			for (event in eventNotes) event.strumTime -= eventEarlyTrigger(event);
			eventNotes.sort(sortByTime);
		}

		startCallback();
		RecalculateRating(false, false);

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		super.create();
		Paths.clearUnusedMemory();

		if (ClientPrefs.data.agressiveRAMClean) {
			#if cpp cpp.NativeGc.run(true); cpp.NativeGc.run(true); #end
			openfl.system.System.gc();
		}

		if(eventNotes.length < 1) checkEventNote();
	}

	public function reloadHUDVisibility():Void
	{
		var showBar:Bool = !ClientPrefs.data.hideHealthBar && !ClientPrefs.data.hideHud;
		if (healthBar != null)
		{
			healthBar.visible = showBar;
			healthBar.alpha = ClientPrefs.data.healthBarAlpha * ClientPrefs.data.hudAlpha;
		}
		if (iconP1 != null) {
			iconP1.visible = showBar;
			iconP1.alpha = ClientPrefs.data.hudAlpha;
		}
		if (iconP2 != null) {
			iconP2.visible = showBar;
			iconP2.alpha = ClientPrefs.data.hudAlpha;
		}
		if (scoreTxt != null) scoreTxt.alpha = ClientPrefs.data.hudAlpha;
		if (timeBar != null) timeBar.visible = (ClientPrefs.data.timeBarType != 'Disabled') && !ClientPrefs.data.hideHud;
	}

	function set_songSpeed(value:Float):Float { songSpeed = value; noteKillOffset = Math.max(Conductor.stepCrochet, 350 / songSpeed * playbackRate); return value; }
	function set_playbackRate(value:Float):Float { playbackRate = value; FlxG.animationTimeScale = value; return playbackRate; }

	public function reloadHealthBarColors() {
		healthBar.setColors(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) {
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startCountdown()
	{
		canPause = true;
		generateStaticArrows(0);
		generateStaticArrows(1);
		
		startedCountdown = true;
		Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;
		
		// --- VOXEL ENGINE OPTIMIZATION: Crossfade Fade In ---
		if (ClientPrefs.data.crossfade == 'Fade') {
			camGame.fade(FlxColor.BLACK, ClientPrefs.data.crossfadeSpeed, true);
		}

		moveCameraSection();
		return true;
	}

	inline private function createCountdownSprite(image:String, antialias:Bool):FlxSprite
	{
		var spr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(image));
		spr.cameras = [camHUD];
		spr.scrollFactor.set();
		spr.updateHitbox();
		spr.screenCenter();
		spr.antialiasing = antialias;
		insert(members.indexOf(noteGroup), spr);
		FlxTween.tween(spr, {alpha: 0}, Conductor.crochet / 1000, {
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween) { remove(spr); spr.destroy(); }
		});
		return spr;
	}

	public dynamic function updateScoreText()
	{
		var str:String = Language.getPhrase('rating_$ratingName', ratingName);
		if(totalPlayed != 0)
		{
			var percent:Float = CoolUtil.floorDecimal(ratingPercent * 100, 2);
			str += ' (${percent}%) - ' + Language.getPhrase(ratingFC);
		}

		// --- VOXEL ENGINE OPTIMIZATION: Minimal Score ---
		var tempScore:String;
		if (ClientPrefs.data.minimalScore) {
			tempScore = "Score: " + songScore;
		} else {
			if(!instakillOnMiss) tempScore = Language.getPhrase('score_text', 'Score: {1} | Misses: {2} | Rating: {3}', [songScore, songMisses, str]);
			else tempScore = Language.getPhrase('score_text_instakill', 'Score: {1} | Rating: {2}', [songScore, str]);
		}
		scoreTxt.text = tempScore;
	}

	public dynamic function updateScore(miss:Bool = false, scoreBop:Bool = true)
	{
		updateScoreText();
		if (!miss && !cpuControlled && scoreBop) doScoreBop();
	}

	public dynamic function fullComboFunction()
	{
		var sicks:Int = ratingsData[0].hits;
		var goods:Int = ratingsData[1].hits;
		var bads:Int = ratingsData[2].hits;
		var shits:Int = ratingsData[3].hits;

		ratingFC = "";
		if(songMisses == 0) {
			if (bads > 0 || shits > 0) ratingFC = 'FC';
			else if (goods > 0) ratingFC = 'GFC';
			else if (sicks > 0) ratingFC = 'SFC';
		} else {
			if (songMisses < 10) ratingFC = 'SDCB';
			else ratingFC = 'Clear';
		}
	}

	public function doScoreBop():Void {
		if(!ClientPrefs.data.scoreZoom) return;
		if(scoreTxtTween != null) scoreTxtTween.cancel();
		scoreTxt.scale.x = 1.075; scoreTxt.scale.y = 1.075;
		scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, { onComplete: function(twn:FlxTween) { scoreTxtTween = null; } });
	}

	function startSong():Void
	{
		startingSong = false;
		@:privateAccess FlxG.sound.playMusic(inst._sound, 1, false);
		FlxG.sound.music.onComplete = finishSong.bind();
		vocals.play(); opponentVocals.play();
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
	}

	private function generateSong():Void { generatedMusic = true; }
	function eventPushed(event:EventNote) {}
	function eventEarlyTrigger(event:EventNote):Float { return 0; }
	public static function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	private function generateStaticArrows(player:Int):Void
	{
		var strumLineX:Float = ClientPrefs.data.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X;
		var strumLineY:Float = ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50;
		for (i in 0...4)
		{
			var targetAlpha:Float = 1;
			if (player < 1) {
				if(!ClientPrefs.data.opponentStrums) targetAlpha = 0;
				else if(ClientPrefs.data.middleScroll) targetAlpha = 0.35;
			}
			var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player);
			babyArrow.downScroll = ClientPrefs.data.downScroll;
			babyArrow.alpha = targetAlpha;

			if (player == 1) playerStrums.add(babyArrow);
			else opponentStrums.add(babyArrow);
			strumLineNotes.add(babyArrow);
			babyArrow.playerPosition();
		}
	}

	public var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	override public function update(elapsed:Float)
	{
		if(!inCutscene && !paused) {
			FlxG.camera.followLerp = 0.04 * cameraSpeed * playbackRate;
		}

		super.update(elapsed);

		if (controls.PAUSE && startedCountdown && canPause) openPauseMenu();

		updateIconsScale(elapsed);
		updateIconsPosition();

		if (startedCountdown && !paused) {
			Conductor.songPosition += elapsed * 1000 * playbackRate;
		}

		if (startingSong) {
			if (startedCountdown && Conductor.songPosition >= Conductor.offset) startSong();
		}

		if (camZooming) {
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, Math.exp(-elapsed * 3.125 * camZoomingDecay * playbackRate));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, Math.exp(-elapsed * 3.125 * camZoomingDecay * playbackRate));
		}

		if (generatedMusic && !inCutscene) keysCheck();
	}

	public dynamic function updateIconsScale(elapsed:Float)
	{
		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, Math.exp(-elapsed * 9 * playbackRate));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult2:Float = FlxMath.lerp(1, iconP2.scale.x, Math.exp(-elapsed * 9 * playbackRate));
		iconP2.scale.set(mult2, mult2);
		iconP2.updateHitbox();
	}

	public dynamic function updateIconsPosition()
	{
		var iconOffset:Int = 26;
		iconP1.x = healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		iconP2.x = healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
	}

	function set_health(value:Float):Float
	{
		value = FlxMath.roundDecimal(value, 5); 
		
		// --- VOXEL ENGINE OPTIMIZATION: Smooth Health Bar ---
		if (ClientPrefs.data.smoothBar) {
			health = FlxMath.lerp(health, value, 0.15); // Lerp suave
		} else {
			health = value;
		}

		var newPercent:Null<Float> = FlxMath.remapToRange(FlxMath.bound(health, 0, 2), 0, 2, 0, 100);
		healthBar.percent = (newPercent != null ? newPercent : 0);

		iconP1.animation.curAnim.curFrame = (healthBar.percent < 20) ? 1 : 0;
		iconP2.animation.curAnim.curFrame = (healthBar.percent > 80) ? 1 : 0;
		return health;
	}

	function openPauseMenu()
	{
		paused = true;
		if(FlxG.sound.music != null) {
			FlxG.sound.music.pause();
			vocals.pause();
			opponentVocals.pause();
		}
		openSubState(new PauseSubState());
	}

	public function checkEventNote() {}
	public function triggerEvent(eventName:String, value1:String, value2:String, strumTime:Float) {}

	public function moveCameraSection(?sec:Null<Int>):Void {
		if(sec == null) sec = curSection;
		if(sec < 0) sec = 0;
		if(SONG.notes[sec] == null) return;
		var isDad:Bool = (SONG.notes[sec].mustHitSection != true);
		moveCamera(isDad);
	}

	public function moveCamera(isDad:Bool)
	{
		if(isDad && dad != null) {
			camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
		} else if (boyfriend != null) {
			camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];
		}
	}

	public function finishSong(?ignoreNoteOffset:Bool = false):Void { endCallback(); }
	public function endSong() { MusicBeatState.switchState(new FreeplayState()); return true; }

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;
	public var showCombo:Bool = true;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	public var comboGroup:FlxSpriteGroup;
	public var uiGroup:FlxSpriteGroup;
	public var noteGroup:FlxTypedGroup<FlxBasic>;

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset);
		vocals.volume = 1;

		var placement:Float = FlxG.width * 0.35;
		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		var daRating:Rating = Conductor.judgeNote(ratingsData, noteDiff / playbackRate);
		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		note.rating = daRating.name;
		score = daRating.score;

		// --- OPTIMIZACIÓN: DISABLE NOTE SPARKS / SPLASHES ---
		if(daRating.noteSplash && !ClientPrefs.data.disableSparks) spawnNoteSplashOnNote(note);

		if(!cpuControlled) {
			songScore += score;
			songHits++; totalPlayed++;
			RecalculateRating(false);
		}

		// --- VOXEL ENGINE OPTIMIZATION: Minimal Score ---
		if (ClientPrefs.data.minimalScore) return; // Si es minimalScore, no dibujamos Sprites de Puntuación.

		var uiFolder:String = "";
		var antialias:Bool = ClientPrefs.data.antialiasing && !ClientPrefs.data.lowQualityStage;

		rating.loadGraphic(Paths.image(uiFolder + daRating.image + uiPostfix));
		rating.screenCenter();
		rating.x = placement - 40; rating.y -= 60;
		rating.acceleration.y = 550 * playbackRate * playbackRate;
		rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
		rating.visible = (!ClientPrefs.data.hideHud && showRating);
		rating.antialiasing = antialias;
		comboGroup.add(rating);

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiFolder + 'combo' + uiPostfix));
		comboSpr.screenCenter();
		comboSpr.x = placement;
		comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
		comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
		comboSpr.visible = (!ClientPrefs.data.hideHud && showCombo);
		comboSpr.antialiasing = antialias;
		comboSpr.y += 60;
		if (showCombo) comboGroup.add(comboSpr);

		// --- VOXEL ENGINE OPTIMIZATION: Hide Combo Num ---
		if (ClientPrefs.data.hideComboNum) showComboNum = false;

		var separatedScore:String = Std.string(combo).lpad('0', 3);
		var daLoop:Int = 0;
		for (i in 0...separatedScore.length)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiFolder + 'num' + Std.parseInt(separatedScore.charAt(i)) + uiPostfix));
			numScore.screenCenter();
			numScore.x = placement + (43 * daLoop) - 90;
			numScore.y += 80;
			numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			numScore.visible = !ClientPrefs.data.hideHud;
			numScore.antialiasing = antialias;
			
			if(showComboNum) comboGroup.add(numScore);
			FlxTween.tween(numScore, {alpha: 0}, 0.2 / playbackRate, { onComplete: function(twn:FlxTween) { numScore.destroy(); }, startDelay: Conductor.crochet * 0.002 / playbackRate });
			daLoop++;
		}
		
		FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, { startDelay: Conductor.crochet * 0.001 / playbackRate });
		FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate, { onComplete: function(twn:FlxTween) { comboSpr.destroy(); rating.destroy(); }, startDelay: Conductor.crochet * 0.002 / playbackRate });
	}

	private function onKeyPress(event:KeyboardEvent):Void { var key:Int = getKeyFromEvent(keysArray, event.keyCode); if(key > -1) keyPressed(key); }
	private function onKeyRelease(event:KeyboardEvent):Void { var key:Int = getKeyFromEvent(keysArray, event.keyCode); if(key > -1) keyReleased(key); }
	
	private function keyPressed(key:Int) {}
	private function keyReleased(key:Int) {}
	public static function getKeyFromEvent(arr:Array<String>, key:FlxKey):Int return -1;

	// ----------------------------------------------------
	// PARTE 2 QUE ME MÁNDASTE HACE RATO:
	// ----------------------------------------------------
	private function keysCheck():Void
	{
		var holdArray:Array<Bool> = []; var pressArray:Array<Bool> = []; var releaseArray:Array<Bool> = [];
		for (key in keysArray) { holdArray.push(controls.pressed(key)); pressArray.push(controls.justPressed(key)); releaseArray.push(controls.justReleased(key)); }

		if(controls.controllerMode && pressArray.contains(true))
			for (i in 0...pressArray.length) if(pressArray[i]) keyPressed(i);

		if (notes.length > 0) {
			for (daNote in notes.members) {
				if (daNote != null && daNote.isSustainNote && daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit) {
					if (holdArray[daNote.noteData] || (controls.controllerMode && pressArray[daNote.noteData])) goodNoteHit(daNote);
				}
			}
		}

		if (controls.controllerMode && releaseArray.contains(true))
			for (i in 0...releaseArray.length) if(releaseArray[i]) keyReleased(i);
	}

	function playerDance():Void
	{
		if (boyfriend.holdingNote != null && !holdCheck(boyfriend.holdingNote)) boyfriend.holdingNote = null;
		if (boyfriend.holdingNote == null && boyfriend.animation.curAnim != null && boyfriend.animation.curAnim.finished) boyfriend.dance();
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit) {
			note.wasGoodHit = true; vocals.volume = 1;
			var isSustain:Bool = note.isSustainNote;

			if (note.hitCausesMiss) { noteMiss(note); if (!isSustain) invalidateNote(note); return; }

			if (!isSustain) { combo++; popUpScore(note); } else { if (!cpuControlled) songScore += 20; }
			if (health < 2 && note.hitsoundOK) health += 0.023 * healthGain;

			var spr:StrumNote = playerStrums.members[note.noteData];
			if (spr != null) { spr.playAnim('confirm', true); spr.resetAnim = 0.15; }

			if (note.noteType != 'No Animation') {
				var animToPlay:String = singAnimations[note.noteData];
				if (note.animSuffix != null) animToPlay += note.animSuffix;
				boyfriend.playAnim(animToPlay, true); boyfriend.holdTimer = 0;
			}
			if (!isSustain) invalidateNote(note);
		}
	}

	function opponentNoteHit(note:Note):Void
	{
		if (note.hitByOpponent) return;
		note.hitByOpponent = true; opponentVocals.volume = 1;

		var spr:StrumNote = opponentStrums.members[note.noteData];
		if (spr != null) { spr.playAnim('confirm', true); spr.resetAnim = 0.15; spr.alpha = ClientPrefs.data.opponentStrumAlpha; }

		if (note.noteType != 'No Animation') {
			var animToPlay:String = singAnimations[note.noteData];
			if (note.animSuffix != null) animToPlay += note.animSuffix;
			dad.playAnim(animToPlay, true); dad.holdTimer = 0;
		}
		if (!note.isSustainNote) invalidateNote(note);
	}

	function noteMiss(note:Note):Void
	{
		if (note.wasGoodHit) return;
		combo = 0; songMisses++; health -= 0.0475 * healthLoss;
		if (instakillOnMiss) health = 0;
		vocals.volume = 0;
		if (note.noteType != 'No Animation') {
			var animToPlay:String = singAnimations[note.noteData] + 'miss';
			if (note.animSuffix != null) animToPlay += note.animSuffix;
			boyfriend.playAnim(animToPlay, true);
		}
		updateScore(true);
	}

	function noteMissPress(direction:Int):Void
	{
		combo = 0; songMisses++; health -= pressMissDamage * healthLoss;
		if (instakillOnMiss) health = 0;
		vocals.volume = 0;
		var animToPlay:String = singAnimations[direction] + 'miss';
		boyfriend.playAnim(animToPlay, true);
		updateScore(true);
	}

	public function invalidateNote(note:Note):Void { note.kill(); notes.remove(note, true); note.destroy(); }

	public function RecalculateRating(badHit:Bool = false, updateTxt:Bool = true)
	{
		if (totalPlayed != 0) ratingPercent = totalNotesHit / totalPlayed; else ratingPercent = 0;
		fullComboFunction();
		for (i in 0...ratingStuff.length) {
			if (ratingPercent >= ratingStuff[i][1]) { ratingName = ratingStuff[i][0]; break; }
		}
		if (updateTxt) updateScoreText();
	}

	public function spawnNoteSplashOnNote(note:Note)
	{
		if (ClientPrefs.data.disableSparks) return; 
		if (ClientPrefs.data.noteSplashes && note != null) {
			var strum:StrumNote = playerStrums.members[note.noteData];
			if (strum != null) {
				var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
				splash.setupNoteSplash(strum.x, strum.y, note.noteData, note);
				splash.alpha = ClientPrefs.data.splashAlpha;
				grpNoteSplashes.add(splash);
			}
		}
	}

	function holdCheck(note:Note):Bool return note != null && note.isSustainNote && controls.pressed(keysArray[note.noteData]);

	function characterBopper(beat:Int):Void
	{
		if (beat % gfSpeed == 0 && gf != null) gf.dance();
		if (beat % dad.danceEveryNumBeats == 0 && dad != null) dad.dance();
		if (beat % boyfriend.danceEveryNumBeats == 0 && boyfriend != null) boyfriend.dance();

		// --- OPTIMIZACIÓN: LOW QUALITY STAGE ---
		if (!ClientPrefs.data.lowQualityStage) stagesFunc(function(stage:BaseStage) { stage.bopStageElements(beat); });

		// --- VOXEL ENGINE: ICON BOP STYLE ---
		if (iconP1 != null && iconP2 != null)
		{
			switch (ClientPrefs.data.iconBopStyle)
			{
				case 'Disabled':
					iconP1.scale.set(1, 1); iconP2.scale.set(1, 1);
				case 'Smooth':
					iconP1.scale.set(1.15, 1.15); iconP2.scale.set(1.15, 1.15);
					FlxTween.tween(iconP1.scale, {x: 1, y: 1}, 0.2, {ease: FlxEase.smoothStepOut});
					FlxTween.tween(iconP2.scale, {x: 1, y: 1}, 0.2, {ease: FlxEase.smoothStepOut});
				case 'Pixel':
					iconP1.scale.set(1.3, 1.3); iconP2.scale.set(1.3, 1.3);
				default: 
					iconP1.scale.set(1.2, 1.2); iconP2.scale.set(1.2, 1.2);
			}
		}
	}

	override function beatHit()
	{
		super.beatHit();
		characterBopper(curBeat);
	}

	// --- OPTIMIZACIÓN: LIMPIEZA DE MEMORIA RAM AL SALIR ---
	override public function destroy():Void
	{
		super.destroy();
		if (ClientPrefs.data.agressiveRAMClean) {
			Paths.clearUnusedMemory();
			#if cpp cpp.NativeGc.run(true); #end
			openfl.system.System.gc();
		}
	}
}