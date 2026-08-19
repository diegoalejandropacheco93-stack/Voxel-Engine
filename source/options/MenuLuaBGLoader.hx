package options;

import flixel.FlxSprite;
import flixel.FlxG;
import backend.Paths;
import backend.ClientPrefs;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

class MenuLuaBGLoader extends FlxSprite
{
	public var isActive:Bool = false;

	public function new(folderName:String)
	{
		super(0, 0);

		// Busca la ruta del archivo config.lua
		var configPath = Paths.getSharedPath('images/menu_bgs/' + folderName + '/config.lua');
		
		#if sys
		if (FileSystem.exists(configPath))
		{
			// Leemos el archivo lua como texto puro (Súper rápido y optimizado)
			var fileContent = File.getContent(configPath);
			
			// Extraemos las variables usando nuestras funciones de abajo
			var active:Bool = parseBool(fileContent, "active");
			var imagePath:String = parseString(fileContent, "image_path");
			var xmlAnim:String = parseString(fileContent, "xml_animation");
			var fps:Int = parseInt(fileContent, "anim_fps", 24);
			var loop:Bool = parseBool(fileContent, "loop");

			this.isActive = active;

			if (this.isActive)
			{
				// Cargamos el XML y la imagen
				frames = Paths.getSparrowAtlas(imagePath);
				animation.addByPrefix('idle', xmlAnim, fps, loop);
				animation.play('idle');

				// --- AQUÍ ESTÁ LA SOLUCIÓN AL RESCALADO ---
				// Esto forza a la imagen a ser del ancho de la pantalla (1280)
				// y ajusta el alto automáticamente sin deformar el dibujo.
				setGraphicSize(FlxG.width); 
				updateHitbox();
				
				// Lo centramos perfecto en la pantalla
				screenCenter();
				
				// Aplicamos la configuración de calidad del Voxel Engine
				antialiasing = ClientPrefs.data.antialiasing;
			}
		}
		else
		{
			trace("¡ERROR! No se encontró el config.lua en: " + configPath);
		}
		#end
	}

	// ========================================================
	// FUNCIONES PARA LEER EL LUA SIN SOBRECARGAR LA MEMORIA
	// ========================================================
	
	private function parseString(content:String, variable:String):String {
		// Busca algo como: image_path = "ruta/imagen"
		var regex = new EReg(variable + '\\s*=\\s*"([^"]+)"', "i");
		if (regex.match(content)) return regex.matched(1);
		return "";
	}

	private function parseBool(content:String, variable:String):Bool {
		// Busca algo como: active = true
		var regex = new EReg(variable + '\\s*=\\s*(true|false)', "i");
		if (regex.match(content)) return regex.matched(1) == "true";
		return false;
	}

	private function parseInt(content:String, variable:String, defaultValue:Int):Int {
		// Busca algo como: anim_fps = 24
		var regex = new EReg(variable + '\\s*=\\s*([0-9]+)', "i");
		if (regex.match(content)) return Std.parseInt(regex.matched(1));
		return defaultValue;
	}
}