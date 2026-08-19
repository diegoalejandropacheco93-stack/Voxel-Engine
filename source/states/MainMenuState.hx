package states;

import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import states.editors.MasterEditorMenu;
import options.OptionsState;
import options.MenuLuaBGLoader;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import backend.ClientPrefs;
import backend.Paths;
import backend.Discord;
import backend.Achievements;
import backend.CoolUtil;
import backend.Mods;

enum MainMenuColumn {
	LEFT;
	CENTER;
	RIGHT;
}

class MainMenuState extends MusicBeatState
{
	// --- VERSIONES DEL MOTOR ---
	public static var voxelEngineVersion:String = '1.0.0'; // Tu versión de Voxel Engine
	public static var psychEngineVersion:String = '1.0.4'; // REQUERIDO para Discord RPC, Lua y Editores

	public static var curSelected:Int = 0;
	public static var curColumn:MainMenuColumn = CENTER;
	var allowMouse:Bool = true; // Turn this off to block mouse movement in menus

	var menuItems:FlxTypedGroup<FlxSprite>;
	var leftItem:FlxSprite;
	var rightItem:FlxSprite;

	// Centered/Text options
	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		#if MODS_ALLOWED 'mods', #end
		'credits'
	];

	var leftOption:String = #if ACHIEVEMENTS_ALLOWED 'achievements' #else null #end;
	var rightOption:String = 'options';

	var bg:FlxSprite;
	var magenta:FlxSprite;
	var camFollow:FlxObject;

	static var showOutdatedWarning:Bool = true;

	override function create()
	{
		super.create();

		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = 0.25;

		// 1. Instanciamos el cargador de fondo animado Lua
		var animatedBG:MenuLuaBGLoader = new MenuLuaBGLoader("menu_test");

		// --- VOXEL ENGINE OPTIMIZATION ---
		// 2. Evaluamos el estado desde el archivo Lua ANTES de cargar imágenes
		if (animatedBG.isActive)
		{
			// Si hay fondo animado, SOLO añadimos el animado (Ahorramos muchísima RAM)
			add(animatedBG);
		}
		else
		{
			// 3. Si no hay fondo animado, cargamos los clásicos de Psych Engine
			bg = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
			bg.antialiasing = ClientPrefs.data.antialiasing;
			bg.scrollFactor.set(0, yScroll);
			bg.setGraphicSize(Std.int(bg.width * 1.175));
			bg.updateHitbox();
			bg.screenCenter();
			add(bg);

			magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
			magenta.antialiasing = ClientPrefs.data.antialiasing;
			magenta.scrollFactor.set(0, yScroll);
			magenta.setGraphicSize(Std.int(magenta.width * 1.175));
			magenta.updateHitbox();
			magenta.screenCenter();
			magenta.visible = false;
			magenta.color = 0xFFfd719b;
			add(magenta);
		}

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		for (i in 0...optionShit.length)
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(0, (i * 140) + offset);
			menuItem.antialiasing = ClientPrefs.data.antialiasing;
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItem.screenCenter(X);
			menuItems.add(menuItem);
			var scr:Float = (optionShit.length - 4) * 0.135;
			if (optionShit.length < 6) scr = 0;
			menuItem.scrollFactor.set(0, scr);
			menuItem.updateHitbox();
		}

		if (leftOption != null)
		{
			leftItem = new FlxSprite(20, 0);
			leftItem.antialiasing = ClientPrefs.data.antialiasing;
			leftItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + leftOption);
			leftItem.animation.addByPrefix('idle', leftOption + " basic", 24);
			leftItem.animation.addByPrefix('selected', leftOption + " white", 24);
			leftItem.animation.play('idle');
			leftItem.screenCenter(Y);
			add(leftItem);
		}

		if (rightOption != null)
		{
			rightItem = new FlxSprite(0, 0);
			rightItem.antialiasing = ClientPrefs.data.antialiasing;
			rightItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + rightOption);
			rightItem.animation.addByPrefix('idle', rightOption + " basic", 24);
			rightItem.animation.addByPrefix('selected', rightOption + " white", 24);
			rightItem.animation.play('idle');
			rightItem.screenCenter(Y);
			rightItem.x = FlxG.width - rightItem.width - 20;
			add(rightItem);
		}

		var psychVer:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		psychVer.scrollFactor.set();
		psychVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(psychVer);

		var voxelVer:FlxText = new FlxText(12, FlxG.height - 24, 0, "Voxel Engine v" + voxelEngineVersion, 12);
		voxelVer.scrollFactor.set();
		voxelVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(voxelVer);

		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		// Unlocks "Freaky on a Friday Night" achievement if played on Friday after 6 PM
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			Achievements.unlock('friday_night_play');

		#if MODS_ALLOWED
		Achievements.reloadList();
		#end
		#end

		super.create();

		FlxG.camera.follow(camFollow, null, 0.15);
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * elapsed;
			if (FreeplayState.vocals != null)
				FreeplayState.vocals.volume += 0.5 * elapsed;
		}

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
				changeItem(-1);

			if (controls.UI_DOWN_P)
				changeItem(1);

			if (controls.UI_LEFT_P || controls.UI_RIGHT_P)
			{
				if (leftOption != null || rightOption != null)
				{
					if (curColumn == CENTER)
					{
						if (controls.UI_LEFT_P && leftOption != null)
							curColumn = LEFT;
						else if (controls.UI_RIGHT_P && rightOption != null)
							curColumn = RIGHT;

						if (curColumn != CENTER)
							FlxG.sound.play(Paths.sound('scrollMenu'));
					}
					else if (curColumn == LEFT && controls.UI_RIGHT_P)
					{
						curColumn = CENTER;
						FlxG.sound.play(Paths.sound('scrollMenu'));
					}
					else if (curColumn == RIGHT && controls.UI_LEFT_P)
					{
						curColumn = CENTER;
						FlxG.sound.play(Paths.sound('scrollMenu'));
					}
				}
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				selectedSomethin = true;

				// --- VOXEL ENGINE OPTIMIZATION ---
				// Solo activamos el destello magenta si realmente existe (si Lua estaba desactivado)
				if (magenta != null)
					magenta.visible = true;

				var item:FlxSprite = null;
				var option:String = '';

				switch (curColumn)
				{
					case CENTER:
						option = optionShit[curSelected];
						item = menuItems.members[curSelected];
					case LEFT:
						option = leftOption;
						item = leftItem;
					case RIGHT:
						option = rightOption;
						item = rightItem;
				}

				FlxFlicker.flicker(item, 1, 0.06, false, false, function(flick:FlxFlicker)
				{
					switch (option)
					{
						case 'story_mode':
							MusicBeatState.switchState(new StoryMenuState());
						case 'freeplay':
							MusicBeatState.switchState(new FreeplayState());
						#if MODS_ALLOWED
						case 'mods':
							MusicBeatState.switchState(new ModsMenuState());
						#end
						case 'achievements':
							MusicBeatState.switchState(new AchievementsMenuState());
						case 'credits':
							MusicBeatState.switchState(new CreditsState());
						case 'options':
							MusicBeatState.switchState(new OptionsState());
							OptionsState.onPlayState = false;
							if (PlayState.SONG != null)
							{
								PlayState.SONG.arrowSkin = null;
								PlayState.SONG.splashSkin = null;
								PlayState.stageUI = 'normal';
							}
						case 'donate':
							CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
							selectedSomethin = false;
							item.visible = true;
						default:
							trace('Menu Item ${option} doesn\'t do anything');
							selectedSomethin = false;
							item.visible = true;
					}
				});

				for (memb in menuItems)
				{
					if (memb == item)
						continue;

					FlxTween.tween(memb, {alpha: 0}, 0.4, {ease: FlxEase.quadOut});
				}
			}
			#if desktop
			if (controls.justPressed('debug_1'))
			{
				selectedSomethin = true;
				FlxG.mouse.visible = false;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);
	}

	function changeItem(change:Int = 0)
	{
		if (change != 0) curColumn = CENTER;
		curSelected = FlxMath.wrap(curSelected + change, 0, optionShit.length - 1);
		FlxG.sound.play(Paths.sound('scrollMenu'));

		for (item in menuItems)
		{
			item.animation.play('idle');
			item.updateHitbox();

			if (item.ID == curSelected && curColumn == CENTER)
			{
				item.animation.play('selected');
				var camCenter:Float = item.getGraphicMidpoint().y;
				camFollow.setPosition(item.getGraphicMidpoint().x, camCenter);
				item.offset.x = 0.15 * (item.frameWidth / 2);
				item.offset.y = 0.15 * (item.frameHeight / 2);
			}
		}

		if (leftItem != null)
		{
			leftItem.animation.play(curColumn == LEFT ? 'selected' : 'idle');
			leftItem.updateHitbox();
		}

		if (rightItem != null)
		{
			rightItem.animation.play(curColumn == RIGHT ? 'selected' : 'idle');
			rightItem.updateHitbox();
		}
	}
}