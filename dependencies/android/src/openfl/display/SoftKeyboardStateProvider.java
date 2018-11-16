// Copyright 2018 TiVo Inc. All Rights Reserved.

package openfl.display;

import android.app.Activity;
import android.graphics.Rect;
import android.view.View;
import android.view.ViewTreeObserver;
import android.util.Log;
import org.haxe.extension.Extension;
import org.haxe.lime.HaxeObject;

public class SoftKeyboardStateProvider extends Extension {

    private static int height = -1;
    private static boolean initiated = false;

    public static void init(HaxeObject listener) {

        Log.i(LOG_TAG, "initiating");
        gListener = listener;

        if (!initiated) {
            initiated = true;

            final View rootView = Extension.mainActivity.getWindow().getDecorView().getRootView();
            height = rootView.getHeight();

            rootView.getViewTreeObserver().addOnGlobalLayoutListener(new ViewTreeObserver.OnGlobalLayoutListener() {
                @Override
                public void onGlobalLayout() {
    
                    Rect r = new Rect();
                    rootView.getWindowVisibleDisplayFrame(r);
    
                    int newHeight = r.bottom - r.top;
    
                    Log.i(LOG_TAG, "height: " + height + ", newHeight: " + newHeight);
    
                    if (newHeight != height) {
                        boolean visibility = newHeight < height;
                        height = newHeight;
                        if (gListener != null) {
                            gListener.call("onKeyboardVisibilityChanged", new Object[]{visibility});
                        } else {
                            Log.i(LOG_TAG, "gListener is null");
                        }
                    }    
                }
            });
        }
    }

    public static int getScreenHeight() {
        return height;
    }

    public static boolean isInitiated() {
        return initiated;
    }

    private static HaxeObject gListener;

    private static final String LOG_TAG = "SoftKeyboardStateProvider";
}

