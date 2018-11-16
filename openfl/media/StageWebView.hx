package openfl.media;

import openfl.display.BitmapData;
import openfl.geom.Rectangle;


#if display
typedef StageWebView = StageWebViewPrototype;
#elseif android
typedef StageWebView = openfl._internal.media.StageWebViewAndroid;
#elseif (appletvos || appletvsim)
typedef StageWebView = openfl._internal.media.StageWebViewTvos;
#else
typedef StageWebView = openfl._internal.media.StageWebViewStub;
#end


/**
 * The StageWebView class displays HTML content in a stage view port.
 *
 * The StageWebView class provides a simple means to display HTML content on
 * devices where the HTMLLoader class is not supported. The class provides no
 * interaction between ActionScript and the HTML content except through the
 * methods and properties of the StageWebView class itself. There is, for
 * example, no way to pass values or call functions between ActionScript and
 * JavaScript.
 *
 * The StageWebView class is NOT a display object and cannot be added to Stage's
 * display objects hierarchy. Instead you display a StageWebView object by
 * attaching it directly to a stage using the stage property. The StageWebView
 * instance attached to a stage is displayed on top of any OpenFL display
 * objects. You control the size and position of the rendering area with the
 * viewPort property. There is no way to control the depth ordering of different
 * StageWebView objects. Overlapping two instances is not recommended.
 *
 * When the content within the StageWebView object has focus, the StageWebView
 * object has the first opportunity to handle keyboard input. The stage to which
 * the StageWebView object is attached dispatches any keyboard input that is not
 * handled. The normal event capture/bubble cycle does not apply here since the
 * StageWebView instance is not part of the display list.
 *
 * Events dispatched:
 * - Event.COMPLETE: Signals that the last load operation requested by
 *                   loadString() or loadURL() method has completed.
 * - ErrorEvent: Signals that an error has occurred.
 * - FocusEvent: Dispatched when this StageWebView object receives or
 *      relinquishes focus.
 * - LocationChangeEvent: Signals that the location property of the StageWebView
 *                        object is about to change or has changed.
 */
#if display
class StageWebViewPrototype extends EventDispatcher {

    /**
     * Reports whether there is a previous page in the browsing history.
     *
     * @return true if there is a previous page in the browsing history.
     */
    public var isHistoryBackEnabled(get, null) : Bool;

    /**
     * Reports whether there is a next page in the browsing history.
     *
     * @return true if there is a next page in the browsing history.
     */
    public var isHistoryForwardEnabled(get, null) : Bool;

    /**
     * Reports whether the StageWebView class is supported on the current
     * device.
     *
     * @return true if the StageWebView class is supported on the current
     *         device.
     */
    public var isSupported(get, null) : Bool;

    /**
     * The URL of the current location.
     *
     * @return String containing the URL of the current location.
     */
    public var location(get, null) : String;

    /**
     * Set whether User is required to perform gesture to play media content.
     * Default value is true.
     *
     * @param A boolean indicating if User is required to perform gesture to
     *        play media content.
     * @return true if User is required to perform gesture to play media
     *         content.
     */
    public var mediaPlaybackRequiresUserAction(get, set) : Bool;


    /**
     * The stage on which this StageWebView object is displayed.
     *
     * @param A stage where this StageWebView should be displayed. Set stage to
     *        null to hide this StageWebView object.
     * @return The stage on which this StageWebView object is displayed.
     */
    public var stage(get, set) : Null<Stage>;

    /**
     * The HTML title value.
     *
     * @return String containing the HTML title value.
     */
    public var title(get, null) : String;

    /**
     * The area on the stage in which the StageWebView object is displayed.
     *
     * @param The area on the stage in which the StageWebView object should be
     *        displayed. Throws an exception if Rectangle value is invalid.
     * @return The area on the stage in which the StageWebView object is
     *         displayed.
     */
    public var viewPort(get, set) : Null<Rectangle>;

    /**
     * Creates a StageWebView object.
     * The object is invisible until it is attached to a stage and until the
     * viewPort is set.
     */
    public function new();

    /**
     * Assigns focus to the content within this StageWebView object.
     *
     * Since StageWebView is not a DisplayObject, calling of this function is
     * the only way to transfer focus to StageWebView and correspondingly enable
     * events handling by StageWebView. Calling thgis function dispatches
     * FOCUS_IN event.
     * 
     * A StageWebView implementation will dispatch FOCUS_OUT event when a user
     * presses up/down/left/right keys being at the top/bottom/left/right edge
     * of StageWebView content.
     */
    public function assignFocus() : Void;
    
    /**
     * If freezeScrollFocus is set the webView will not give up focus event when it
     * is scrolled to the end. This is for screens that only have a webview and wish
     * to retain the focus only on it.
     * @param shouldFreezeScrollFocus sets or unsets the scrollFocus on the webView.
     */
    public function freezeScrollFocus(shouldFreezeScrollFocus : Bool) : Void;

    /**
     * Disposes of this StageWebView object.
     *
     * Calling dispose() is mandatory.
     */
    public function dispose() : Void;

    /**
     * Draws the StageWebView's view port to a bitmap.
     *
     * Capture the bitmap and set the stage to null for displaying the content
     * above the StageWebView object.
     *
     * Throws:
     * - ArgumentError: The bitmap's width or height is different from view
     *                  port's width or height.
     * - Error: The bitmap is null.
     *
     * @param bitmap — The BitmapData object on which to draw the visible
     *                 portion of the StageWebView's view port.
     */
    public function drawViewPortToBitmapData(bitmap : BitmapData): Void;

    /**
     * Navigates to the previous page in the browsing history.
     */
    public function historyBack() : Void;

    /**
     * Navigates to the next page in the browsing history.
     */
    public function historyForward() : Void;

    /**
     * Loads and displays the specified HTML string.
     *
     * When the loadString() method is used, the location is reported as
     * "about:blank." Only standard URI schemes can be used in URLs within the
     * HTML string.
     *
     * The HTML content cannot load local resources, such as image files.
     * XMLHttpRequests are not allowed.
     *
     * Only the "text/html" and "application/xhtml+xml" MIME types are
     * supported.
     *
     * @param text — the string of HTML or XHTML content to display.
     * mimeType — The MIME type of the content, either "text/html" or
     *            "application/xhtml+xml".
     */
    public function loadString(text : String,
                               mimeType : String = "text/html") : Void;

    /**
     * Loads the page at the specified URL.
     *
     * The URL can use the following URI schemes: http:, https:, file:, data:,
     * and javascript:. Content loaded with the file: scheme can load other
     * local resources.
     * @param url
     */
    public function loadURL(url : String) : Void;

    /**
     * Reloads the current page.
     */
    public function reload() : Void;

    /**
     * Halts the current load operation.
     */
    public function stop() : Void;

    /**
     * Sets vertical scrollbar visibility 
     *
     * @param enabled sets visibility of vertical scrollbar.
     */
    public function setVerticalScrollBarEnabled(enabled : Bool) : Void;
}
#end
