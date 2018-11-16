package openfl._internal.media;


import openfl.display.BitmapData;
import openfl.geom.Rectangle;


class StageWebViewTvos extends extends StageWebViewCommon {

    public function new() {
        super()
    }

    override public function dispose() : Void {
        super.dispose();
        // TODO
    }

    override public function drawViewPortToBitmapData(bitmap : BitmapData): Void {
        // TODO
    }

    override public function historyBack() : Void {
        // TODO
    }

    override public function historyForward() : Void {
        // TODO
    }

    override public function loadString(text : String,
                                        mimeType : String = "text/html") : Void {
        // TODO
    }

    override public function loadURL(url : String) : Void {
        // TODO
    }

    override public function reload() : Void {
        // TODO
    }

    override public function stop() : Void {
        // TODO
    }

    override public function setVerticalScrollBarEnabled(enabled : Bool) : Void
    {
        // TODO
    }

    override private function get_isHistoryBackEnabled() : Bool
    {
        // TODO
        return false;
    }
    
    override private function get_isHistoryForwardEnabled() : Bool
    {
        // TODO
        return false;
    }
    
    override private function get_isSupported() : Bool
    {
        // TODO
        return false;
    }
    
    override private function get_location() : String
    {
        // TODO
        return "";
    }
    
    override private function get_mediaPlaybackRequiresUserAction() : Bool
    {
        // TODO
        return false;
    }
    
    override private function set_mediaPlaybackRequiresUserAction(newVal: Bool) : Bool
    {
        // TODO
        return false;
    }
        
    override private function get_title() : String {
        // TODO
        return "";
    }

    override private function setNativeWebViewVisible(isVisible : Bool) : Void
    {
        // TODO
    }

    override private function setNativeWebViewViewPort(newVal : Rectangle) : Void
    {
        // TODO
    }

    override private function setNativeWebViewEventHandlingEnabled(isEnabled : Bool) : Void
    {
        // TODO
    }
}
