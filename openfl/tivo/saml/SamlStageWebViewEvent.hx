package openfl.tivo.saml;

import openfl.events.Event;

class SamlStageWebViewEvent extends Event {
    /**
     * Signals that a web page rendered by the SamlStageWebView object
     * authenticated a user and wants to transfer generated SAML token to
     * tcdui code.
     */
    public static inline var SAML_TOKEN = "samlToken";

    /**
     * The name of callback parameter (defined by the CallbackStageWebView's
     * addCallbackParameter() function)
     */
    public var samlToken: String;

    public function new (type : String,
	 					 bubbles : Bool = false,
						 cancelable : Bool = false,
						 samlToken : String = "") {

		super (type, bubbles, cancelable);
		this.samlToken = samlToken;
	}

	public override function clone() : Event {
		var event = new SamlStageWebViewEvent(type,
    										      bubbles,
    											  cancelable,
    											  samlToken);
		event.target = target;
		event.currentTarget = currentTarget;
		event.eventPhase = eventPhase;
		return event;
	}
}
