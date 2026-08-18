private function keysCheck():Void
	{
		// HOLDING
		var holdArray:Array<Bool> = [];
		var pressArray:Array<Bool> = [];
		var releaseArray:Array<Bool> = [];
		for (key in keysArray)
		{
			holdArray.push(controls.pressed(key));
			pressArray.push(controls.justPressed(key));
			releaseArray.push(controls.justReleased(key));
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(controls.controllerMode && pressArray.contains(true))
			for (i in 0...pressArray.length)
				if(pressArray[i])
					keyPressed(i);

		// ONLY DO NOTE CHECKING IF THERE'S NOTES TO HIT
		if (notes.length > 0)
		{
			for (daNote in notes.members)
			{
				if (daNote != null && daNote.isSustainNote && strumsBlocked[daNote.noteData] != true
					&& daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit)
				{
					if (holdArray[daNote.noteData] || (controls.controllerMode && pressArray[daNote.noteData]))
						goodNoteHit(daNote);
				}
			}
		}

		if (controls.controllerMode && releaseArray.contains(true))
			for (i in 0...releaseArray.length)
				if(releaseArray[i])
					keyReleased(i);
	}

	function playerDance():Void
	{
		if (boyfriend.holdingNote != null && !holdCheck(boyfriend.holdingNote))
			boyfriend.holdingNote = null;

		if (boyfriend.holdingNote == null && boyfriend.animation.curAnim != null && boyfriend.animation.curAnim.finished)
			boyfriend.dance();
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			note.wasGoodHit = true;
			vocals.volume = 1;

			var isSustain:Bool = note.isSustainNote;

			if (callOnScripts('goodNoteHit', [notes.members.indexOf(note), note.noteData, note.noteType, isSustain]) != LuaUtils.Function_Stop)
			{
				if (note.hitCausesMiss)
				{
					noteMiss(note);
					if (!isSustain)
						invalidateNote(note);
					return;
				}

				if (!isSustain)
				{
					combo++;
					popUpScore(note);
				}
				else
				{
					if (!cpuControlled)
						songScore += 20;
				}

				if (health < 2 && note.hitsoundOK)
					health += 0.023 * healthGain;

				var spr:StrumNote = playerStrums.members[note.noteData];
				if (spr != null)
				{
					spr.playAnim('confirm', true);
					spr.resetAnim = 0.15;
				}

				if (note.noteType != 'No Animation')
				{
					var animToPlay:String = singAnimations[note.noteData];
					if (note.animSuffix != null) animToPlay += note.animSuffix;

					boyfriend.playAnim(animToPlay, true);
					boyfriend.holdTimer = 0;
				}

				if (!isSustain)
				{
					note.active = false;
					note.visible = false;
					invalidateNote(note);
				}
			}
		}
	}

	function opponentNoteHit(note:Note):Void
	{
		if (note.hitByOpponent) return;

		note.hitByOpponent = true;
		opponentVocals.volume = 1;

		var isSustain:Bool = note.isSustainNote;

		if (callOnScripts('opponentNoteHit', [notes.members.indexOf(note), note.noteData, note.noteType, isSustain]) != LuaUtils.Function_Stop)
		{
			var spr:StrumNote = opponentStrums.members[note.noteData];
			if (spr != null)
			{
				spr.playAnim('confirm', true);
				spr.resetAnim = 0.15;
				spr.alpha = ClientPrefs.data.opponentStrumAlpha;
			}

			if (note.noteType != 'No Animation')
			{
				var animToPlay:String = singAnimations[note.noteData];
				if (note.animSuffix != null) animToPlay += note.animSuffix;

				dad.playAnim(animToPlay, true);
				dad.holdTimer = 0;
			}

			if (!isSustain)
			{
				note.active = false;
				note.visible = false;
				invalidateNote(note);
			}
		}
	}

	function noteMiss(note:Note):Void
	{
		if (note.wasGoodHit) return;

		combo = 0;
		songMisses++;
		health -= 0.0475 * healthLoss;

		if (instakillOnMiss)
			health = 0;

		vocals.volume = 0;

		callOnScripts('noteMiss', [notes.members.indexOf(note), note.noteData, note.noteType, note.isSustainNote]);

		if (note.noteType != 'No Animation')
		{
			var animToPlay:String = singAnimations[note.noteData] + 'miss';
			if (note.animSuffix != null) animToPlay += note.animSuffix;

			boyfriend.playAnim(animToPlay, true);
		}

		updateScore(true);
	}

	function noteMissPress(direction:Int):Void
	{
		combo = 0;
		songMisses++;
		health -= pressMissDamage * healthLoss;

		if (instakillOnMiss)
			health = 0;

		vocals.volume = 0;

		callOnScripts('noteMissPress', [direction]);

		var animToPlay:String = singAnimations[direction] + 'miss';
		boyfriend.playAnim(animToPlay, true);

		updateScore(true);
	

	public function invalidateNote(note:Note):Void
	{
		note.kill();
		notes.remove(note, true);
		note.destroy();
	}

	public function RecalculateRating(badHit:Bool = false, updateTxt:Bool = true)
	{
		if (totalPlayed != 0)
			ratingPercent = totalNotesHit / totalPlayed;
		else
			ratingPercent = 0;

		fullComboFunction();

		for (i in 0...ratingStuff.length)
		{
			if (ratingPercent >= ratingStuff[i][1])
			{
				ratingName = ratingStuff[i][0];
				break;
			}
		}

		if (updateTxt)
			updateScoreText();
	}

	// --- OPTIMIZACIÓN: DISABLE NOTE SPARKS / SPLASHES ---
	public function spawnNoteSplashOnNote(note:Note)
	{
		if (ClientPrefs.data.disableSparks) return; // Cancela el render de chispas si está activado en Opciones

		if (ClientPrefs.data.noteSplashes && note != null)
		{
			var strum:StrumNote = playerStrums.members[note.noteData];
			if (strum != null)
			{
				var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
				splash.setupNoteSplash(strum.x, strum.y, note.noteData, note);
				splash.alpha = ClientPrefs.data.splashAlpha;
				grpNoteSplashes.add(splash);
			}
		}
	}

	function holdCheck(note:Note):Bool
	{
		return note != null && note.isSustainNote && controls.pressed(keysArray[note.noteData]);
	}

	function characterBopper(beat:Int):Void
	{
		if (beat % gfSpeed == 0 && gf != null)
			gf.dance();

		if (beat % dad.danceEveryNumBeats == 0 && dad != null)
			dad.dance();

		if (beat % boyfriend.danceEveryNumBeats == 0 && boyfriend != null)
			boyfriend.dance();

		// --- OPTIMIZACIÓN: LOW QUALITY STAGE ---
		if (!ClientPrefs.data.lowQualityStage)
		{
			stagesFunc(function(stage:BaseStage) {
				stage.bopStageElements(beat);
			});
		}

		// Icon Bop Style Customization
		if (iconP1 != null && iconP2 != null)
		{
			switch (ClientPrefs.data.iconBopStyle)
			{
				case 'Disabled':
					iconP1.scale.set(1, 1);
					iconP2.scale.set(1, 1);
				case 'Smooth':
					iconP1.scale.set(1.15, 1.15);
					iconP2.scale.set(1.15, 1.15);
					FlxTween.tween(iconP1.scale, {x: 1, y: 1}, 0.2, {ease: FlxEase.smoothStepOut});
					FlxTween.tween(iconP2.scale, {x: 1, y: 1}, 0.2, {ease: FlxEase.smoothStepOut});
				case 'Pixel':
					iconP1.scale.set(1.3, 1.3);
					iconP2.scale.set(1.3, 1.3);
				default: // Default FNF Bop
					iconP1.scale.set(1.2, 1.2);
					iconP2.scale.set(1.2, 1.2);
			}
		}
	}

	// --- OPTIMIZACIÓN: LIMPIEZA DE MEMORIA RAM AL SALIR DEL STATE ---
	override public function destroy():Void
	{
		super.destroy();

		if (ClientPrefs.data.agressiveRAMClean)
		{
			Main.performRAMClean();
		}
	}

	// Dynamic Script Calls & Helpers
	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	public function callOnScripts(funcName:String, ?args:Array<Dynamic>, ?ignoreStops:Bool = false):Dynamic
	{
		var value:Dynamic = LuaUtils.Function_Continue;

		#if LUA_ALLOWED
		for (script in luaArray)
		{
			if (script == null) continue;
			var ret:Dynamic = script.call(funcName, args);
			if (ret == LuaUtils.Function_Stop && !ignoreStops)
				return LuaUtils.Function_Stop;
		}
		#end

		#if HSCRIPT_ALLOWED
		for (script in hscriptArray)
		{
			if (script == null) continue;
			var ret:Dynamic = script.call(funcName, args);
			if (ret == LuaUtils.Function_Stop && !ignoreStops)
				return LuaUtils.Function_Stop;
		}
		#end

		return value;
	}

	public function setOnScripts(varName:String, arg:Dynamic)
	{
		#if LUA_ALLOWED
		for (script in luaArray)
			if (script != null) script.set(varName, arg);
		#end

		#if HSCRIPT_ALLOWED
		for (script in hscriptArray)
			if (script != null) script.set(varName, arg);
		#end
	}
	#else
	public inline function callOnScripts(funcName:String, ?args:Array<Dynamic>, ?ignoreStops:Bool = false):Dynamic return null;
	public inline function setOnScripts(varName:String, arg:Dynamic) {}
	#end

	public function stagesFunc(func:BaseStage->Void)
	{
		for (stage in stageBuildMap)
		{
			if (stage != null && stage.exists && stage.active)
				func(stage);
		}
	}

	public function reloadHUDVisibility():Void
	{
		var showBar:Bool = !ClientPrefs.data.hideHealthBar && !ClientPrefs.data.hideHud;
		if (healthBar != null)
		{
			healthBar.visible = showBar;
			healthBar.alpha = ClientPrefs.data.healthBarAlpha * ClientPrefs.data.hudAlpha;
		}
		if (iconP1 != null) iconP1.visible = showBar;
		if (iconP2 != null) iconP2.visible = showBar;
		if (scoreTxt != null) scoreTxt.alpha = ClientPrefs.data.hudAlpha;
		if (timeBar != null) timeBar.visible = (ClientPrefs.data.timeBarType != 'Disabled') && !ClientPrefs.data.hideHud;
	}
}
