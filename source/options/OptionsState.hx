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

	// Variable para detectar si el modo secreto (Tecla 7) está activo
	var isSecretMode:Bool = false;

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
					menuBG.visible = true;
				}
				openSubState(new options.ControlsSubState());

			case 'Graphics':
				if(menuBG != null) {
					menuBG.loadGraphic(Paths.image('MenuOption'));
					menuBG.color = 0xFFFFFFFF;
					menuBG.visible = true;
				}
				openSubState(new options.GraphicsSettingsSubState());

			case 'Visuals':
				if(menuBG != null) {
					menuBG.loadGraphic(Paths.image('MenuOption'));
					menuBG.color = 0xFFFFFFFF;
					menuBG.visible = true;
				}
				openSubState(new options.VisualsSettingsSubState());

			case 'Gameplay':
				if(menuBG != null) {
					menuBG.loadGraphic(Paths.image('MenuOption'));
					menuBG.color = 0xFFFFFFFF;
					menuBG.visible = true;
				}
				openSubState(new options.GameplaySettingsSubState());

			case 'Adjust Delay and Combo':
				MusicBeatState.switchState(new options.NoteOffsetState());

			case 'Language':
				openSubState(new options.LanguageSubState());
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end

		menuBG = new FlxSprite().loadGraphic(Paths.image('MenuOption'));
		menuBG.antialiasing = ClientPrefs.data.antialiasing;
		menuBG.color = 0xFFFFFFFF;
		menuBG.updateHitbox();
		menuBG.screenCenter();
		add(menuBG);

		// Reproducir música personalizada del menú de opciones si existe
		if (Paths.fileExists('music/MusicOption.ogg', SOUND))
			FlxG.sound.playMusic(Paths.music('MusicOption'), 1, true);

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

		// Restaurar el fondo personalizado de Voxel Engine si volvemos de sub-estados como Controls
		if (menuBG != null) {
			if (!isSecretMode)
				menuBG.loadGraphic(Paths.image('MenuOption'));
			else
				menuBG.loadGraphic(Paths.image('Option7'));

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