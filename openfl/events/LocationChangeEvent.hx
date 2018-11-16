package openfl.events;


class LocationChangeEvent extends Event {

	/**
	 * Signals that the location property of the StageWebView object has
	 * changed. The event cannot be canceled. Dispatched after every location
	 * change.
	 */
	public static inline var LOCATION_CHANGE = "locationChange";

	/**
	 * Signals that the location property of the StageWebView object is about to
	 * change.
	 * A locationChanging event is only dispatched when the location change is
	 * initiated through HTML content or code running inside the StageWebView
	 * object, such as when a user clicks a link.
	 * A locationChanging event is not dispatched when you change the location
	 * with the following methods:
	 * - historyBack()
	 * - historyForward()
	 * - loadString()
	 * - loadURL()
	 * - reload()
	 */
	public static inline var LOCATION_CHANGING = "locationChanging";

	/**
	 * The destination URL of the change.
	 */
	public var location : String;

	/**
	 * Creates a LocationChangeEvent object.
	 */
	public function new (type : String,
	 					 bubbles : Bool = false,
						 cancelable : Bool = false,
						 location : String = null) {

		super (type, bubbles, cancelable);
		this.location = location;
	}

	public override function clone() : Event {
		var event = new LocationChangeEvent (type,
											 bubbles,
											 cancelable,
											 location);
		event.target = target;
		event.currentTarget = currentTarget;
		event.eventPhase = eventPhase;
		return event;
	}

	public override function toString() : String {
		return __formatToString ("LocationChangeEvent",
								 [ "type",
								   "bubbles",
								   "cancelable",
								   "location" ]);
	}
}
