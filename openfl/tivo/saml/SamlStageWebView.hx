package openfl.tivo.saml;

import openfl.media.StageWebView;

#if display
typedef SamlStageWebView = SamlStageWebViewPrototype;
#elseif android
typedef SamlStageWebView = SamlStageWebViewAndroidCpp;
#else
typedef SamlStageWebView = SamlStageWebViewStub;
#end

/**
 * The TivoSamlStageWebView class displays a SAML login web page in a stage
 * view port, providing that web page with ability to communicate to tcdui
 * code through callbacks.
 *
 * Except for those callbacks, this class is the same as the StageWebView
 * in terms of capabilities, limitations and other rules. Please refer to
 * the openfl.media.StageWebView documentation for details.
 *
 * Events dispatched:
 * - TivoSamlStageWebViewEvent.SAML_TOKEN
 */
class SamlStageWebViewPrototype extends SamlStageWebViewBase
{

}
