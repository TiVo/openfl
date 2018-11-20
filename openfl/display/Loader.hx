package openfl.display;


import haxe.Json;
import haxe.Unserializer;
import lime.system.BackgroundWorker;
import openfl._internal.swf.SWFLiteLibrary;
import openfl._internal.swf.SWFLite;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.geom.Rectangle;
import openfl.net.URLLoader;
import openfl.net.URLLoaderDataFormat;
import openfl.net.URLRequest;
import openfl.system.LoaderContext;
import openfl.utils.ByteArray;
import openfl.Assets;

#if (js && html5)
import js.html.ScriptElement;
import js.Browser;
#end

@:access(lime.Assets)
@:access(openfl._internal.swf.SWFLiteLibrary)
@:access(openfl.display.LoaderInfo)
@:access(openfl.events.Event)


class Loader extends DisplayObjectContainer {
	
	
	public var content (default, null):DisplayObject;
	public var contentLoaderInfo (default, null):LoaderInfo;

	private var mClosed : Bool = false;
	private var mLoader : URLLoader;

	public function new () {
		
		super ();
		
		contentLoaderInfo = LoaderInfo.create (this);
		
	}
	
	
	public function close ():Void {
		
		mClosed = true;
		if (mLoader != null) {
			mLoader.close();
			mLoader = null;
		}
	}
	
	
	public function load (request:URLRequest, context:LoaderContext = null):Void {

        if (mLoader != null) {
            mLoader.close();
            mLoader = null;
        }

		var extension = "";
		var path = request.url;
		
		var queryIndex = path.indexOf ('?');
		if (queryIndex > -1) {
			
			path = path.substring (0, queryIndex);
			
		}
		
		var extIndex = path.lastIndexOf('.');
		if (extIndex > -1) {
			
			extension = path.substring(extIndex + 1);
			
		}
		
		contentLoaderInfo.url = request.url;
		
		if (request.contentType == null || request.contentType == "") {
			
			contentLoaderInfo.contentType = switch (extension) {
				
				case "json": "application/json";
				case "swf": "application/x-shockwave-flash";
				case "jpg", "jpeg": "image/jpeg";
				case "png": "image/png";
				case "gif": "image/gif";
				case "js": "application/javascript";
				default: "application/x-www-form-urlencoded"; /*throw "Unrecognized file " + request.url;*/
				
			}
			
		} else {
			
			contentLoaderInfo.contentType = request.contentType;
			
		}
		
		if (contentLoaderInfo.contentType.indexOf ("/javascript") > -1 || contentLoaderInfo.contentType.indexOf ("/ecmascript") > -1) {

			#if (js && html5)
			var loader = new URLLoader ();
			loader.addEventListener (Event.COMPLETE, function (e) {

				contentLoaderInfo.content = new Sprite ();
				addChild (contentLoaderInfo.content);

				//var script:ScriptElement = cast Browser.document.createElement ("script");
				//script.innerHTML = loader.data;
				//Browser.document.head.appendChild (script);

				untyped __js__ ("eval") ('(function () {' + loader.data + '})()');

				var event = new Event (Event.COMPLETE);
				event.target = contentLoaderInfo;
				event.currentTarget = contentLoaderInfo;
				contentLoaderInfo.dispatchEvent (event);

			});
			loader.addEventListener (IOErrorEvent.IO_ERROR, function (e) {

				BitmapData_onError (e);

			});
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			loader.load (request);
			#else
			BitmapData_onError (null);
			#end

			return;

		} else if (contentLoaderInfo.contentType.indexOf ("/json") > -1) {

			var loader = new URLLoader ();
			loader.addEventListener (Event.COMPLETE, function (e) {

				var info = Json.parse (loader.data);
				var library:SWFLiteLibrary = cast Type.createInstance (Type.resolveClass (info.type), [ null ]/*info.args*/);

				Assets.registerLibrary (info.name, library);

				var manifest:Array<Dynamic> = cast Unserializer.run (info.manifest);
				var assetType:AssetType;

				var basePath = request.url;
				basePath = StringTools.replace (basePath, "\\", "/");
				var parts = basePath.split ("/");
				parts.pop ();
				parts.pop ();
				basePath = parts.join ("/");

				var libraryData:String = null;

				var loaded = -1;
				var total = 0;

				var checkLoaded = function () {

					if (loaded >= total) {

						library.swf = SWFLite.unserialize (libraryData);

						contentLoaderInfo.content = library.getMovieClip ("");
						addChild (contentLoaderInfo.content);

						var event = new Event (Event.COMPLETE);
						event.target = contentLoaderInfo;
						event.currentTarget = contentLoaderInfo;
						contentLoaderInfo.dispatchEvent (event);

					}

				}

				for (asset in manifest) {

					if (!Assets.exists (asset.id)) {

						assetType = asset.type;

						switch (assetType) {

							case IMAGE:

								total++;

								BitmapData.fromFile (basePath + "/" + asset.path, function (bitmapData) {

									loaded++;
									checkLoaded ();

									Assets.cache.setBitmapData (asset.path, bitmapData);

								}, function () BitmapData_onError (null));

							case TEXT:

								total++;

								var textLoader = new URLLoader ();
								textLoader.addEventListener (Event.COMPLETE, function (_) {

									libraryData = textLoader.data;

									loaded++;
									checkLoaded ();

								});
								textLoader.addEventListener (IOErrorEvent.IO_ERROR, function (e) {

									BitmapData_onError (e);

								});
								textLoader.dataFormat = URLLoaderDataFormat.TEXT;
								textLoader.load (new URLRequest (basePath + "/" + asset.path));

							default:


						}

					}

				}

				loaded++;
				checkLoaded ();

			});
			loader.addEventListener (IOErrorEvent.IO_ERROR, function (e) {

				BitmapData_onError (e);

			});
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			loader.load (request);

		}

		#if sys
		if (request.url != null && request.url.indexOf ("http://") > -1 || request.url.indexOf ("https://") > -1) {

			mLoader = new URLLoader ();
			mLoader.addEventListener (Event.COMPLETE, function (e) {
				if (!mClosed)
				{
					BitmapData_onLoad (BitmapData.fromBytes (mLoader.data));
				}
				else
				{
					mLoader.data = null;
				}
				
			});
			mLoader.addEventListener (IOErrorEvent.IO_ERROR, function (e) {
				
				BitmapData_onError (e);
				
			});
			mLoader.dataFormat = URLLoaderDataFormat.BINARY;
			mLoader.load (request);
			return;
			
		} else 
		#end
		{
			
			var worker = new BackgroundWorker ();
			
			worker.doWork.add (function (_) {

				BitmapData.fromFile (path, function (bitmapData) worker.sendComplete (bitmapData), function () worker.sendError (IOErrorEvent.IO_ERROR));
				
			});
			
			worker.onError.add (BitmapData_onError);
			worker.onComplete.add (BitmapData_onLoad);
			worker.run ();
			
		}
		
	}
	
	
	public function loadBytes (buffer:ByteArray, context:LoaderContext = null):Void {
		
		var worker = new BackgroundWorker ();
		
		worker.doWork.add (function (_) {
			
			BitmapData.fromBytes (buffer, function (bitmapData) worker.sendComplete (bitmapData));
			
		});
		
		worker.onComplete.add (BitmapData_onLoad);
		worker.run ();
		
	}
	
	
	public function unload ():Void {
		
		if (numChildren > 0) {
			
			while (numChildren > 0) {
				
				removeChildAt (0);
				
			}
			
			content = null;
			contentLoaderInfo.url = null;
			contentLoaderInfo.contentType = null;
			contentLoaderInfo.content = null;
			contentLoaderInfo.bytesLoaded = 0;
			contentLoaderInfo.bytesTotal = 0;
			contentLoaderInfo.width = 0;
			contentLoaderInfo.height = 0;
			
			var event = new Event (Event.UNLOAD);
			event.currentTarget = this;
			__dispatchEvent (event);
			
		}
		
	}
	
	
	public function unloadAndStop (gc:Bool = true):Void {
		
		openfl.Lib.notImplemented ();
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	private function BitmapData_onLoad (bitmapData:BitmapData):Void {
		
		contentLoaderInfo.content = new Bitmap (bitmapData);
		content = contentLoaderInfo.content;
		addChild (content);
		
		var event = new Event (Event.COMPLETE);
		event.target = contentLoaderInfo;
		event.currentTarget = contentLoaderInfo;
		contentLoaderInfo.dispatchEvent (event);
		
	}
	
	
	private function BitmapData_onError (_):Void {
		
		var event = new IOErrorEvent (IOErrorEvent.IO_ERROR);
		event.target = contentLoaderInfo;
		event.currentTarget = contentLoaderInfo;
		contentLoaderInfo.dispatchEvent (event);
		
	}
	
	
}
