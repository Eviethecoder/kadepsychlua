package funkin.gameplay;

import flixel.system.frontEnds.BitmapFrontEnd;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.FlxCamera;
import flixel.math.FlxPoint;
import flixel.FlxObject;
#if FEATURE_DISCORD
import funkin._backend.utils.Discord.DiscordClient;
#end
import flixel.addons.effects.FlxTrail;
import flixel.group.FlxGroup.FlxTypedGroup;
import openfl.ui.Keyboard;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUIState;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.plugin.FlxMouseControl;
import flixel.addons.display.FlxExtendedSprite;
import flixel.math.FlxRect;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxTimer;
import funkin._backend.MusicBeatState.MusicBeatState.transSubstate;
import funkin._backend.MusicBeatState;
import funkin.gameplay.objects.Stage;
import funkin._backend.chart.*;
import funkin.menus.OptionsDirect;
import funkin._backend.utils.NoteskinHelpers;

using StringTools;

class GameplayCustomizeState extends MusicBeatState
{
	var defaultX:Float = FlxG.width * 0.55 - 135;
	var defaultY:Float = FlxG.height / 2 - 50;

	var sick:FlxExtendedSprite;

	var UI_options:FlxUITabMenu;

	var text:FlxText;
	var blackBorder:FlxSprite;

	var strumLine:FlxSprite;
	var strumLineNotes:FlxTypedGroup<StaticArrow>;
	var playerStrums:FlxTypedGroup<StaticArrow>;
	var cpuStrums:FlxTypedGroup<StaticArrow>;

	var arrowLanes:FlxTypedGroup<FlxSprite>;

	public static var instance:GameplayCustomizeState = null;

	public var arrowsGenerated:Bool = false;

	public var arrowsAppeared:Bool = false;

	var camPos:FlxPoint;

	public var tweenManager:FlxTweenManager;
	public var timerManager:FlxTimerManager;

	private var camHUD:FlxCamera;
	private var camGame:FlxCamera;

	private var camRatings:FlxCamera;

	private var camFollow:FlxPoint;

	private var camFollowPos:FlxObject;

	private var camStrums:FlxCamera;

	private var dataSuffix:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];
	private var dataColor:Array<String> = ['purple', 'blue', 'green', 'red'];

	public var dad:Character;
	public var gf:Character;
	public var boyfriend:Boyfriend;
	public var Stage:Stage;

	public static var freeplayNoteStyle:String = 'normal';
	public static var freeplayWeek:Int = 1;

	var currentTimingShown:FlxText = null;

	public var mainCam:FlxCamera;

	var changedPos:Bool = true;

	var timeShown = 0;

	var strumYRef:FlxExtendedSprite;

	var arrowHeight:Float = 0;

	var strumYBounds:FlxSprite;

	public override function create()
	{
		Paths.clearStoredMemory();

		instance = this;

		#if FEATURE_DISCORD
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Customizing Gameplay Modules", null);
		#end

		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		mainCam = new FlxCamera();
		camStrums = new FlxCamera();
		camRatings = new FlxCamera();
		camStrums.bgColor.alpha = 0;
		mainCam.bgColor.alpha = 0;
		camHUD.bgColor.alpha = 0;
		camRatings.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camStrums, false);
		FlxG.cameras.add(camRatings, false);
		FlxG.cameras.add(mainCam, false);

		camHUD.zoom = FlxG.save.data.zoom;

		camStrums.zoom = camHUD.zoom;

		camRatings.zoom = camHUD.zoom;

		persistentUpdate = persistentDraw = true;

		tweenManager = new FlxTweenManager();
		timerManager = new FlxTimerManager();

		var opt_tabs = [
			{name: "Appeareance", label: 'Appeareance'},
			{name: "Gameplay Modules", label: 'Gameplay Modules'}
		];

		UI_options = new FlxUITabMenu(null, opt_tabs, true);

		UI_options.scrollFactor.set();
		UI_options.selected_tab = 0;
		UI_options.resize(150, 115);
		UI_options.x = FlxG.width - 200;
		UI_options.y = FlxG.height - 700;
		if (!FlxG.save.data.downscroll)
			UI_options.y = FlxG.height - (UI_options.height + 20);
		UI_options.cameras = [mainCam];

		add(UI_options);

		Stage = new Stage('stage');

		Stage.initStageProperties();

		if (Stage.loadGF)
			gf = new Character(400, 130, 'gf');

		boyfriend = new Boyfriend(770, 450, 'bf');

		dad = new Character(100, 100, 'dad');

		Stage.camPosition = [
			gf.getGraphicMidpoint().x + gf.camPos[0],
			gf.getGraphicMidpoint().y + gf.camPos[1]
		];

		var positions = Stage.positions[Stage.curStage];
		if (positions != null)
		{
			for (char => pos in positions)
				for (person in [boyfriend, gf, dad])
					if (person != null)
						if (person.curCharacter == char)
							person.setPosition(pos[0], pos[1]);
		}

		Stage.initStageSprites();
		if (FlxG.save.data.background)
		{
			for (i in Stage.toAdd)
			{
				add(i);
			}
			for (index => array in Stage.layInFront)
			{
				switch (index)
				{
					case 0:
						if (gf != null)
						{
							add(gf);
							gf.scrollFactor.set(0.95, 0.95);
							for (bg in array)
								add(bg);
						}
					case 1:
						add(dad);
						for (bg in array)
							add(bg);
					case 2:
						add(boyfriend);
						for (bg in array)
							add(bg);
				}
			}

			if (gf != null)
			{
				switch (dad.curCharacter)
				{
					case 'gf':
						dad.setPosition(gf.x, gf.y);
						gf.visible = false;
				}
			}
		}
		else
		{
			if (gf != null)
			{
				gf.scrollFactor.set(0.95, 0.95);
				add(gf);
			}
			add(dad);
			add(boyfriend);
		}

		if (!FlxG.save.data.characters)
		{
			if (gf != null)
				gf.alpha = 0;
			dad.alpha = 0;
			boyfriend.alpha = 0;
		}

		camPos = new FlxPoint(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);

		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 0.01);
		FlxG.camera.focusOn(camFollow);
		FlxG.camera.zoom = Stage.camZoom;
		FlxG.camera.focusOn(camFollowPos.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		strumLine = new FlxSprite(0, 0).makeGraphic(FlxG.width, 14);
		strumLine.scrollFactor.set();
		strumLine.alpha = 0;

		strumYBounds = new FlxSprite(0, 0).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.YELLOW);
		strumYBounds.screenCenter(X);
		strumYBounds.scrollFactor.set();
		strumYBounds.alpha = 0;

		strumYBounds.camera = camHUD;

		add(strumLine);

		if (FlxG.save.data.downscroll)
		{
			strumYBounds.y = FlxG.height - 250;
			strumLine.y = FlxG.height - 165;
		}
		else
		{
			strumYBounds.y = FlxG.height - 1925;
			strumLine.y = FlxG.height - 670;
		}

		strumLineNotes = new FlxTypedGroup<StaticArrow>();
		add(strumLineNotes);

		playerStrums = new FlxTypedGroup<StaticArrow>();
		cpuStrums = new FlxTypedGroup<StaticArrow>();

		add(playerStrums);
		add(cpuStrums);

		playerStrums.visible = false;
		cpuStrums.visible = false;

		FlxG.plugins.add(new FlxMouseControl());

		sick = new FlxExtendedSprite(0, 0, Paths.image('hud/default/sick', 'shared'));
		sick.setGraphicSize(Std.int(sick.width * 0.7));
		sick.scrollFactor.set();

		if (freeplayNoteStyle != 'pixel')
		{
			sick.setGraphicSize(Std.int(sick.width * 0.7));
			sick.antialiasing = FlxG.save.data.antialiasing;
		}
		else
			sick.setGraphicSize(Std.int(sick.width * 0.7));

		// sick.enableMouseDrag(false, false, 255);

		sick.updateHitbox();
		add(sick);

		strumLine.cameras = [camStrums];
		strumLineNotes.cameras = [camStrums];
		sick.cameras = [camRatings];

		arrowLanes = new FlxTypedGroup<FlxSprite>();
		arrowLanes.camera = camHUD;
		add(arrowLanes);

		setupStaticArrows(0);
		setupStaticArrows(1);

		appearStaticArrows(true);

		strumYRef = new FlxExtendedSprite(0, strumLine.y + FlxG.save.data.strumOffset.get(FlxG.save.data.downscroll ? 'downscroll' : 'upscroll'));

		strumYRef.makeGraphic(FlxG.width * 2, Std.int(arrowHeight), FlxColor.WHITE);
		strumYRef.screenCenter(X);
		strumYRef.alpha = 0.5;
		strumYRef.scrollFactor.set();
		// strumYRef.enableMouseDrag(false, false, 255);

		strumYRef.cameras = [camHUD];

		add(strumYBounds);

		add(strumYRef);

		text = new FlxText(5, FlxG.height + 40, 0,
			"  Use Arrows or Mouse to move your combo Rate around. Press R to reset. Q/E to change zoom. C to show combo. Escape to exit.", 12);
		text.scrollFactor.set();
		text.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		blackBorder = new FlxSprite(-25, FlxG.height + 40).makeGraphic((Std.int(text.width + 900)), Std.int(text.height + 600), FlxColor.BLACK);
		blackBorder.alpha = 0.5;

		blackBorder.cameras = [mainCam];
		text.cameras = [mainCam];

		add(blackBorder);
		add(text);

		FlxTween.tween(text, {y: FlxG.height - 18}, 2, {ease: FlxEase.elasticInOut});
		FlxTween.tween(blackBorder, {y: FlxG.height - 18}, 2, {ease: FlxEase.elasticInOut});

		sick.x = FlxG.save.data.changedHitX;
		sick.y = FlxG.save.data.changedHitY;

		super.create();

		transSubstate.nextCamera = mainCam;

		Paths.clearUnusedMemory();

		addOptionsUI();
	}

	function snapCamFollowToPos(x:Float, y:Float)
	{
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		// sick.update(elapsed);

		/*if (FlxG.save.data.zoom >= 0.8 && FlxG.save.data.zoom <= 1.2)
			{
				if (FlxG.save.data.downscroll)
					strumLine.y = FlxG.height - 165
				else
					strumLine.y = FlxG.height - 670;
		}*/

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		if (FlxG.save.data.zoom < 0.8)
			FlxG.save.data.zoom = 0.8;

		if (FlxG.save.data.zoom > 1.2)
			FlxG.save.data.zoom = 1.2;

		var bpmRatio = Conductor.bpm / 100;

		FlxG.camera.zoom = FlxMath.lerp(Stage.camZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * bpmRatio), 0, 1));
		camHUD.zoom = FlxMath.lerp(FlxG.save.data.zoom, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * bpmRatio), 0, 1));
		camStrums.zoom = camHUD.zoom;

		if (FlxG.keys.justPressed.LEFT || FlxG.keys.pressed.LEFT)
		{
			sick.x -= 2;
			sick.y -= 0;
			changedPos = true;
		}
		if (FlxG.keys.justPressed.RIGHT || FlxG.keys.pressed.RIGHT)
		{
			sick.x += 2;
			sick.y -= 0;
			changedPos = true;
		}
		if (FlxG.keys.justPressed.UP || FlxG.keys.pressed.UP)
		{
			sick.y -= 2;
			sick.x += 0;
			changedPos = true;
		}
		if (FlxG.keys.justPressed.DOWN || FlxG.keys.pressed.DOWN)
		{
			sick.y += 2;
			sick.x += 0;
			changedPos = true;
		}

		for (i in strumLineNotes)
			i.y = strumYRef.y;

		FlxG.save.data.strumOffset.set(FlxG.save.data.downscroll ? 'downscroll' : 'upscroll', strumYRef.y - strumLine.y);

		if (FlxG.keys.justPressed.Q)
		{
			FlxG.save.data.zoom += 0.02;
			camHUD.zoom = FlxG.save.data.zoom;
			camRatings.zoom = FlxG.save.data.zoom;
		}

		if (FlxG.keys.justPressed.E)
		{
			FlxG.save.data.zoom -= 0.02;
			camHUD.zoom = FlxG.save.data.zoom;
			camRatings.zoom = FlxG.save.data.zoom;
		}

		if (changedPos)
		{
			FlxG.save.data.changedHitX = sick.x;
			FlxG.save.data.changedHitY = sick.y;
		}

		/*if (FlxG.keys.justPressed.C)
			{
				var visibleCombos:Array<FlxSprite> = [];

				var seperatedScore:Array<Int> = [];

				var comboSplit:Array<String> = (FlxG.random.int(10, 420) + "").split('');

				var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2, pixelShitPart3));
				comboSpr.screenCenter();
				comboSpr.x = sick.x - 150;
				comboSpr.y = sick.y + 125;
				if (freeplayNoteStyle == 'pixel')
				{
					comboSpr.x += 142.5;
					comboSpr.y += 65;
				}
				comboSpr.cameras = [camRatings];
				comboSpr.acceleration.y = 600;
				comboSpr.velocity.y -= 150;

				comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.6));

				if (FlxG.save.data.showCombo)
					add(comboSpr);

				currentTimingShown = new FlxText(0, 0, 0, "0ms");
				currentTimingShown.color = FlxColor.CYAN;
				currentTimingShown.borderStyle = OUTLINE;
				currentTimingShown.borderSize = 1;
				currentTimingShown.borderColor = FlxColor.BLACK;
				currentTimingShown.text = "69ms";
				currentTimingShown.size = 20;

				if (FlxG.save.data.showMs)
					add(currentTimingShown);

				currentTimingShown.screenCenter();
				currentTimingShown.x = sick.x + 225;
				currentTimingShown.y = sick.y + 150;

				currentTimingShown.cameras = [camRatings];

				// make sure we have 3 digits to display (looks weird otherwise lol)
				if (comboSplit.length == 1)
				{
					seperatedScore.push(0);
					seperatedScore.push(0);
				}
				else if (comboSplit.length == 2)
					seperatedScore.push(0);

				for (i in 0...comboSplit.length)
				{
					var str:String = comboSplit[i];
					seperatedScore.push(Std.parseInt(str));
				}

				var daLoop:Int = 0;
				for (i in seperatedScore)
				{
					var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2, pixelShitPart4));
					numScore.screenCenter();
					numScore.x = sick.x + (43 * daLoop) - 50;
					numScore.y = sick.y + 100;
					numScore.cameras = [camRatings];

					if (freeplayNoteStyle != 'pixel')
					{
						currentTimingShown.x -= 15;
						currentTimingShown.y -= 15;
						numScore.antialiasing = FlxG.save.data.antialiasing;
						numScore.setGraphicSize(Std.int(numScore.width * 0.5));
					}
					else
						numScore.setGraphicSize(Std.int(numScore.width));

					numScore.updateHitbox();

					numScore.acceleration.y = FlxG.random.int(200, 300);
					numScore.velocity.y -= FlxG.random.int(140, 160);
					numScore.velocity.x = FlxG.random.float(-5, 5);

					if (FlxG.save.data.showComboNum)
						add(numScore);

					visibleCombos.push(numScore);

					FlxTween.tween(numScore, {alpha: 0}, 0.2, {
						onComplete: function(tween:FlxTween)
						{
							visibleCombos.remove(numScore);
							numScore.destroy();
						},
						onUpdate: function(tween:FlxTween)
						{
							if (!visibleCombos.contains(numScore))
							{
								tween.cancel();
								numScore.destroy();
							}
						},
						startDelay: Conductor.crochet * 0.002
					});

					if (visibleCombos.length > seperatedScore.length + 20)
					{
						for (i in 0...seperatedScore.length - 1)
						{
							visibleCombos.remove(visibleCombos[visibleCombos.length - 1]);
						}
					}

					daLoop++;
				}

				if (FlxG.save.data.showMs)
				{
					FlxTween.cancelTweensOf(currentTimingShown);

					FlxTween.tween(currentTimingShown, {alpha: 0}, 0.2, {
						onComplete: function(twn)
						{
							if (currentTimingShown != null)
							{
								remove(currentTimingShown);
								currentTimingShown.destroy();
							}
						}
					});
				}

				FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
					onComplete: function(tween:FlxTween)
					{
						comboSpr.destroy();
					},
					startDelay: Conductor.crochet * 0.001
				});
		}*/

		if (FlxG.keys.justPressed.R)
		{
			sick.x = defaultX;
			sick.y = defaultY;
			FlxG.save.data.zoom = 1;
			camHUD.zoom = FlxG.save.data.zoom;
			camRatings.zoom = camHUD.zoom;
			FlxG.save.data.changedHitX = sick.x;
			FlxG.save.data.changedHitY = sick.y;
			FlxG.save.data.changedHit = false;

			FlxG.save.data.strumOffset.set(FlxG.save.data.downscroll ? 'downscroll' : 'upscroll', 0);

			strumYRef.y = strumLine.y + FlxG.save.data.strumOffset.get(FlxG.save.data.downscroll ? 'downscroll' : 'upscroll');
		}

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new OptionsDirect());
		}
	}

	override function beatHit()
	{
		super.beatHit();

		if (curBeat % 2 == 0)
		{
			boyfriend.dance();
			dad.dance();
		}
		else if (dad.curCharacter == 'spooky' || dad.curCharacter == 'gf')
			dad.dance();

		gf.dance();

		/*if (!FlxG.keys.pressed.SPACE)
			{
				if (curBeat % 4 == 0)
				{
					FlxG.camera.zoom += 0.015;
					camHUD.zoom += 0.03;
				}
		}*/

		trace('beat');
	}

	// ripped from playstate cuz lol
	private function setupStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var babyArrow:StaticArrow = new StaticArrow(43,
				strumLine.y + FlxG.save.data.strumOffset.get(FlxG.save.data.downscroll ? 'downscroll' : 'upscroll'));

			// defaults if no noteStyle was found in chart
			var noteStyleCheck:String = 'normal';

			/*if (FlxG.save.data.optimize && player == 0)
				continue; */

			babyArrow.downScroll = FlxG.save.data.downscroll;

			if (freeplayNoteStyle == null && FlxG.save.data.overrideNoteskins)
			{
				switch (freeplayWeek)
				{
					case 6:
						noteStyleCheck = 'pixel';
					default:
						noteStyleCheck = 'normal';
				}
			}
			else
			{
				noteStyleCheck = freeplayNoteStyle;
			}

			babyArrow.frames = NoteskinHelpers.generateNoteskinSprite(FlxG.save.data.noteskin, 'normal', 'default');

			Debug.logTrace(babyArrow.frames);
			for (j in 0...4)
			{
				babyArrow.animation.addByPrefix(dataColor[j], 'arrow' + dataSuffix[j]);
				babyArrow.animation.addByPrefix('dirCon' + j, dataSuffix[j].toLowerCase() + ' confirm', 24, false);
			}

			var lowerDir:String = dataSuffix[i].toLowerCase();

			babyArrow.animation.addByPrefix('static', 'arrow' + dataSuffix[i]);
			babyArrow.animation.addByPrefix('pressed', lowerDir + ' press', 24, false);
			babyArrow.animation.addByPrefix('confirm', lowerDir + ' confirm', 24, false);

			babyArrow.x += NoteSpr.swagWidth * i;

			babyArrow.antialiasing = FlxG.save.data.antialiasing;
			babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));

			babyArrow.loadLane();

			babyArrow.bgLane.updateHitbox();
			babyArrow.bgLane.scrollFactor.set();
			babyArrow.updateHitbox();
			babyArrow.scrollFactor.set();
			babyArrow.camera = camStrums;

			babyArrow.alpha = 0;
			arrowHeight = babyArrow.height;

			babyArrow.ID = i;

			switch (player)
			{
				case 0:
					if (!PlayStateChangeables.opponentMode)
						cpuStrums.add(babyArrow);
					else
						playerStrums.add(babyArrow);
					babyArrow.x += 20.5;

				case 1:
					if (!PlayStateChangeables.opponentMode)
						playerStrums.add(babyArrow);
					else
						cpuStrums.add(babyArrow);
			}

			babyArrow.playAnim('static');
			babyArrow.x += ((FlxG.width / 2) * player);
			babyArrow.x += 48.5;

			if (FlxG.save.data.middleScroll)
			{
				if (!PlayStateChangeables.opponentMode)
				{
					babyArrow.x -= 310;
					if (player == 0)
						babyArrow.x -= 410;
				}
				else
				{
					babyArrow.x += 310;
					if (player == 1)
						babyArrow.x += 410;
				}
			}

			/*cpuStrums.forEach(function(spr:FlxSprite)
				{
					spr.centerOffsets(); // CPU arrows start out slightly off-center
			});*/

			strumLineNotes.add(babyArrow);
		}
		arrowsGenerated = true;
	}

	private function appearStaticArrows(?tween:Bool = true):Void
	{
		strumLineNotes.forEach(function(babyArrow:StaticArrow)
		{
			babyArrow.alpha = 1;

			arrowLanes.add(babyArrow.bgLane);
		});
		arrowsAppeared = true;
	}

	function addOptionsUI()
	{
		var comboSprite = new FlxUICheckBox(10, 15, null, null, "Show Combo Sprite", 100);
		comboSprite.checked = FlxG.save.data.showCombo;
		comboSprite.callback = function()
		{
			FlxG.save.data.showCombo = comboSprite.checked;
		};

		var comboNum = new FlxUICheckBox(10, 40, null, null, "Show Combo Number", 100);
		comboNum.checked = FlxG.save.data.showComboNum;
		comboNum.callback = function()
		{
			FlxG.save.data.showComboNum = comboNum.checked;
		};

		var msTiming = new FlxUICheckBox(10, 65, null, null, "Show Timing MS", 100);
		msTiming.checked = FlxG.save.data.showMs;
		msTiming.callback = function()
		{
			FlxG.save.data.showMs = msTiming.checked;
		};

		var tab_app = new FlxUI(null, UI_options);
		tab_app.name = "Appeareance";
		tab_app.add(comboSprite);
		tab_app.add(comboNum);
		tab_app.add(msTiming);
		UI_options.addGroup(tab_app);

		var tab_modules = new FlxUI(null, UI_options);
		tab_modules.name = "Gameplay Modules";

		var gameplayModules = ['Rating', 'Receptors'];
		var modulesDropDown = new FlxUIDropDownMenu(10, 15, FlxUIDropDownMenu.makeStrIdLabelArray(gameplayModules, true), function(gameplayModule:String)
		{
			sick.disableMouseDrag();
			strumYRef.disableMouseDrag();
			strumYBounds.alpha = 0;

			var leModuleString = gameplayModules[Std.parseInt(gameplayModule)];
			switch (leModuleString)
			{
				case 'Rating':
					sick.enableMouseDrag();
				case 'Receptors':
					strumYBounds.alpha = 0.5;

					strumYRef.enableMouseDrag(false, false, 255, null, strumYBounds);
					strumYRef.setDragLock(false, true);
			}
		});
		modulesDropDown.selectedLabel = 'Rating';
		modulesDropDown.callback('0');

		tab_modules.add(modulesDropDown);

		UI_options.addGroup(tab_modules);
	}

	override function destroy()
	{
		instance = null;
		super.destroy();
	}
}
