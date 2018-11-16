package openfl.media;

import android.content.Context;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewGroupOverlay;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.util.Log;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import org.haxe.extension.Extension;
import android.content.pm.ApplicationInfo;


public class StageWebView extends WebView
{
    public enum FocusLossDirection
    {
        PREVIOUS,
        NEXT
    }

    public enum FocusLossAxis
    {
        VERTICAL,
        HORIZONTAL
    }

    public interface StageWebViewFocusLossListener
    {
        void onFocusLoss(FocusLossDirection direction, FocusLossAxis axis);
    }

    private static final String LOG_TAG = "StageWebView";

    private StageWebViewFocusLossListener focusLossListener = null;
    private boolean isEventHandlingEnabled = true;
    private KeyEvent lastMaxExtentKeyEvent = null;
    private boolean isScrollFocusFrozen = false;
    public StageWebView(Context context)
    {
        super(context);
    }

    public void setFocusLossListener(StageWebViewFocusLossListener focusLossListener)
    {
        this.focusLossListener = focusLossListener;
    }

    public void setEventHandlingEnabled(boolean isEnabled)
    {
        isEventHandlingEnabled = isEnabled;
        lastMaxExtentKeyEvent = null;
    }

    public void freezeScrollFocus(boolean shouldFreezeScrollFocus)
    {

        isScrollFocusFrozen = shouldFreezeScrollFocus;    
    }

    private static boolean hasSystemLevelPermissions() 
    {
        PackageManager pm = Extension.mainContext.getPackageManager();
        try {
            PackageInfo info = pm.getPackageInfo
                (Extension.mainContext.getPackageName(), 0);
            if (info == null) {
                Log.e(LOG_TAG, "Cannot determine package info for package " +
                      Extension.mainContext.getPackageName());
                return false;
            }
            return ((info.applicationInfo.flags &
                     (ApplicationInfo.FLAG_SYSTEM |
                      ApplicationInfo.FLAG_UPDATED_SYSTEM_APP)) != 0);
        }
        catch (Exception e) {
            Log.e(LOG_TAG, "Failed to fetch package info: " + e);
            return false;
        }
    }

    @Override
    public boolean dispatchKeyEvent(KeyEvent event)
    {
        boolean isHandled = false;

        if (event.getAction() == KeyEvent.ACTION_UP && isEventHandlingEnabled && focusLossListener != null) {

            switch (event.getKeyCode())
            {
                case KeyEvent.KEYCODE_DPAD_DOWN:
                    if ((computeVerticalScrollOffset() + computeVerticalScrollExtent()) >=
                         computeVerticalScrollRange())
                    {
                        isHandled = true;
                        transferFocusIfRequired(event, FocusLossAxis.VERTICAL);
                    }
                    else
                    {
                        lastMaxExtentKeyEvent = null;
                    }
                    break;

                case KeyEvent.KEYCODE_DPAD_UP:
                    if (computeVerticalScrollOffset() <= 0)
                    {
                        isHandled = true;
                        transferFocusIfRequired(event, FocusLossAxis.VERTICAL);
                    }
                    else
                    {
                        lastMaxExtentKeyEvent = null;
                    }
                    break;

                case KeyEvent.KEYCODE_DPAD_LEFT:
                    Log.e(LOG_TAG, "computeHorizontalScrollOffset(): "+computeHorizontalScrollOffset()+" computeHorizontalScrollExtent(): "+computeHorizontalScrollExtent());
                    if (computeHorizontalScrollOffset() <= 0)
                    {
                        isHandled = true;
                        transferFocusIfRequired(event, FocusLossAxis.HORIZONTAL);
                    }
                    else
                    {
                        lastMaxExtentKeyEvent = null;
                    }
                    break;

                case KeyEvent.KEYCODE_DPAD_RIGHT:
                    if ((computeHorizontalScrollOffset() + computeHorizontalScrollExtent()) >=
                        computeHorizontalScrollRange())
                    {
                        isHandled = true;
                        transferFocusIfRequired(event, FocusLossAxis.HORIZONTAL);
                    }
                    else
                    {
                        lastMaxExtentKeyEvent = null;
                    }
                    break;
                case KeyEvent.KEYCODE_BACK:
                    {
                        if (hasSystemLevelPermissions())
                        {
                            isHandled = true;
                        }
                    }
                    break;
            }
        }

        if (!isHandled)
        {
            isHandled = super.dispatchKeyEvent(event);
        }

        return isHandled;
    }

    //This method checks if we have reached the end of the webview. Upon reaching the end we don't want to lose focus immediately.
    //This is required to keep the focus on the last item of the view. Upon getting a repeated keyevent at the max extent,
    //the webView will lose focus. 
    private void transferFocusIfRequired(KeyEvent keyevent, FocusLossAxis focusLossAxis)
    {
        if(isScrollFocusFrozen)
        {
            return;
        }
        if(lastMaxExtentKeyEvent == null || lastMaxExtentKeyEvent.getKeyCode() != keyevent.getKeyCode())
        {
            //Either direction has changed or max extent was never reached previously. Record this keyevent as the one that has caused 
            //the view to reach the max extent.
            lastMaxExtentKeyEvent = keyevent;
        }
        else
        {
            //Max extent is reached with the same key, the webview is now ready to lose focus. 
            lastMaxExtentKeyEvent = null;
            focusLossListener.onFocusLoss(FocusLossDirection.PREVIOUS, focusLossAxis);
        }

    }

    @Override
    public boolean onTrackballEvent(MotionEvent event)
    {
        return isEventHandlingEnabled ? super.onTrackballEvent(event) : false;
    }

    @Override
    public boolean onTouchEvent(MotionEvent event)
    {
        return isEventHandlingEnabled ? super.onTouchEvent(event) : false;
    }

    @Override
    public boolean onGenericMotionEvent(MotionEvent event)
    {
        return isEventHandlingEnabled ? super.onGenericMotionEvent(event) : false;
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event)
    {
        boolean isHandled = false;
        if (isEventHandlingEnabled)
        {
            isHandled = super.onKeyDown(keyCode, event);
        }

        return isHandled;
    }

    @Override
    public boolean onKeyUp(int keyCode, KeyEvent event)
    {
        boolean isHandled = false;
        if (isEventHandlingEnabled)
        {
            isHandled = super.onKeyUp(keyCode, event);
        }

        return isHandled;
    }

    @Override
    public boolean onKeyMultiple(int keyCode, int repeatCount, KeyEvent event)
    {
        boolean isHandled = false;
        if (isEventHandlingEnabled)
        {
            isHandled = super.onKeyMultiple(keyCode, repeatCount, event);
        }

        return isHandled;
    }

}
