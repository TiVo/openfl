// Copyright 2017 TiVo Inc. All Rights Reserved.

package openfl.tivo.saml;

import openfl.media.StageWebView;

class SamlStageWebViewBase extends StageWebView
{
    /**
     * this property value must be set before createAndPostSamlData function is invoked
     */
    public  var postDataFormat(get, set) : String;

    private var mPostDataFormat : String;

    public function new()
    {
        super();
    }

    public function createAndPostSamlData(authenticationUrl : String, issuer : String,
                                          consumerServiceUrl : String, shouldDeflateSamlRequest : Bool) : Void
    {

    }

    private function get_postDataFormat() : String
    {
        return mPostDataFormat;
    }

    private function set_postDataFormat(value : String) : String
    {
        mPostDataFormat = value;
        return value;
    }
}
