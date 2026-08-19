package options;

import states.MainMenuState;
import backend.StageData;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import objects.Alphabet;
import backend.ClientPrefs; // Necesario para el antialiasing
import backend.Paths;
import backend.Language;
#if DISCORD_ALLOWED
import backend.Discord;
#end

class OptionsState extends MusicBeatState
{
	var options:Array<String> = [
		'Note Colors',
		'Controls',
		'Adjust Delay and Combo',
		'Graphics',
		'Visuals',
		'Gameplay'
		#if TRANSLATIONS_ALLOWED , 'Language' #end
	];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;

	var isSecretMode:Bool = false;
	
	// Variable para rastrear que nuestra música está sonando y no reiniciarla a cada rato
	public static var optionMusicPlaying:Bool = false;

	function openSelectedSubstate(label:String) {
		switch(label)
		{
			case 'Note Colors':
				if(menuBG != null) menuBG.visible = false;
				openSubState(new options.NotesColorSubState());

			case 'Controls':
				if(menuBG != null) {
					menuBG.loadGraphic(Paths.image('menuDesat'));
					menuBG.color = 0xFF2B3A82;
					// Optimización: Aseguramos que cubra la pantalla igual
					menuBG.setGraphicSize(FlxG.width);
					menuBG.updateHitbox();
					menuBG.screenCenter();
					menuBG.visible = true;
				}
				openSubState(new options.ControlsSubState());

			case 'Graphics':
				if(menuBG != null) menuBG.visible = true;
				openSubState(new options.GraphicsSettingsSubState());

			case 'Visuals':
				if(menuBG != null) menuBG.visible = true;
				openSubState(new options.VisualsSettingsSubState());

			case 'Gameplay':
				if(menuBG != null) menuBG.visible = true;
				openSubState(new options.GameplaySettingsSubState());

			case 'Adjust Delay and Combo':
				if(menuBG != null) menuBG.visible = true;
				MusicBeatState.switchState(new options.NoteOffsetState());

			#if TRANSLATIONS_ALLOWED
			case 'Language':
				if(menuBG != null) menuBG.visible = true;
				openSubState(new options.LanguageSubState());
			#end
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end

		// Reproducir música de opciones de forma inteligente
		if (!optionMusicPlaying)
		{
			FlxG.sound.playMusic(Paths.music('MusicOption'), 0.7, true);
			optionMusicPlaying = true;
		}

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('MenuOption'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.color = 0xFFFFFFFF;
		// Hacemos que siempre se ajuste al ancho de la pantalla, evitando bordes negros
		bg.setGraphicSize(FlxG.width); 
		bg.updateHitbox();
		bg.screenCenter();
		bg.active = false; // Optimización de rendimiento (Voxel Engine)
		add(bg);
		menuBG = bg;

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, 0, Language.getPhrase('options_${options[i]}', options[i]), true);
			optionText.screenCenter();
			optionText.y += (100 * (i - (options.length / 2))) + 50;
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true);
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true);
		add(selectorRight);

		changeSelection();
		ClientPrefs.saveSettings();

		super.create();
	}

	override function closeSubState()
	{
		super.closeSubState();
		ClientPrefs.saveSettings();

		if (menuBG != null) {
			if (!isSecretMode)
				menuBG.loadGraphic(Paths.image('MenuOption'));
			else
				menuBG.loadGraphic(Paths.image('Option7'));

			menuBG.setGraphicSize(FlxG.width);
			menuBG.updateHitbox();
			menuBG.screenCenter();
			menuBG.color = 0xFFFFFFFF;
			menuBG.visible = true;
		}

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (controls.UI_UP_P)
			changeSelection(-1);
		if (controls.UI_DOWN_P)
			changeSelection(1);

		if (FlxG.keys.justPressed.SEVEN)
		{
			isSecretMode = !isSecretMode;
			FlxG.sound.play(Paths.sound('scrollMenu'));
			
			if (menuBG != null)
			{
				if (isSecretMode)
					menuBG.loadGraphic(Paths.image('Option7'));
				else
					menuBG.loadGraphic(Paths.image('MenuOption'));
				
				menuBG.color = 0xFFFFFFFF;
				menuBG.setGraphicSize(FlxG.width);
				menuBG.updateHitbox();
				menuBG.screenCenter();
			}
		}

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			optionMusicPlaying = false; // Reiniciamos el tracker al salir

			if(onPlayState)
			{
				StageData.loadDirectory(PlayState.SONG);
				LoadingState.loadAndSwitchState(new PlayState());
				FlxG.sound.music.volume = 0;
			}
			else
			{
				// Devolvemos la música del menú principal
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				MusicBeatState.switchState(new MainMenuState());
			}
		}
		else if (controls.ACCEPT) 
		{
			openSelectedSubstate(options[curSelected]);
		}
	}
	
	function changeSelection(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);

		for (i in 0...grpOptions.members.length)
		{
			var item = grpOptions.members[i];
			item.targetY = i - curSelected;

			if (item.targetY == 0)
			{
				item.alpha = 1;
				selectorLeft.x = item.x - 60;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
			else
			{
				item.alpha = 0.6;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
}