package debug;

import flixel.FlxG;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.system.System;
import openfl.filters.DropShadowFilter;

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
class FPSCounter extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;

	/**
		The current memory usage (WARNING: this is NOT your total program memory usage, rather it shows the garbage collector memory)
	**/
	public var memoryMegas(get, never):Float;
	public var memoryPeak:Float = 0;

	@:noCompletion private var times:Array<Float>;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0xFFFFFF)
	{
		super();

		this.x = x;
		this.y = y;

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		
		// Fuente profesional y suave estilo Voxel Engine
		defaultTextFormat = new TextFormat("_sans", 13, color, true);
		autoSize = LEFT;
		multiline = true;
		
		// Transparencia sutil para que se note pero no moleste en pantalla
		this.alpha = 0.85;

		// Sombra sutil para lectura perfecta sobre cualquier stage
		this.filters = [new DropShadowFilter(2, 45, 0x000000, 0.8, 2, 2, 1)];

		text = "FPS: 0\nRAM: 0 MB";

		times = [];
	}

	var deltaTimeout:Float = 0.0;

	// Event Handlers
	private override function __enterFrame(deltaTime:Float):Void
	{
		final now:Float = haxe.Timer.stamp() * 1000;
		times.push(now);
		while (times[0] < now - 1000) times.shift();

		if (deltaTimeout < 50) {
			deltaTimeout += deltaTime;
			return;
		}

		currentFPS = times.length < FlxG.updateFramerate ? times.length : FlxG.updateFramerate;		
		updateText();
		deltaTimeout = 0.0;
	}

	public dynamic function updateText():Void {
		var curMem:Float = memoryMegas;
		if (curMem > memoryPeak) memoryPeak = curMem;

		text = 'FPS: ${currentFPS}'
			+ '\nRAM: ${flixel.util.FlxStringUtil.formatBytes(curMem)} / ${flixel.util.FlxStringUtil.formatBytes(memoryPeak)}';

		textColor = 0xFFFFFFFF;
		if (currentFPS < FlxG.drawFramerate * 0.5)
			textColor = 0xFFFF4444; // Rojo suave para caídas de FPS
	}

	inline function get_memoryMegas():Float
	{
		#if cpp
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);
		#else
		return System.totalMemory;
		#end
	}
}