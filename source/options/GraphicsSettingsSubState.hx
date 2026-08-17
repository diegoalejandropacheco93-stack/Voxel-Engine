package options;

class GraphicsSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Graphic & RAM Optimization';
		rpcTitle = 'Graphics Settings Menu';

		// Opción 1: Limpieza agresiva de memoria RAM
		var option:Option = new Option('Agressive RAM Clean',
			'If checked, forces memory release when switching songs to keep RAM usage extremely low.',
			'agressiveRAMClean',
			'bool');
		addOption(option);

		// Opción 2: Desactivar partículas de impacto de notas
		var option:Option = new Option('Disable Note Sparks',
			'If checked, disables hit particles to save GPU and CPU resources.',
			'disableSparks',
			'bool');
		addOption(option);

		// Opción 3: Reducir animaciones pesadas en el escenario
		var option:Option = new Option('Low Quality Stage',
			'If checked, disables animated background elements for maximum performance.',
			'lowQualityStage',
			'bool');
		addOption(option);

		// Opción de Antialiasing original
		var option:Option = new Option('Anti-Aliasing',
			'If unchecked, disables anti-aliasing, increasing performance at the cost of sharper edges.',
			'antialiasing',
			'bool');
		option.onChange = onChangeAntiAliasing;
		addOption(option);

		// Configuración de FPS límite
		var option:Option = new Option('Framerate',
			'Pretty self-explanatory, isn\'t it?',
			'framerate',
			'int');
		addOption(option);
		option.minValue = 60;
		option.maxValue = 240;
		option.displayFormat = '%v FPS';
		option.onChange = onChangeFramerate;

		super();
	}

	function onChangeAntiAliasing()
	{
		for (sprite in members)
		{
			var sprite:FlxSprite = cast sprite;
			if(sprite != null && (sprite is FlxSprite) && !(sprite is FlxText)) {
				sprite.antialiasing = ClientPrefs.data.antialiasing;
			}
		}
	}

	function onChangeFramerate()
	{
		if(ClientPrefs.data.framerate > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = ClientPrefs.data.framerate;
			FlxG.drawFramerate = ClientPrefs.data.framerate;
		}
		else
		{
			FlxG.drawFramerate = ClientPrefs.data.framerate;
			FlxG.updateFramerate = ClientPrefs.data.framerate;
		}
	}
}