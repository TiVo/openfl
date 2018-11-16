package openfl._internal.media;


import lime.system.JNI;
import openfl.display.BitmapData;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.LocationChangeEvent;
import openfl.geom.Rectangle;


class StageWebViewAndroid extends StageWebViewCommon {

    private var mJavaWebViewController : Dynamic;

    public function new()
    {
        super();
        mJavaWebViewController = createJavaWebViewController();
    }

    public function createJavaWebViewController() : Dynamic
    { 
        return gWebViewCtrlConstructor(this);
    }

    override public function dispose() : Void
    {
        super.dispose();
        gWebViewCtrlDispose(mJavaWebViewController);
        mJavaWebViewController = null;
    }
   
    override public function freezeScrollFocus(shouldFreezeScrollFocus : Bool) : Void
    {
        gWebViewCtrlFreezeScrollFocus(mJavaWebViewController, shouldFreezeScrollFocus);
    }

    override public function drawViewPortToBitmapData(bitmap : BitmapData): Void
    {
        throw "StageWebViewAndroid drawViewPortToBitmapData() is not implemented for Android";
    }

    override public function historyBack() : Void
    {
        gWebViewCtrlGoBack(mJavaWebViewController);
    }

    override public function historyForward() : Void
    {
        gWebViewCtrlGoForward(mJavaWebViewController);
    }

    override public function loadString(text : String, mimeType : String = "text/html") : Void
    {
        gWebViewCtrlLoadString(mJavaWebViewController, text, mimeType);
    }

    override public function loadURL(url : String) : Void
    {
        gWebViewCtrlLoadUrl(mJavaWebViewController, url);
    }

    override public function reload() : Void
    {
        gWebViewCtrlReload(mJavaWebViewController);
    }

    override public function stop() : Void
    {
        gWebViewCtrlStopLoading(mJavaWebViewController);
    }

    override public function setVerticalScrollBarEnabled(enabled : Bool) : Void
    {
        gWebViewSetVerticalScrollBarEnabled(mJavaWebViewController, enabled);
    }

    override private function get_isHistoryBackEnabled() : Bool
    {
        return gWebViewCtrlCanGoBack(mJavaWebViewController);
    }
    
    override private function get_isHistoryForwardEnabled() : Bool
    {
        return gWebViewCtrlCanGoForward(mJavaWebViewController);
    }
    
    override private function get_isSupported() : Bool
    {
        return true;
    }
    
    override private function get_location() : String
    {
        return gWebViewCtrlGetUrl(mJavaWebViewController);
    }
    
    override private function get_mediaPlaybackRequiresUserAction() : Bool
    {
        return gWebViewCtrlGetPlaybackRequiresGesture(mJavaWebViewController);
    }
    
    override private function set_mediaPlaybackRequiresUserAction(newVal: Bool) : Bool
    {
        gWebViewCtrlSetPlaybackRequiresGesture(mJavaWebViewController, newVal);
        return newVal;
    }
    
    override private function get_stage() : Stage
    {
        return mStage;
    }
    
    override private function set_stage(newVal : Stage) : Null<Stage>
    {
        mStage = newVal;
        if (!mViewPort.isEmpty() && mStage != null)
        {
            gWebViewCtrlSetVisible(mJavaWebViewController, true);
        }
        else if (mStage == null)
        {
            gWebViewCtrlSetVisible(mJavaWebViewController, false);
        }
        return mStage;
    }
    
    override private function get_title() : String {
        return gWebViewCtrlGetTitle(mJavaWebViewController);
    }

    override private function setNativeWebViewVisible(isVisible : Bool) : Void
    {
        gWebViewCtrlSetVisible(mJavaWebViewController, isVisible);
    }

    override private function setNativeWebViewViewPort(newVal : Rectangle) : Void
    {
        gWebViewCtrlSetViewPort(mJavaWebViewController,
                                          Std.int(newVal.x),
                                          Std.int(newVal.y),
                                          Std.int(newVal.width),
                                          Std.int(newVal.height));
    }

    override private function setNativeWebViewEventHandlingEnabled(isEnabled : Bool) : Void
    {
        gWebViewCtrlSetEventHandlingEnabled(mJavaWebViewController, isEnabled);
    }

    private static function loadStaticMethod(name : String, signature : String) : Dynamic
    {
        return lime.system.JNI.createStaticMethod("openfl.media.StageWebViewController", name, signature);
    }

    private static function loadMemberMethod(name : String, signature : String) : Dynamic
    {
        return lime.system.JNI.createMemberMethod("openfl.media.StageWebViewController", name, signature);
    }

    private static var gWebViewCtrlConstructor = loadStaticMethod("<init>", "(Lorg/haxe/lime/HaxeObject;)V");
    private static var gWebViewCtrlCanGoBack = loadMemberMethod("canGoBack", "()Z");
    private static var gWebViewCtrlCanGoForward = loadMemberMethod("canGoForward", "()Z");
    private static var gWebViewCtrlGetPlaybackRequiresGesture = loadMemberMethod("getMediaPlaybackRequiresUserGesture",
                                                                                 "()Z");
    private static var gWebViewCtrlSetPlaybackRequiresGesture = loadMemberMethod("setMediaPlaybackRequiresUserGesture",
                                                                                 "(Z)V");
    private static var gWebViewCtrlGoBack = loadMemberMethod("goBack", "()V");
    private static var gWebViewCtrlGoForward = loadMemberMethod("goForward", "()V");
    private static var gWebViewCtrlReload = loadMemberMethod("reload", "()V");
    private static var gWebViewCtrlStopLoading = loadMemberMethod("stopLoading", "()V");
    private static var gWebViewCtrlLoadUrl = loadMemberMethod("loadUrl", "(Ljava/lang/String;)V");
    private static var gWebViewCtrlLoadString = loadMemberMethod("loadString",
                                                                 "(Ljava/lang/String;Ljava/lang/String;)V");
    private static var gWebViewSetVerticalScrollBarEnabled = loadMemberMethod("setVerticalScrollBarEnabled", "(Z)V");
    private static var gWebViewCtrlSetVisible = loadMemberMethod("setVisible", "(Z)V");
    private static var gWebViewCtrlSetViewPort = loadMemberMethod("setViewPort", "(IIII)V");
    private static var gWebViewCtrlGetTitle = loadMemberMethod("getTitle", "()Ljava/lang/String;");
    private static var gWebViewCtrlSetEventHandlingEnabled = loadMemberMethod("setEventHandlingEnabled", "(Z)V");
    private static var gWebViewCtrlDispose = loadMemberMethod("dispose", "()V");
    private static var gWebViewCtrlGetUrl = loadMemberMethod("getUrl", "()Ljava/lang/String;");
    private static var gWebViewCtrlFreezeScrollFocus = loadMemberMethod("freezeScrollFocus", "(Z)V");

}
