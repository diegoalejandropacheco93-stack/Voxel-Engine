package options;

import openfl.Lib;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import backend.ClientPrefs;

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
			STRING,
			resolutions);
		addOption(resolutionOption);
		resolutionOption.onChange = onChangeResolution;

		// Botón de activación del Render Scale
		var enableScaleOption:Option = new Option('Enable Render Scale',
			'Enable custom resolution scaling to lower render quality and boost performance.',
			'enableRenderScale',
			BOOL);
		addOption(enableScaleOption);
		enableScaleOption.onChange = onChangeEnableRenderScale;

		// Deslizador de porcentaje
		renderScaleOption = new Option('Render Scale:',
			'Lowering this pixelates the internal rendering scale (10% - 100%).',
			'renderScale',
			PERCENT);
		addOption(renderScaleOption);
		renderScaleOption.scrollSpeed = 1.6;
		renderScaleOption.minValue = 0.1; // 10% mínimo
		renderScaleOption.maxValue = 1.0; // 100% Nativo
		renderScaleOption.displayFormat = '%v%';
		renderScaleOption.onChange = onChangeRenderScale;

		// --- OPTIMIZACIONES VOXEL ENGINE ---
		var option:Option = new Option('Agressive RAM Clean',
			'If checked, forces memory release when switching songs to keep RAM usage extremely low.',
			'agressiveRAMClean',
			BOOL);
		addOption(option);

		var option:Option = new Option('Disable Note Sparks',
			'If checked, disables hit particles to save GPU and CPU resources.',
			'disableSparks',
			BOOL);
		addOption(option);

		var option:Option = new Option('Low Quality Stage',
			'If checked, disables animated background elements for maximum performance.',
			'lowQualityStage',
			BOOL);
		addOption(option);

		// --- EFECTOS VISUALES Y SHADERS ---
		var bloomOption:Option = new Option('Bloom Effect',
			'If checked, applies global bloom shader to all game screens.',
			'bloom',
			BOOL);
		addOption(bloomOption);
		bloomOption.onChange = onChangeBloom;

		var option:Option = new Option('Low Quality',
			'If checked, disables some background details, decreases loading times and improves performance.',
			'lowQuality',
			BOOL);
		addOption(option);

		var option:Option = new Option('Anti-Aliasing',
			'If unchecked, disables anti-aliasing, increasing performance at the cost of sharper edges.',
			'antialiasing',
			BOOL);
		option.onChange = onChangeAntiAliasing;
		addOption(option);

		var option:Option = new Option('Shaders',
			'If unchecked, disables shaders. It\'s used for some visual effects, and also CPU heavy for weak PCs.',
			'shaders',
			BOOL);
		option.onChange = onChangeShaders;
		addOption(option);

		var option:Option = new Option('GPU Caching',
			'If checked, allows the GPU to be used for caching textures, decreasing RAM usage.',
			'cacheOnGPU',
			BOOL);
		addOption(option);

		// Configuración de FPS límite
		var option:Option = new Option('Framerate',
			'Pretty self-explanatory, isn\'t it?',
			'framerate',
			INT);
		addOption(option);
		option.minValue = 60;
		option.maxValue = 240;
		option.displayFormat = '%v FPS';
		option.onChange = onChangeFramerate;

		super();
	}

	function getSupportedResolutions():Array<String>
	{
		return ['1280x720', '1920x1080', '1024x576', '800x600'];
	}

	function onChangeResolution()
	{
		if (resolutionOption != null && resolutionOption.getValue() != null)
		{
			var resStr:String = resolutionOption.getValue();
			var parts:Array<String> = resStr.split('x');
			if (parts.length == 2)
			{
				var width:Int = Std.parseInt(parts[0]);
				var height:Int = Std.parseInt(parts[1]);
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
			FlxG.game.scaleX = 1.0;
			FlxG.game.scaleY = 1.0;
			FlxG.stage.quality = openfl.display.StageQuality.HIGH;
		}
		else
		{
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
			FlxG.stage.quality = openfl.display.StageQuality.LOW;
		else
			FlxG.stage.quality = openfl.display.StageQuality.HIGH;
	}

	function onChangeBloom()
	{
		#if (openfl && !mobile)
		ClientPrefs.reloadBloom();
		#end
	}

	function onChangeShaders()
	{
		#if (openfl && !mobile)
		ClientPrefs.reloadBloom();
		#end
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