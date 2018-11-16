package openfl.display;

import openfl.events.SoftKeyboardEvent;
import openfl.geom.Rectangle;


class InteractiveObject extends DisplayObject {
	
	
	public var doubleClickEnabled:Bool;
	public var focusRect:Dynamic;
	public var mouseEnabled:Bool;
	public var needsSoftKeyboard(get, set):Bool;
	
	public var softKeyboardInputAreaOfInterest:Rectangle;
	public var tabEnabled (get, set):Bool;
	public var tabIndex:Int;
	
	private var __tabEnabled:Bool;
	private var __needsSoftKeyboard:Bool;
	
	
	public function new () {
		
		super ();
		
		doubleClickEnabled = false;
		mouseEnabled = true;
		__needsSoftKeyboard = false;
		__tabEnabled = false;
		tabIndex = -1;
		
		#if tivo_android
		if (!is_initiated_jni()) {

			init_jni(SoftKeyboardEventHandler.get());

		}
		#end
	}
	
	
	public function requestSoftKeyboard ():Bool {
		
		openfl.Lib.notImplemented ("InteractiveObject.requestSoftKeyboard");
		
		return false;
		
	}
	
	
	private override function __getInteractive (stack:Array<DisplayObject>):Bool {
		
		if (stack != null) {
			
			stack.push (this);
			
			if (parent != null) {
				
				parent.__getInteractive (stack);
				
			}
			
		}
		
		return true;
		
	}
	
	
	private override function __hitTest (x:Float, y:Float, shapeFlag:Bool, stack:Array<DisplayObject>, interactiveOnly:Bool, hitObject:DisplayObject):Bool {
		
		if (!hitObject.visible || __isMask || (interactiveOnly && !mouseEnabled)) return false;
		return super.__hitTest (x, y, shapeFlag, stack, interactiveOnly, hitObject);
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private function get_tabEnabled ():Bool {
		
		return __tabEnabled;
		
	}
	
	
	private function set_tabEnabled (value:Bool):Bool {
		
		return __tabEnabled = value;
		
	}

	private function get_needsSoftKeyboard ():Bool {
		
		return __needsSoftKeyboard;
		
	}
	
	
	private function set_needsSoftKeyboard (value:Bool):Bool {

		#if tivo_android
		if (value) {

			SoftKeyboardEventHandler.get().addListener(onKeyboardVisibilityChanged);

		}
		else {

			SoftKeyboardEventHandler.get().removeListener(onKeyboardVisibilityChanged);

		}
		#end

		return __needsSoftKeyboard = value;
		
	}

	private function onKeyboardVisibilityChanged(visibility:Bool):Void {

		if (needsSoftKeyboard) {
			
			var height:Int = 0;
			var width:Int = 0;
			#if tivo_android
			height = get_screen_height_jni();
			#end
			softKeyboardInputAreaOfInterest = new Rectangle(0, 0, width, height);

			dispatchEvent(new SoftKeyboardEvent(visibility ? SoftKeyboardEvent.SOFT_KEYBOARD_ACTIVATE : 
									 SoftKeyboardEvent.SOFT_KEYBOARD_DEACTIVATE, 
							    true, false, this, ""));

		}

	}
	
	#if tivo_android
	private static var init_jni =
	    lime.system.JNI.createStaticMethod(
            "openfl.display.SoftKeyboardStateProvider",
            "init",
            "(Lorg/haxe/lime/HaxeObject;)V");
	private static var get_screen_height_jni =
	    lime.system.JNI.createStaticMethod(
            "openfl.display.SoftKeyboardStateProvider",
            "getScreenHeight",
            "()I");
	private static var is_initiated_jni =
	    lime.system.JNI.createStaticMethod(
            "openfl.display.SoftKeyboardStateProvider",
            "isInitiated",
            "()Z");
	#end
}

#if tivo_android
/**
 * Helper-class which allows to call Haxe callbacks from Java code
 */
private class SoftKeyboardEventHandler {

	private static var gSoftKeyboardEventHandler:SoftKeyboardEventHandler;
	private var listenerCallbacks:Array<Bool->Void> = [];

	private function new() {

		onKeyboardVisibilityChanged = __onKeyboardVisibilityChanged;

	}

	public static function get():SoftKeyboardEventHandler {

		if (gSoftKeyboardEventHandler == null) {

			gSoftKeyboardEventHandler = new SoftKeyboardEventHandler();

		}
		return gSoftKeyboardEventHandler;

	}
	

	public var onKeyboardVisibilityChanged:Bool->Void;

	public function addListener(onKeyboardVisibilityChangedCallback:Bool->Void):Void {

		if (listenerCallbacks.indexOf(onKeyboardVisibilityChangedCallback) == -1) {

			listenerCallbacks.push(onKeyboardVisibilityChangedCallback);

		}

	}

	public function removeListener(onKeyboardVisibilityChangedCallback:Bool->Void):Void {

		listenerCallbacks.remove(onKeyboardVisibilityChangedCallback);

	}

	private function __onKeyboardVisibilityChanged(e:Bool):Void {

		for (callback in listenerCallbacks) {

			callback(e);

		}

	}
}
#end
