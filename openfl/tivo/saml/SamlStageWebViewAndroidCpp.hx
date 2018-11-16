// Copyright 2017 TiVo Inc. All Rights Reserved.

package openfl.tivo.saml;

import lime.system.JNI;

import openfl.media.StageWebView;

class SamlStageWebViewAndroidCpp extends SamlStageWebViewBase
{
    private var mJavaSamlWebViewController : Dynamic;

    public function new()
    {
        super();
    }

    override public function createJavaWebViewController() : Dynamic
    {
        mJavaSamlWebViewController = gWebViewCtrlConstructor(this);
        return mJavaSamlWebViewController;
    }

    override public function dispose() : Void
    {
        super.dispose();
        mJavaSamlWebViewController = null;
    }

    override public function createAndPostSamlData(authenticationUrl : String, issuer : String,
                                                   consumerServiceUrl : String, shouldDeflateSamlRequest : Bool) : Void
    {
        #if TIVOCONFIG_UNSAFE_PRIVACY
        trace('calling WebViewController\'s postSamlData with authUrl=${authenticationUrl}, issuer=${issuer}, consumerServiceUrl=${consumerServiceUrl}, shouldDeflateSamlRequest=${shouldDeflateSamlRequest}...');
        #end
        gWebViewCtrlpostSamlData(mJavaSamlWebViewController, authenticationUrl, issuer, postDataFormat, shouldDeflateSamlRequest);
        #if TIVOCONFIG_UNSAFE_PRIVACY
        trace('returned from WebViewController\'s postSamlData');
        #end
    }

    @:keep
    public function handleSamlStageWebViewEvent(htmlResponse : String) : Void
    {
        #if TIVOCONFIG_UNSAFE_PRIVACY
        trace('calling dispatchWebViewEvent for SAML_TOKEN event with ${htmlResponse}');
        #end
        dispatchWebViewEvent(new SamlStageWebViewEvent(SamlStageWebViewEvent.SAML_TOKEN, false, false, htmlResponse));
        #if TIVOCONFIG_UNSAFE_PRIVACY
        trace('returned from dispatchWebViewEvent for SAML_TOKEN event');
        #end
    }

    private static function loadStaticMethod(name : String, signature : String) : Dynamic
    {
        return lime.system.JNI.createStaticMethod("openfl.tivo.saml.SamlStageWebViewController", name, signature);
    }

    private static function loadMemberMethod(name : String, signature : String) : Dynamic
    {
        return lime.system.JNI.createMemberMethod("openfl.tivo.saml.SamlStageWebViewController", name, signature);
    }

    private static var gWebViewCtrlConstructor = loadStaticMethod("<init>", "(Lorg/haxe/lime/HaxeObject;)V");
    private static var gWebViewCtrlDispose = loadMemberMethod("dispose", "()V");
    private static var gWebViewCtrlpostSamlData = loadMemberMethod("createAndPostSamlData", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Z)V");
}
