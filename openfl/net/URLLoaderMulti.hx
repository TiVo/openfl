package openfl.net;

// Single-threaded native URLLoader that uses the CURL multi support

#if !cpp
#error "URLLoaderMulti requires cpp target"
#end

import lime.app.Event;
import lime.system.BackgroundWorker;
import lime.system.CFFI;
import lime.utils.Bytes;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.HTTPStatusEvent;
import openfl.events.IOErrorEvent;
import openfl.events.ProgressEvent;
import openfl.errors.IOError;
import openfl.events.SecurityErrorEvent;
import openfl.events.TimerEvent;
import openfl.utils.ByteArray;
import openfl.utils.Timer;

#if lime_curl
import lime.net.curl.CURL;
import lime.net.curl.CURLEasy;
import lime.net.curl.CURLMulti;
import lime.net.curl.CURLCode;
import lime.net.curl.CURLInfo;
import lime.net.curl.CURLOption;
#else
#error "URLLoaderMulti requires lime_curl"
#end


@:access(openfl.events.Event)
class URLLoaderMulti extends EventDispatcher
{
    // Public properties
    public var bytesLoaded : Int;
    public var bytesTotal : Int;
    public var data : Dynamic;
    public var dataFormat : URLLoaderDataFormat;


    public function new(request : URLRequest = null)
    {
        super();

        this.bytesLoaded = 0;
        this.bytesTotal = 0;
        this.dataFormat = URLLoaderDataFormat.TEXT;

        if (request != null) {
            this.load(request);
        }
    }


    public function close()
    {
        if (mEasy == 0) {
            return;
        }

        // Prevent CURL badness
        var easy = mEasy;
        mEasy = 0;

        // Remove the mapping from the CURL to this loader
        gLoaderMap.remove(Std.string(easy));

        var index = gEasies.indexOf(easy);
        if (index != -1) {
            gEasies.splice(index, 1);
            if (gEasies.length == 0) {
                gTimer.stop();
            }
            // CURL will actually make callbacks directly from remove_handle,
            // which is surprisingly bad form.  This is why the mEasy had to
            // be immediately zeroed above, so that the callbacks are ignored.
            CURLMulti.remove_handle(gMulti, easy);
        }
        
        CURLEasy.cleanup(easy);

        data = mData = null;
        __removeAllListeners();
    }


    public function load(request : URLRequest)
    {
        // Null request URL is kind of meaningless; call it an error
        if (request.url == null) {
            var evt = new IOErrorEvent(IOErrorEvent.IO_ERROR);
            evt.currentTarget = this;
            this.asyncDispatchEvent(evt);
            return;
        }

        // HTTP request is handled via CURL
        if ((request.url.indexOf("http://") == 0) ||
            (request.url.indexOf("https://") == 0)) {
            this.requestUrl(request.url, request.method, request.data,
                            request.formatRequestHeaders());
            return;
        }

        // Non-HTTP request is handled via synchronous file load with
        // asynchronous event delivery
        var path = request.url;
        var index = path.indexOf("?");
        if (index > -1) {
            path = path.substring(0, index);
        }

        try {
            var bytes : ByteArray;

            // In order to allow all platforms to open file URLs in an
            // identical manner, if the path is relative, use
            // Assets.getBytes()
            if ((path.length > 0) && (path.charAt(0) != "/")) {
                bytes = openfl.Assets.getBytes(path);
            }
            else {
                bytes = Bytes.readFile (path);
            }

            if (bytes == null) {
                throw "Bytes.readFile";
            }

            switch (dataFormat) {
            case BINARY:
                this.data = bytes;
            default:
                this.data = bytes.readUTFBytes(bytes.length);
            }

            var evt = new Event(Event.COMPLETE);
            evt.currentTarget = this;
            this.asyncDispatchEvent(evt);
        }
        catch (e : Dynamic) {
            var evt = new IOErrorEvent(IOErrorEvent.IO_ERROR);
            evt.currentTarget = this;
            this.asyncDispatchEvent(evt);
        }
    }


    private function requestUrl(url : String, method : URLRequestMethod,
                                data : Dynamic,
                                requestHeaders : Array<URLRequestHeader>)
    {
        if (!gMultiInitialized) {
            gMulti = CURLMulti.init();
            gTimer = new Timer(0);
            gTimer.addEventListener(TimerEvent.TIMER, onTimer);
            gMultiInitialized = true;
        }

        if (mEasy != 0) {
            throw "requestUrl called while request already in progress";
        }
        mEasy = CURLEasy.init();
        gLoaderMap.set(Std.string(mEasy), this);

        var uri = prepareData(data);
        uri.position = 0;

        mData = new ByteArray();
        this.data = mData;
        this.bytesLoaded = 0;
        this.bytesTotal = 0;
        mStatus = 0;

        CURLEasy.setopt(mEasy, URL, url);

        switch (method) {
        case HEAD:
            CURLEasy.setopt(mEasy, NOBODY, true);

        case GET:
            CURLEasy.setopt(mEasy, HTTPGET, true);
            if (uri.length > 0) {
                CURLEasy.setopt(mEasy, URL,
                                url + "?" + uri.readUTFBytes(uri.length));
            }

        case POST:
            CURLEasy.setopt(mEasy, POST, true);
            CURLEasy.setopt(mEasy, READFUNCTION, readFunction.bind(_, uri));
            CURLEasy.setopt(mEasy, POSTFIELDSIZE, uri.length);
            CURLEasy.setopt(mEasy, INFILESIZE, uri.length);

        case PUT:
            CURLEasy.setopt(mEasy, UPLOAD, true);
            CURLEasy.setopt(mEasy, READFUNCTION, readFunction.bind(_, uri));
            CURLEasy.setopt(mEasy, INFILESIZE, uri.length);

        default:
            var reqMethod : String = method;
            CURLEasy.setopt(mEasy, CUSTOMREQUEST, reqMethod);
            CURLEasy.setopt(mEasy, READFUNCTION, readFunction.bind(_, uri));
            CURLEasy.setopt(mEasy, INFILESIZE, uri.length);
        }

        var headers : Array<String> = [];
        headers.push("Expect: "); // removes the default cURL value

        for (requestHeader in requestHeaders) {
            headers.push('${requestHeader.name}: ${requestHeader.value}');
        }

        CURLEasy.setopt(mEasy, FOLLOWLOCATION, true);
        CURLEasy.setopt(mEasy, AUTOREFERER, true);
        CURLEasy.setopt(mEasy, HTTPHEADER, headers);

        CURLEasy.setopt(mEasy, HEADERFUNCTION, headerFunction);
        CURLEasy.setopt(mEasy, WRITEFUNCTION, writeFunction);

        CURLEasy.setopt(mEasy, SSL_VERIFYPEER, false);
        CURLEasy.setopt(mEasy, SSL_VERIFYHOST, 0);
        CURLEasy.setopt(mEasy, USERAGENT, "libcurl-agent/1.0");
        CURLEasy.setopt(mEasy, CONNECTTIMEOUT, 30);

        CURLEasy.setopt(mEasy, TRANSFERTEXT, (dataFormat == BINARY) ? 0 : 1);

        // Add the easy to the multi
        CURLMulti.add_handle(gMulti, mEasy);
        // Add the easy to the set of easies being watched
        gEasies.push(mEasy);

        // If this is the first easy, start the multi timer, going off
        // immediately to handle immediate status
        if (gEasies.length == 1) {
            gTimer.delay = 0.0;
            gTimer.start();
        }
    }


    private static function prepareData(data : Dynamic) : ByteArray
    {
        var uri = new ByteArray();

        if (Std.is(data, ByteArrayData)) {
            var data : ByteArray = cast data;
            uri = data;
        }
        else if (Std.is(data, URLVariables)) {
            var data : URLVariables = cast data;
            var tmp : String = "";

            for (p in Reflect.fields(data)) {
                if (tmp.length != 0) {
                    tmp += "&";
                }
                tmp += (StringTools.urlEncode(p) + "=" +
                        StringTools.urlEncode
                        (Std.string(Reflect.field(data, p))));
            }

            uri.writeUTFBytes(tmp);
        }
        else if (data != null) {
            uri.writeUTFBytes(Std.string(data));
        }

        return uri;
    }


    private function readFunction(max : Int, input : ByteArray) : Bytes
    {
        if (mEasy != 0) {
            // CURL sometimes calls its callbacks while it is being cleaned up
            this.checkStatus();
        }

        return input;
    }


    private function headerFunction(output : haxe.io.Bytes, size : Int,
                                    nmemb : Int) : Int
    {
        if (mEasy != 0) {
            // CURL sometimes calls its callbacks while it is being cleaned up
            this.checkStatus();
        }

        // Ignore headers for now
        return (size * nmemb);
    }


    private function writeFunction(output : haxe.io.Bytes, size : Int,
                                   nmemb : Int) : Int
    {
        if (mEasy != 0) {
            // CURL sometimes calls its callbacks while it is being cleaned up
            this.checkStatus();
            
            mData.writeBytes(ByteArray.fromBytes(output));
        }

        return (size * nmemb);
    }


    private function checkProgress()
    {
        this.checkStatus();

        var dltotal : Int = CURLEasy.getinfo(mEasy, CONTENT_LENGTH_DOWNLOAD);
        var dlnow : Int = CURLEasy.getinfo(mEasy, SIZE_DOWNLOAD);

        var progress = false;

        if (dltotal > this.bytesTotal) {
            this.bytesTotal = Std.int(dltotal);
            progress = true;
        }

        if (dlnow > this.bytesLoaded) {
            this.bytesLoaded = Std.int(dlnow);
            progress = true;
        }

        if (progress) {
            var evt = new ProgressEvent(ProgressEvent.PROGRESS);
            evt.currentTarget = this;
            evt.bytesLoaded = bytesLoaded;
            evt.bytesTotal = bytesTotal;
            this.dispatchEvent(evt);
        }

        // If the download total is reached, then the load is done; but if the
        // total data is <= 0, the total is not known yet.
        if ((dltotal > 0) && (dlnow == dltotal)) {
            // If everything has been downloaded, then act like the socket has
            // been closed
            var evt = new Event(Event.COMPLETE);
            evt.currentTarget = this;
            this.dispatchEvent(evt);
            this.close();
        }
        // If the curl socket is dead, then it's an IO error
        else if (cast(CURLEasy.getinfo(mEasy, LASTSOCKET), Int) == -1) {
            var evt = new IOErrorEvent(IOErrorEvent.IO_ERROR);
            evt.currentTarget = this;
            this.dispatchEvent(evt);
            this.close();
        }

        return 0;
    }


    private static function onTimer(e : Event)
    {
        // Because the CURL library seems to be very flaky when it comes to
        // making CURL calls from within the progress function callback, don't
        // use a progress function callback; instead manually poll all CURL
        // easy handles of interest after doing CURLMulti.perform.

        if (gEasies.length > 0) {
            // Run curl_multi_perform, which will fill in the array with
            // the easy handles that are known to be done
            CURLMulti.perform(gMulti, gMultiEasyReady);
            var i = 0;
            while (i < gMultiEasyReady.length) {
                var loader = gLoaderMap.get(Std.string(gMultiEasyReady[i++]));
                if (loader != null) {
                    loader.checkProgress();
                }
            }
            gMultiEasyReady.splice(0, gMultiEasyReady.length);
        }

        // If there are still connections being tracked, restart the timer
        if (gEasies.length > 0) {
            if (gTimer.delay != gTimerDelay) {
                gTimer.delay = gTimerDelay;
            }
            gTimer.start();
        }
        // Else ensure that the timer is stopped
        else {
            gTimer.stop();
        }
    }


    // If status is not yet known, announce it if it is now known
    private function checkStatus()
    {
        if (mStatus != 0) {
            // Already announced status
            return;
        }

        mStatus = CURLEasy.getinfo(mEasy, RESPONSE_CODE);

        if (mStatus == 0) {
            // Still don't have status
            return;
        }

        // Announce newly acquired status
        var evt = new HTTPStatusEvent
            (HTTPStatusEvent.HTTP_STATUS, false, false, mStatus);
        evt.currentTarget = this;
        this.dispatchEvent(evt);
    }


    private function asyncDispatchEvent(evt : Event)
    {
        var timer = new Timer(0.0);
        timer.addEventListener(TimerEvent.TIMER,
                               function (e)
                               {
                                   this.dispatchEvent(evt);
                                   timer.stop();
                               });
        timer.start();
    }


    private dynamic function getData() : Dynamic
    {
        return null;
    }


    private var mEasy : CURL;
    private var mData : ByteArray;
    private var mStatus : Int;

    private static var gMultiInitialized : Bool = false;
    private static var gMulti : CURL;
    private static var gMultiEasyReady : Array<CURL> = [ ];
    private static var gLoaderMap : Map<String, URLLoaderMulti> =
        new Map<String, URLLoaderMulti>();
    private static var gEasies : Array<CURL> = [ ];
    private static var gTimer : Timer;
    private static var gTimerDelay : Float = (1.0 / 10.0);
}
