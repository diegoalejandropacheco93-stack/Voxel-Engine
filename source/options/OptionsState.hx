package options;

import states.MainMenuState;
import backend.StageData;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;

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

	// Variable para detectar si el modo tecla 7 está activo
	var isSecretMode:Bool = false;

	function openSelectedSubstate(label:String) {
		switch(label)
		{
			case 'Note Colors':
				// Oculta el fondo para no estorbar en la edición de color
				if(menuBG != null) menuBG.visible = false;
				openSubState(new options.NotesColorSubState());

			case 'Controls':
				// Muestra el fondo clásico FNF teñido de azul
				if(menuBG != null) {
					menuBG.loadGraphic(Paths.image('menuDesat'));
					menuBG.color = 0xFF2B3A82;
					menuBG.visible = true;
				}
				openSubState(new options.ControlsSubState());

			case 'Graphics':
				openSubState(new options.GraphicsSettingsSubState());

			case 'Visuals':
				openSubState(new options.VisualsSettingsSubState());

			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());

			case 'Adjust Delay and Combo':
				// Se apaga el fondo y la música al ir al editor de combo
				if(FlxG.sound.music != null) FlxG.sound.music.stop();
				MusicBeatState.switchState(new options.NoteOffsetState());

			case 'Language':
				#if TRANSLATIONS_ALLOWED
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

		// Reproduce MusicOption de assets/shared/music
		if(FlxG.sound.music == null || !FlxG.sound.music.playing)
			FlxG.sound.playMusic(Paths.music('MusicOption'), 0.7);

		// Zoom suave al entrar al menú
		FlxG.camera.zoom = 1.03;
		FlxTween.tween(FlxG.camera, {zoom: 1}, 0.25, {ease: FlxEase.cubeOut});

		// Carga la imagen MenuOption de assets/shared/images
		menuBG = new FlxSprite().loadGraphic(Paths.image('MenuOption'));
		menuBG.antialiasing = ClientPrefs.data.antialiasing;
		menuBG.color = 0xFFFFFFFF;
		menuBG.updateHitbox();
		menuBG.screenCenter();
		add(menuBG);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (num => option in options)
		{
			var optionText:Alphabet = new Alphabet(0, 0, Language.getPhrase('options_$option', option), true);
			optionText.screenCenter();
			optionText.y += (92 * (num - (options.length / 2))) + 45;
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

	// Pequeño golpe/zoom de cámara que va a la par de la música
	override function beatHit()
	{
		super.beatHit();
		if (FlxG.camera != null)
		{
			FlxG.camera.zoom = 1.015;
			FlxTween.tween(FlxG.camera, {zoom: 1.0}, 0.15, {ease: FlxEase.quadOut});
		}
	}

	override function closeSubState()
	{
		super.closeSubState();
		ClientPrefs.saveSettings();

		// Restaura la imagen adecuada al salir de sub-estados
		if(menuBG != null) {
			menuBG.visible = true;
			if(isSecretMode) {
				menuBG.loadGraphic(Paths.image('Option7'));
			} else {
				menuBG.loadGraphic(Paths.image('MenuOption'));
			}
			menuBG.color = 0xFFFFFFFF;
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

		// Tecla 7: Cambia el fondo a Option7 únicamente al presionarla
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
			}
		}

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if(onPlayState)
			{
				StageData.loadDirectory(PlayState.SONG);
				LoadingState.loadAndSwitchState(new PlayState());
				FlxG.sound.music.volume = 0;
			}
			else
			{
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				MusicBeatState.switchState(new MainMenuState());
			}
		}
		else if (controls.ACCEPT) openSelectedSubstate(options[curSelected]);
	}
	
	function changeSelection(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);

		for (num => item in grpOptions.members)
		{
			item.targetY = num - curSelected;
			item.alpha = 0.6;
			if (item.targetY == 0)
			{
				item.alpha = 1;
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		super.destroy();
	}
}