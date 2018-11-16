package openfl.media;

import android.content.Context;
import android.graphics.Bitmap;
import android.net.http.SslError;
import android.util.Log;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewGroupOverlay;
import android.webkit.SslErrorHandler;
import android.webkit.WebResourceResponse;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.AbsoluteLayout;

import java.util.concurrent.Callable;

import org.haxe.extension.Extension;
import org.haxe.lime.HaxeObject;

public class StageWebViewController
{
    protected class StageWebViewClient extends WebViewClient
    {
        public StageWebViewClient()
        {
            super();
        }

        @Override
        public void onPageStarted(WebView view, String url, Bitmap favicon)
        {
            Log.v(LOG_TAG, "onPageStarted for URL: " + url);
            mHaxeObject.call("handleLocationChangingEvent", new Object[] { url });
        }

        @Override
        public void onPageFinished(WebView view, String url)
        {
            Log.v(LOG_TAG, "onPageFinished for URL: " + url);
            Log.v(LOG_TAG, "invoking Haxe event handler, for location change event...");
            mHaxeObject.call("handleLocationChangeEvent", new Object[] { url });
            Log.v(LOG_TAG, "invoking Haxe event handler, for page load complete event...");
            mHaxeObject.call0("handleCompleteEvent");
        }

        @Override
        public void onReceivedError(WebView view, int errorCode, String description, String failingUrl)
        {
            Log.v(LOG_TAG, "invoking Haxe event handler, for *error* event...");
            mHaxeObject.call("handleErrorEvent", new Object[] { errorCode, description, failingUrl });
        }

        @Override
        public void onReceivedSslError(WebView view, SslErrorHandler handler, SslError error)
        {
            if (error.hasError(SslError.SSL_DATE_INVALID) ||
                error.hasError(SslError.SSL_EXPIRED) ||
                error.hasError(SslError.SSL_IDMISMATCH) ||
                error.hasError(SslError.SSL_INVALID) ||
                error.hasError(SslError.SSL_NOTYETVALID) ||
                error.hasError(SslError.SSL_UNTRUSTED)) {
                Log.e(LOG_TAG, "SSL error: \"" + error.toString() +
                      "\". Cancelling loading.");
                handler.cancel();
            }
            else {
                Log.e(LOG_TAG, "SSL error (unknown): \"" +
                      error.toString() + "\". Cancelling loading.");
                handler.cancel();
            }
        }

        @Override
        public WebResourceResponse shouldInterceptRequest(WebView view, String url)
        {
            return null;
        }
    }

    private class SyncOperationParams<T>
    {
        public T result;
        public boolean isOperationInProgress;

        public SyncOperationParams(T defaultValue)
        {
            result = defaultValue;
            isOperationInProgress = true;
        }
    }

    private static final String LOG_TAG = "StageWebViewController";
    private static final String SDL_VIEW_CLASS_NAME = "org.libsdl.app.SDLSurface";
    private static final String USER_AGENT = "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.4) Gecko/20100101 Firefox/4.0";

    protected StageWebView mWebView;

    private HaxeObject mHaxeObject;
    private ViewGroup  mParentView;
    private View mSdlView;

    public StageWebViewController(HaxeObject object)
    {
        super();

        mHaxeObject = object;

        // Create a WebView instance in context of Android UI thread
        Extension.callbackHandler.post(new Runnable() {
            public void run()
            {
                mWebView = setupWebView();
            }
        });
    }

    public StageWebView setupWebView()
    {
        // Find the OpenFL view
        if (!(Extension.mainView instanceof ViewGroup))
        {
            throw new RuntimeException("Extension.mainView is not a ViewGroup");
        }

        mParentView = (ViewGroup) Extension.mainView;
        mSdlView = null;
        int sdlViewIndex = 0;
        for (int i = 0; i < mParentView.getChildCount(); i++) {
            View childView = mParentView.getChildAt(i);
            if (childView.getClass().getName().equals(SDL_VIEW_CLASS_NAME)) {
                mSdlView = childView;
                sdlViewIndex = i;
            }
        }

        if (mSdlView == null) {
            throw new RuntimeException("StageWebViewController: couldn't find SDLSurface in the app's Android view hierarchy");
        }

        // Create WebView
        StageWebView webView = new StageWebView(Extension.mainActivity);

        webView.setFocusLossListener(new StageWebView.StageWebViewFocusLossListener() {
            @Override
            public void onFocusLoss(StageWebView.FocusLossDirection direction, StageWebView.FocusLossAxis axis)
            {
                mHaxeObject.call("handleWebViewFocusLoss", new Object[] {
                            (axis ==  StageWebView.FocusLossAxis.VERTICAL),
                            (direction ==  StageWebView.FocusLossDirection.PREVIOUS) });
                }
            });

        webView.setBackgroundColor(0xFF000000);
        webView.setVisibility(View.GONE);
        mParentView.addView(webView, sdlViewIndex + 1);

        webView.getSettings().setJavaScriptEnabled(true);
        webView.getSettings().setUserAgentString(USER_AGENT);
        webView.getSettings().setSaveFormData(false);

        WebViewClient webViewClient = new StageWebViewClient();

        webView.setWebViewClient(webViewClient);
        return webView;
    }

    public void dispose()
    {
        Extension.callbackHandler.post(new Runnable() {
            public void run()
            {
                ((ViewGroup)mWebView.getParent()).removeView(mWebView);
            }
        });
    }

    public boolean canGoBack()
    {
        return syncCallOnAndroidUiThread(new Callable<Boolean>() {
            public Boolean call()
            {
                return mWebView.canGoBack();
            }
        }, false);
    }

    public boolean canGoForward()
    {
        return syncCallOnAndroidUiThread(new Callable<Boolean>() {
            public Boolean call()
            {
                return mWebView.canGoForward();
            }
        }, false);
    }

    public void goBack()
    {
        Extension.callbackHandler.post(new Runnable() {
            public void run()
            {
                mWebView.goBack();
            }
        });
    }

    public void goForward()
    {
        Extension.callbackHandler.post(new Runnable() {
            public void run()
            {
                mWebView.goForward();
            }
        });
    }

    public void reload()
    {
        Extension.callbackHandler.post(new Runnable() {
            public void run()
            {
                mWebView.reload();
            }
        });
    }

    public void stopLoading()
    {
        Extension.callbackHandler.post(new Runnable() {
            public void run()
            {
                mWebView.stopLoading();
            }
        });
    }

    public void setVerticalScrollBarEnabled(final boolean enabled)
    {
        Extension.callbackHandler.post(new Runnable() {
            public void run()
            {
                mWebView.setVerticalScrollBarEnabled(enabled);
            }
        });
    }

    public String getTitle()
    {
        return syncCallOnAndroidUiThread(new Callable<String>() {
            public String call()
            {
                return mWebView.getTitle();
            }
        }, "");
    }

    public boolean getMediaPlaybackRequiresUserGesture()
    {
        return syncCallOnAndroidUiThread(new Callable<Boolean>() {
            public Boolean call()
            {
                return mWebView.getSettings().getMediaPlaybackRequiresUserGesture();
            }
        }, false);
    }

    public void setMediaPlaybackRequiresUserGesture(final boolean isRequired)
    {
        Extension.callbackHandler.post(new Runnable() {
            public void run()
            {
                mWebView.getSettings().setMediaPlaybackRequiresUserGesture(isRequired);
            }
        });
    }

    public void loadUrl(final String url)
    {
        Extension.callbackHandler.post(new Runnable() {
            public void run()
            {
                mWebView.loadUrl(url);
            }
        });
    }

    public void loadString(final String text, final String mimeType)
    {
        Extension.callbackHandler.post(new Runnable() {
            public void run()
            {
                mWebView.loadDataWithBaseURL(null, text, mimeType, "UTF-8", null);
            }
        });
    }

    public void setVisible(final boolean isVisible)
    {
        Extension.callbackHandler.post(new Runnable() {
            public void run()
            {
                mWebView.setVisibility(isVisible ? View.VISIBLE : View.GONE);
            }
        });
    }

    public void setViewPort(final int x, final int y, final int w, final int h)
    {
        Extension.callbackHandler.post(new Runnable() {
            public void run()
            {
                mWebView.setLayoutParams(new AbsoluteLayout.LayoutParams(w, h, x, y));
                mParentView.invalidate();
            }
        });
    }

    public void setEventHandlingEnabled(final boolean isEnabled)
    {
        Extension.callbackHandler.post(new Runnable() {
            public void run()
            {
                if (isEnabled)
                {
                    mWebView.requestFocus();
                }
                else
                {
                    mSdlView.requestFocus();
                }
                mWebView.setEventHandlingEnabled(isEnabled);
            }
        });
    }
    
    public void freezeScrollFocus(final boolean shouldFreezeScrollFocus)
    {
        Extension.callbackHandler.post(new Runnable() {
            public void run()
            {
                mWebView.freezeScrollFocus(shouldFreezeScrollFocus);
            }
        });
    }

    public String getUrl()
    {
        return syncCallOnAndroidUiThread(new Callable<String>() {
            public String call()
            {
                return mWebView.getUrl();
            }
        }, "");
    }

    private <T> T syncCallOnAndroidUiThread(final Callable<T> func, final T defaultValue)
    {
        final SyncOperationParams<T> params = new SyncOperationParams<T>(defaultValue);
        Runnable task = new Runnable() {
            @Override
            public void run()
            {
                synchronized(this)
                {
                    try
                    {
                        //retVal = func.call();
                        params.result = func.call();
                    }
                    catch (Exception e)
                    {
                        Log.e(LOG_TAG, "StageWebViewController syncCallOnAndroidUiThread(): exception while " +
                                       "performing operation on Android UI thread: " + e);
                    }
                    params.isOperationInProgress = false;
                    notify();
                }
            }
        };

        Extension.callbackHandler.post(task);

        synchronized(task)
        {
            while (params.isOperationInProgress)//!isTaskCompleted)
            {
                try
                {
                    task.wait();
                }
                catch (InterruptedException e)
                {
                    Log.e(LOG_TAG, "StageWebViewController syncCallOnAndroidUiThread(): interrupted while waiting " +
                                   "for completion of operation on Android UI thread: " + e);
                    Thread.currentThread().interrupt();
                    return defaultValue;
                }
            }
        }

        return params.result;
    }
}
