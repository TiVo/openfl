package openfl._internal.media;


#if cpp
import cpp.vm.Mutex;
#end
import lime.system.JNI;
import openfl.display.BitmapData;
import openfl.display.Stage;
import openfl.errors.RangeError;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.FocusEvent;
import openfl.events.ErrorEvent;
import openfl.events.LocationChangeEvent;
import openfl.geom.Rectangle;
import openfl.ui.Keyboard;


/**
 * This is a part of StageWebView implementation common for all platforms.
 *
 * It covers logic for stage and viewPort vars and provides handling of all
 * events emitted by StageWebView.
 * 
 * A StageWebView implementation for a particular platform should:
 * - Subclass from the StageWebViewCommon;
 * - Provide implementations for all StageWebViewCommon functions throwing
 *   "Must be implemented by subclass" exceptions;
 * - Call the StageWebViewCommon's handle*() functions in response to proper
 *   native WebView events.
 */
class StageWebViewCommon extends EventDispatcher {

    public var isHistoryBackEnabled(get, null) : Bool;
    public var isHistoryForwardEnabled(get, null) : Bool;
    public var isSupported(get, null) : Bool;
    public var location(get, null) : String;
    public var mediaPlaybackRequiresUserAction(get, set) : Bool;
    public var stage(get, set) : Null<Stage>;
    public var title(get, null) : String;
    public var viewPort(get, set) : Rectangle;

#if cpp
    private static var gLock : Mutex = new Mutex();
#end
    private static var gOpenFlThreadScheduledFuncs: Array<Void -> Void> = [ ];

    private var mStage : Stage;
    private var mViewPort : Rectangle;

    public function new()
    {
        super();
    }

    public function init() : Void
    {
        mViewPort = new Rectangle();
        setNativeWebViewEventHandlingEnabled(false);
        setNativeWebViewVisible(false);
        setNativeWebViewViewPort(mViewPort);
        openfl.Lib.current.stage.addEventListener(openfl.events.Event.ENTER_FRAME, onFrameEnter);
    }

    public function assignFocus() : Void
    {
        setNativeWebViewEventHandlingEnabled(true);
        var ev : FocusEvent = new FocusEvent(FocusEvent.FOCUS_IN,
                                             false,
                                             false,
                                             mStage.focus,
                                             false,
                                             0);
        dispatchEvent(ev);
        mStage.dispatchEvent(ev);
    }
   
    public function freezeScrollFocus(shouldFreezeScrollFocus : Bool) : Void
    {
         throw 'StageWebViewCommon freezeScrollFocus(): Must be implemented by subclass';
    }
 
    public function dispose() : Void
    {
        openfl.Lib.current.stage.removeEventListener(openfl.events.Event.ENTER_FRAME, onFrameEnter);
    }

    public function drawViewPortToBitmapData(bitmap : BitmapData): Void
    {
        throw 'StageWebViewCommon drawViewPortToBitmapData(): Must be implemented by subclass';
    }

    public function historyBack() : Void
    {
        throw 'StageWebViewCommon historyBack(): Must be implemented by subclass';
    }

    public function historyForward() : Void
    {
        throw 'StageWebViewCommon historyForward(): Must be implemented by subclass';
    }

    public function loadString(text : String, mimeType : String = "text/html") : Void
    {
        throw 'StageWebViewCommon loadString(): Must be implemented by subclass';
    }

    public function loadURL(url : String) : Void
    {
        throw 'StageWebViewCommon loadURL(): Must be implemented by subclass';
    }

    public function reload() : Void
    {
        throw 'StageWebViewCommon reload(): Must be implemented by subclass';
    }

    public function stop() : Void
    {
        throw 'StageWebViewCommon stop(): Must be implemented by subclass';
    }

    public function setVerticalScrollBarEnabled(enabled : Bool) : Void
    {
        throw 'StageWebViewCommon setVerticalScrollBarEnabled(): Must be implemented by subclass';
    }

    @:keep
    public function handleLocationChangingEvent(url : String) : Void
    {
        dispatchWebViewEvent(new LocationChangeEvent(LocationChangeEvent.LOCATION_CHANGING, false, false, url));
    }

    @:keep
    public function handleLocationChangeEvent(url : String) : Void
    {
        dispatchWebViewEvent(new LocationChangeEvent(LocationChangeEvent.LOCATION_CHANGE, false, false, url));
    }

    @:keep
    public function handleCompleteEvent() : Void
    {
        dispatchWebViewEvent(new Event(Event.COMPLETE, false, false));
    }

    @:keep
    public function handleErrorEvent(errorCode : Int, description : String, failingUrl : String) : Void
    {
        dispatchWebViewEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, '$failingUrl: $description', errorCode));
    }
 
    public function dispatchWebViewEvent(event : Event) : Void
    {
        scheduleOnOpenFlThread(function () {
            dispatchEvent(event);
        });

    }

    /**
     * All OpenFL UI is rendered within a single platform's native view (SDL
     * surface), and native WebView is a separate native view in platform's view
     * hierarchy. It means that any user's input events are not delivered to SDL
     * surface (and, correspondingly, to any OpenFL DisplayObjects) when a
     * native WebView has focus.
     * This is why any OpenFL's DisplayObject has no chance to detect when focus
     * should be revoked from StageWebView. That's why native WebView must call
     * this function when a user performs an action that should cause focus
     * transfer from StageWebView to some DisplayObject presented on Stage (for
     * example, user reaches a web page content's bottom and presses DOWN key).
     */
    @:keep
    public function handleWebViewFocusLoss(isVertical: Bool, isPrev: Bool) : Void
    {
        var keyCode : Int = 0;
        if (isVertical && isPrev)
        {
            keyCode = Keyboard.UP;
        }
        else if (isVertical && !isPrev)
        {
            keyCode = Keyboard.DOWN;
        }
        else if (!isVertical && isPrev)
        {
            keyCode = Keyboard.LEFT;
        }
        else if (!isVertical && !isPrev)
        {
            keyCode = Keyboard.RIGHT;
        }

        scheduleOnOpenFlThread(function () {
            setNativeWebViewEventHandlingEnabled(false);
            var ev : FocusEvent = new FocusEvent(FocusEvent.FOCUS_OUT,
                                                 false,
                                                 false,
                                                 null,
                                                 false,
                                                 keyCode);
            dispatchEvent(ev);
            mStage.dispatchEvent(ev);
        }); 
    }

    private static function scheduleOnOpenFlThread(func : Void -> Void)
    {
        if (func == null)
        {
            return;
        }
    #if cpp
        gLock.acquire();
    #end
        gOpenFlThreadScheduledFuncs.push(func);

    #if cpp
        gLock.release();
    #end
    }

    private static function onFrameEnter(e : Dynamic)
    {
        if (gOpenFlThreadScheduledFuncs.length == 0)
        {
            return;
        }
    #if cpp
        gLock.acquire();
    #end
        while (gOpenFlThreadScheduledFuncs.length > 0)
        {
            var func = gOpenFlThreadScheduledFuncs.pop();
            lime.app.Application.current.schedule(func);
        }
    #if cpp
        gLock.release();
    #end
    }

    private function get_stage() : Stage
    {
        return mStage;
    }
    
    private function set_stage(newStage : Stage) : Null<Stage>
    {
        mStage = newStage;
        if (!mViewPort.isEmpty() && mStage != null)
        {
            setNativeWebViewVisible(true);
        }
        else if (mStage == null)
        {
            setNativeWebViewVisible(false);
        }
        return mStage;
    }
    
    private function get_viewPort() : Rectangle
    {
        return mViewPort;
    }
    
    private function set_viewPort(newVal : Rectangle) : Rectangle
    {
        if (newVal.isEmpty())
        {
            throw new RangeError('StageWebView: Attempt to set invalid viewPort $newVal');
        }

        mViewPort = newVal;
        setNativeWebViewViewPort(mViewPort);
        if (!mViewPort.isEmpty() && mStage != null)
        {
            setNativeWebViewVisible(true);
        }

        return mViewPort;
    }

    private function get_isHistoryBackEnabled() : Bool
    {
        throw 'StageWebViewCommon get_isHistoryBackEnabled(): Must be implemented by subclass';
    }
    
    private function get_isHistoryForwardEnabled() : Bool
    {
        throw 'StageWebViewCommon get_isHistoryForwardEnabled(): Must be implemented by subclass';
    }
    
    private function get_isSupported() : Bool
    {
        throw 'StageWebViewCommon get_isSupported(): Must be implemented by subclass';
    }
    
    private function get_location() : String
    {
        throw 'StageWebViewCommon get_location(): Must be implemented by subclass';
    }
    
    private function get_mediaPlaybackRequiresUserAction() : Bool
    {
        throw 'StageWebViewCommon get_mediaPlaybackRequiresUserAction(): Must be implemented by subclass';
    }
    
    private function set_mediaPlaybackRequiresUserAction(newVal: Bool) : Bool
    {
        throw 'StageWebViewCommon set_mediaPlaybackRequiresUserAction(): Must be implemented by subclass';
    }

    private function get_title() : String {
        throw 'StageWebViewCommon get_title(): Must be implemented by subclass';
    }
    
    private function setNativeWebViewVisible(isVisible : Bool) : Void
    {
        throw 'StageWebViewCommon setNativeWebViewVisible(): Must be implemented by subclass';
    }

    private function setNativeWebViewViewPort(newVal : Rectangle) : Void
    {
        throw 'StageWebViewCommon setNativeWebViewViewPort(): Must be implemented by subclass';
    }

    private function setNativeWebViewEventHandlingEnabled(isEnabled : Bool) : Void
    {
        throw 'StageWebViewCommon setNativeWebViewEventHandlingEnabled(): Must be implemented by subclass';
    }
}
