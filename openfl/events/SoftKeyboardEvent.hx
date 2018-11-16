package openfl.events;

class SoftKeyboardEvent extends Event 
{
    public static var SOFT_KEYBOARD_ACTIVATE : String = "softKeyboardActivate";
    public static var SOFT_KEYBOARD_ACTIVATING : String = "softKeyboardActivating";
    public static var SOFT_KEYBOARD_DEACTIVATE : String = "softKeyboardDeactivate";

    public var relatedObject : flash.display.InteractiveObject;
    public var triggerType(default,null) : String;

    public function new(type : String, bubbles : Bool, cancelable : Bool, relatedObjectVal : flash.display.InteractiveObject, triggerTypeVal : String) : Void 
    {
       super(type, bubbles, cancelable);

       relatedObject = relatedObjectVal;
       triggerType = triggerTypeVal;
    }

    public override function clone() : Event 
    {
        var event = new SoftKeyboardEvent(type, bubbles, cancelable, relatedObject, triggerType);
        event.target = target;
        event.currentTarget = currentTarget;
        event.eventPhase = eventPhase;
        return event;
    }

    public override function toString() : String 
    {
        return __formatToString("SoftKeyboardEvent",  ["type", "bubbles", "cancelable", "relatedObject", "triggerType"]);		
    }
}
