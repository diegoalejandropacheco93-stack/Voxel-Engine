package options;

import openfl.Lib;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;

class GraphicsSettingsSubState extends BaseOptionsMenu
{
	var resolutionOption:Option;
	var renderScaleOption:Option;

	public function new()
	{
		title = 'Graphic & RAM Optimization';
		rpcTitle = 'Graphics Settings Menu';

		// --- RESOLUCIÓN Y ESCALADO DE RENDER (VOXEL ENGINE) ---
		var resolutions:Array<String> = getSupportedResolutions();
		resolutionOption = new Option('Display Resolution:',
			'Changes the game window resolution to fit your display.',
			'resolution',
			'string',
			resolutions);
		addOption(resolutionOption);
		resolutionOption.onChange = onChangeResolution;

		// Botón de activación del Render Scale
		var enableScaleOption:Option = new Option('Enable Render Scale',
			'Enable custom resolution scaling to lower render quality and boost performance.',
			'enableRenderScale',
			'bool');
		addOption(enableScaleOption);
		enableScaleOption.onChange = onChangeEnableRenderScale;

		// Deslizador de porcentaje
		renderScaleOption = new Option('Render Scale:',
			'Lowering this pixelates the internal rendering scale (10% - 100%).',
			'renderScale',
			'percent');
		addOption(renderScaleOption);
		renderScaleOption.scrollSpeed = 1.6;
		renderScaleOption.minValue = 0.1; // 10% mínimo
		renderScaleOption.maxValue = 1.0; // 100% Nativo
		renderScaleOption.changeValue = 0.1;
		renderScaleOption.decimals = 1;
		renderScaleOption.onChange = onChangeRenderScale;

		// --- OPTIMIZACIONES VOXEL ENGINE ---
		var option:Option = new Option('Agressive RAM Clean',
			'If checked, forces memory release when switching songs to keep RAM usage extremely low.',
			'agressiveRAMClean',
			'bool');
		addOption(option);

		var option:Option = new Option('Disable Note Sparks',
			'If checked, disables hit particles to save GPU and CPU resources.',
			'disableSparks',
			'bool');
		addOption(option);

		var option:Option = new Option('Low Quality Stage',
			'If checked, disables animated background elements for maximum performance.',
			'lowQualityStage',
			'bool');
		addOption(option);

		// --- OPCIONES GRÁFICAS ORIGINALES DE PSYCH ---
		var option:Option = new Option('Low Quality',
			'If checked, disables some background details, decreases loading times and improves performance.',
			'lowQuality',
			'bool');
		addOption(option);

		var option:Option = new Option('Anti-Aliasing',
			'If unchecked, disables anti-aliasing, increasing performance at the cost of sharper edges.',
			'antialiasing',
			'bool');
		option.onChange = onChangeAntiAliasing;
		addOption(option);

		var option:Option = new Option('Shaders',
			'If unchecked, disables shaders. It\'s used for some visual effects, and also CPU heavy for weak PCs.',
			'shaders',
			'bool');
		addOption(option);

		var option:Option = new Option('GPU Caching',
			'If checked, allows the GPU to be used for caching textures, decreasing RAM usage.',
			'cacheOnGPU',
			'bool');
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
		updateRenderScaleState();
	}

	function getSupportedResolutions():Array<String>
	{
		var list:Array<String> = [];
		try
		{
			var display = FlxG.stage.application.window.display;
			if (display != null && display.supportedModes != null)
			{
				for (mode in display.supportedModes)
				{
					var resStr:String = mode.width + 'x' + mode.height;
					if (!list.contains(resStr))
						list.push(resStr);
				}
			}
		}
		catch(e:Dynamic) {}

		if (list.length == 0)
			list = ['1920x1080', '1600x900', '1366x768', '1280x720', '1024x768', '800x600', '640x480'];

		return list;
	}

	function onChangeResolution()
	{
		var resVal:String = ClientPrefs.data.resolution;
		if (resVal != null && resVal.contains('x'))
		{
			var splitRes:Array<String> = resVal.split('x');
			var width:Int = Std.parseInt(splitRes[0]);
			var height:Int = Std.parseInt(splitRes[1]);

			if (width > 0 && height > 0)
			{
				FlxG.resizeWindow(width, height);
				FlxG.resizeGame(width, height);
			}
		}
	}

	function onChangeEnableRenderScale()
	{
		updateRenderScaleState();
	}

	function updateRenderScaleState()
	{
		var enabled:Bool = ClientPrefs.data.enableRenderScale;
		
		if (!enabled)
		{
			// Si está desactivado, restaura la escala al 100% nativo
			FlxG.game.scaleX = 1.0;
			FlxG.game.scaleY = 1.0;
			FlxG.game.stage.quality = openfl.display.StageQuality.HIGH;
		}
		else
		{
			// Aplica el porcentaje actual guardado
			onChangeRenderScale();
		}
	}

	function onChangeRenderScale()
	{
		if (!ClientPrefs.data.enableRenderScale) return;

		var scale:Float = ClientPrefs.data.renderScale;
		if (scale <= 0) scale = 0.1;

		FlxG.game.scaleX = scale;
		FlxG.game.scaleY = scale;

		if (scale < 1.0)
			FlxG.game.stage.quality = openfl.display.StageQuality.LOW;
		else
			FlxG.game.stage.quality = openfl.display.StageQuality.HIGH;
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