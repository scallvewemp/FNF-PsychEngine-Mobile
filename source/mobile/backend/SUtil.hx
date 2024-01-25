package mobile.backend;

#if android
import android.content.Context;
import android.widget.Toast;
import android.os.Environment;
import android.Permissions;
#end
import haxe.io.Path;
import haxe.CallStack;
import lime.app.Application;
import lime.system.System as LimeSystem;
import openfl.utils.Assets as OpenflAssets;
import lime.utils.Log as LimeLogger;
import openfl.events.UncaughtErrorEvent;
import openfl.Lib;

using StringTools;

enum StorageType
{
	//DATA;
	EXTERNAL;
	EXTERNAL_DATA;
	EXTERNAL_OBB;
	MEDIA;
}

/**
 * ...
 * @author Mihai Alexandru (M.A. Jigsaw)
 */
class SUtil
{
	/**
	 * This returns the external storage path that the game will use by the type.
	 */
	public static function getStorageDirectory(type:StorageType = #if EXTERNAL EXTERNAL #elseif OBB EXTERNAL_OBB #elseif MEDIA MEDIA #else EXTERNAL_DATA #end):String
	{
		var daPath:String = '';

		#if android
		switch (type)
		{
			//case DATA:
				//daPath = Context.getFilesDir();
			case EXTERNAL_DATA:
				daPath = Context.getExternalFilesDir(null);
			case EXTERNAL_OBB:
				daPath = Context.getObbDir();
			case EXTERNAL:
				daPath = Environment.getExternalStorageDirectory() + '/.' + Application.current.meta.get('file');
			case MEDIA:
				daPath = Environment.getExternalStorageDirectory() + '/Android/media/' + Application.current.meta.get('packageName');
		}
		#elseif ios
		daPath = LimeSystem.documentsDirectory;
		#end

		return daPath;
	}

	/**
	 * Uncaught error handler, original made by: Sqirra-RNG and YoshiCrafter29
	 */
	public static function uncaughtErrorHandler():Void
	{
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onError);
	}

	private static function onError(error:UncaughtErrorEvent):Void
	{
		final log:Array<String> = [error.error];

		for (item in CallStack.exceptionStack(true))
		{
			switch (item)
			{
				case CFunction:
					log.push('C Function');
				case Module(m):
					log.push('Module [$m]');
				case FilePos(s, file, line, column):
					log.push('$file [line $line]');
				case Method(classname, method):
					log.push('$classname [method $method]');
				case LocalFunction(name):
					log.push('Local Function [$name]');
			}
		}

		final msg:String = log.join('\n');

		#if sys
		try
		{
			if (!FileSystem.exists('logs'))
				FileSystem.createDirectory('logs');

			File.saveContent('logs/' + Date.now().toString().replace(' ', '-').replace(':', "'") + '.txt', msg + '\n');
		}
		catch (e:Dynamic)
		{
			#if (android && debug)
			Toast.makeText("Error!\nCouldn't save the crash dump because:\n" + e, Toast.LENGTH_LONG);
			#else
			LimeLogger.println("Error!\nCouldn't save the crash dump because:\n" + e);
			#end
		}
		#end

		LimeLogger.println(msg);
		showPopUp(msg, "Error!");

		#if DISCORD_ALLOWED
		DiscordClient.shutdown();
		#end

                #if js
                if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

                js.Browser.window.location.reload(true);
                #else
		LimeSystem.exit(1);
                #end
	}

	/**
	 * This is mostly a fork of https://github.com/openfl/hxp/blob/master/src/hxp/System.hx#L595
	 */
	#if sys
	public static function mkDirs(directory:String):Void
	{
		var total:String = '';
		if (directory.substr(0, 1) == '/')
			total = '/';

		var parts:Array<String> = directory.split('/');
		if (parts.length > 0 && parts[0].indexOf(':') > -1)
			parts.shift();

		for (part in parts)
		{
			if (part != '.' && part != '')
			{
				if (total != '' && total != '/')
					total += '/';

				total += part;

				if (!FileSystem.exists(total))
					FileSystem.createDirectory(total);
			}
		}
	}

	public static function saveContent(fileName:String = 'file', fileExtension:String = '.json',
			fileData:String = 'you forgot to add something in your code lol'):Void
	{
		try
		{
			if (!FileSystem.exists('saves'))
				FileSystem.createDirectory('saves');

			File.saveContent('saves/' + fileName + fileExtension, fileData);
			showPopUp(fileName + " file has been saved", "Success!");
		}
		catch (e:Dynamic)
		{
			#if (android && debug)
			Toast.makeText("Error!\nClouldn't save the file because:\n" + e, Toast.LENGTH_LONG);
			#else
			LimeLogger.println("Error!\nClouldn't save the file because:\n" + e);
			#end
		}
	}

	public static function copyContent(copyPath:String, savePath:String):Void
	{
		try {
			if (!FileSystem.exists(savePath) && OpenflAssets.exists(copyPath))
			{
				if (!FileSystem.exists(Path.directory(savePath)))
					mkDirs(Path.directory(savePath));
				if(copyPath.endsWith('.otf') || copyPath.endsWith('.ttf'))
					File.saveBytes(savePath, cast OpenflAssets.getFont(copyPath));
				else if(copyPath.endsWith('.txt'))
					File.saveBytes(savePath, cast OpenflAssets.getText(copyPath));
				else
					File.saveBytes(savePath, OpenflAssets.getBytes(copyPath));
			}
		}
		catch (e:Dynamic)
		{
			#if (android && debug)
			Toast.makeText('Error!\nClouldn\'t copy the $copyPath because:\n' + e, Toast.LENGTH_LONG);
			#else
			LimeLogger.println('Error!\nClouldn\'t copy the $copyPath because:\n' + e);
			#end
		}
	}

	#end
	#if android
	public static function doPermissionsShit():Void
        {
		if(!Permissions.getGrantedPermissions().contains(Permissions.READ_EXTERNAL_STORAGE) || !Permissions.getGrantedPermissions().contains(Permissions.WRITE_EXTERNAL_STORAGE)) {
			if(!Permissions.getGrantedPermissions().contains(Permissions.READ_EXTERNAL_STORAGE))
				Permissions.requestPermission(Permissions.READ_EXTERNAL_STORAGE);
			if(!Permissions.getGrantedPermissions().contains(Permissions.WRITE_EXTERNAL_STORAGE))
				Permissions.requestPermission(Permissions.WRITE_EXTERNAL_STORAGE);
			showPopUp('Please Make Sure You Accepted The Permissions To Be Able To Run The Game', 'Notice!');
		}
	}
	#end

        public static function showPopUp(message:String, title:String):Void
        {
                /*#if ios
		var application:UIViewController = UIApplication.sharedApplication().keyWindow.rootViewController;

                var alert = UIAlertController.alertControllerWithTitleMessagePreferredStyle(title, message, UIAlertControllerStyle.UIAlertControllerStyleAlert);
		var action = UIAlertAction.actionWithTitleStyleHandler("OK", UIAlertActionStyle.UIAlertActionStyleDefault,
			UIAlertActionCall((data:UIAlertAction) -> {
			//var title = data.title;
			var label:UILabel = UILabel.alloc().initWithFrame(CGRectMake(100, 100, 200, 40));
			label.text = "23";
			label.textColor = UIColor.colorWithRedGreenBlueAlpha(1, 1, 0, 1);
			application.view.addSubview(label);
		}));
		alert.addAction(action);*/
                #if (windows || mobile || js || wasm)
                Application.current.window.alert(message, title);
                #else
                trace('$title - $message');
                #end
        }
}
