// Copyright 2017 TiVo Inc. All Rights Reserved.

package openfl.tivo.saml;

import android.text.format.Time;
import android.util.Base64;
import android.util.Log;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.JavascriptInterface;
import android.util.Log;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.util.Random;
import java.util.zip.Deflater;

import org.haxe.extension.Extension;
import openfl.media.StageWebView;
import openfl.media.StageWebViewController;
import org.haxe.lime.HaxeObject;

/**
 * A controller class that creates a webview which has support to
 * receive javascript callbacks. This class also provides method
 * to create saml data and post it to the authentication url.
 */
public class SamlStageWebViewController extends StageWebViewController
{
    final private class SamlStageWebViewClient extends StageWebViewController.StageWebViewClient
    {
        final private static String sJsHandler = "javascript:" +
                                                  "var isSamlResponseFound = false;" +
                                                  "var formsHtml = \"\";" +
                                                  "for (var i = 0; i < document.forms.length; i++)" +
                                                  "{" +
                                                  "    if ((typeof document.forms[i] !== 'undefined') &&" +
                                                  "        (document.forms[i] !== null))" +
                                                  "    {" +
                                                  "        formsHtml += \"\n\n\" + document.forms[i].innerHTML;" +
                                                  "        if (('SAMLResponse' in document.forms[i]) &&" +
                                                  "            (typeof document.forms[i].SAMLResponse !== 'undefined') &&" +
                                                  "            (document.forms[i].SAMLResponse !== null))" +
                                                  "        {" +
                                                  "            window.HTMLOUT.processHTML(document.forms[i].SAMLResponse.value);" +
                                                  "            isSamlResponseFound = true;" +
                                                  "            break;" +
                                                  "        }" +
                                                  "    }" +
                                                  "}" +
                                                  "if (!isSamlResponseFound)" +
                                                  "{" +
                                                  "    window.HTMLOUT.handleSamlResponseNotFound(\"Not found SAMLResponse in the HTML document forms:\n\n\" + formsHtml);" +
                                                  "}";

        public SamlStageWebViewClient()
        {
            super();
        }

        @Override
        public void onPageFinished(WebView view, String url)
        {
            super.onPageFinished(view, url);
            Log.v(LOG_TAG, "invoking JS handler, *iff* SAML token is present");
            mWebView.loadUrl(sJsHandler);
        }
    }

    private static final String LOG_TAG = "SamlStageWebViewController";
    private static final String JAVASCRIPT_NAME = "HTMLOUT";
    //TODO: STB-32734 Set the right format for streamers
    private static final String POST_SAML_FORMAT = "SAMLRequest=%s&RelayState=mobile";
    private HaxeObject mHaxeObject;

    public SamlStageWebViewController(HaxeObject object)
    {
        super(object);
        mHaxeObject = object;
    }

    /**
     * Creates a webview and adds specific properties and listners to it.
     * @return The created webview
     */
    public StageWebView setupWebView()
    {
        StageWebView webView = super.setupWebView();

        WebViewClient webViewClient = new SamlStageWebViewClient();
        webView.setWebViewClient(webViewClient);
        webView.getSettings().setJavaScriptEnabled(true);
        webView.addJavascriptInterface(new JavaScriptHandler(mHaxeObject), JAVASCRIPT_NAME);
        webView.getSettings().setSupportZoom(true);
        webView.getSettings().setBuiltInZoomControls(true);
        webView.getSettings().setUseWideViewPort(false);
        webView.getSettings().setLoadWithOverviewMode(false);
        return webView;
    }

    /**
     * This method creates saml data and posts the data in the webview
     * to the authentication url provided .
     * @param authenticationUrl The url to post in the webview to perform saml authentication
     * @param issuer The issuer of the saml request
     * @param postDataFormat Specific post data for the request
     * @param shouldDeflateSamlRequest If request is required to be deflated before posting
     */
    public void createAndPostSamlData(final String authenticationUrl, String issuer,
                                      String postDataFormat, boolean shouldDeflateSamlRequest)
    {
        // create an ID
        final String ID = "_" + String.valueOf(new Random().nextLong());

        // TODO: STB-32734 Use gregorian calendar to get time instead of deprecated Time class.
        final Time now = new Time("UTC");
        now.set(System.currentTimeMillis());
        final String date = now.format3339(false);

        Log.v(LOG_TAG, "postDataFormat: " + postDataFormat);
        Log.v(LOG_TAG, "ID: " + ID);
        Log.v(LOG_TAG, "date: " + date);
        Log.v(LOG_TAG, "issuer: " + issuer);

        final String fullPostData = String.format(postDataFormat, ID, date, issuer);

        Log.v(LOG_TAG, "fullPostData: " + fullPostData);

        String encodedURL = "";
        String base64 = "";
        byte[] postDataBytes;
        try {
            postDataBytes = fullPostData.getBytes("UTF-8");
            if (shouldDeflateSamlRequest) {
                postDataBytes = deflateSAMLRequest(postDataBytes);
            }

            // NO_WRAP ensures better compatibility with other Base64 decoders
            base64 = Base64.encodeToString(postDataBytes, Base64.NO_WRAP);
            encodedURL = URLEncoder.encode(base64, "UTF-8");
            final String samlRequest = String.format(POST_SAML_FORMAT, encodedURL);
            Extension.callbackHandler.post(new Runnable() {
                public void run()
                {
                    Log.v(LOG_TAG, "executing postUrl with ...");
                    Log.v(LOG_TAG, "authenticationUrl: " + authenticationUrl);
                    Log.v(LOG_TAG, "samlRequest: " + samlRequest);
                    mWebView.postUrl(authenticationUrl, samlRequest.getBytes());
                }
            });

        } catch (UnsupportedEncodingException e) {
            Log.e(LOG_TAG, "createAndPostSamlData: UnsupportedEncodingException" + e.toString());
        } catch (IOException e) {
            Log.e(LOG_TAG, "createAndPostSamlData: IOException" + e.toString());
        }
    }

    private byte[] deflateSAMLRequest(byte[] postDataBytes) throws IOException {
        Deflater deflater = new Deflater(Deflater.DEFAULT_COMPRESSION, true);
        deflater.setInput(postDataBytes);
        deflater.finish();

        byte[] tmp = new byte[8192];
        int count;

        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        while (!deflater.finished()) {
            count = deflater.deflate(tmp);
            bos.write(tmp, 0, count);
        }
        bos.close();
        deflater.end();

        return bos.toByteArray();
    }

    /**
     * Javascript interface class which is added to the webview to receive callbacks
     * from javascript. In this case javascript will call JAVASCRIPT_NAME.processHTML(String)
     */
     public class JavaScriptHandler
     {
        private final HaxeObject myHaxeObject;
        private boolean mForwardToHaxeObject;

        public JavaScriptHandler(HaxeObject object)
        {
            myHaxeObject = object;
            mForwardToHaxeObject = true;
        }

        @JavascriptInterface
        public void processHTML(String htmlResponse)
        {
            if (!mForwardToHaxeObject)
            {
              Log.v(LOG_TAG, "processHTML: *NOT* forwarding to HaxeObject: htmlResponse: " + htmlResponse);
              return;
            }
            mForwardToHaxeObject = false;
            Log.v(LOG_TAG, "processHTML: *forwarding* to HaxeObject: htmlResponse: " + htmlResponse);
            myHaxeObject.call("handleSamlStageWebViewEvent", new Object[] { htmlResponse });
        }

        @JavascriptInterface
        public void handleSamlResponseNotFound(String errorString)
        {
            Log.i(LOG_TAG, "handleSamlResponseNotFound: " + errorString);
        }
     }
}
