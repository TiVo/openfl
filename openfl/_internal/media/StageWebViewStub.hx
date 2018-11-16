package openfl._internal.media;


import openfl.display.BitmapData;
import openfl.display.Stage;
import openfl.events.EventDispatcher;
import openfl.geom.Rectangle;


class StageWebViewStub extends EventDispatcher {

    public var isHistoryBackEnabled(get, null) : Bool;
    public var isHistoryForwardEnabled(get, null) : Bool;
    public var isSupported(get, null) : Bool;
    public var location(get, null) : String;
    public var mediaPlaybackRequiresUserAction(get, set) : Bool;
    public var stage(get, set) : Null<Stage>;
    public var title(get, null) : String;
    public var viewPort(get, set) : Null<Rectangle>;

    public function new() { super(); }

    public function init() : Void {  }

    public function dispose() : Void {  }

    public function assignFocus() : Void {  }
 
    public function freezeScrollFocus(shouldFreezeScrollFocus : Bool) : Void { }

    public function drawViewPortToBitmapData(bitmap : BitmapData): Void {  }

    public function historyBack() : Void {  }

    public function historyForward() : Void {  }

    public function loadString(text : String,
                               mimeType : String = "text/html") : Void {  }

    public function loadURL(url : String) : Void {  }

    public function reload() : Void {  }

    public function stop() : Void {  }

    public function setVerticalScrollBarEnabled(enabled : Bool) : Void {  }

    private function get_isHistoryBackEnabled() : Bool { return false; }
    private function get_isHistoryForwardEnabled() : Bool { return false; }
    private function get_isSupported() : Bool { return false; }
    private function get_location() : String { return ""; }
    private function get_mediaPlaybackRequiresUserAction() : Bool {
        return false;
    }
    private function set_mediaPlaybackRequiresUserAction(newVal: Bool) : Bool {
        return false;
    }
    private function get_stage() : Null<Stage> { return null; }
    private function set_stage(newVal : Stage) : Null<Stage> { return null; }
    private function get_title() : String { return ""; }
    private function get_viewPort() : Null<Rectangle> { return null; }
    private function set_viewPort(newVal : Rectangle) : Null<Rectangle> {
        return null;
    }
}
