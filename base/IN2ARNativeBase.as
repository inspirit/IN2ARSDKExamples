package  
{
    import com.in2ar.ane.IN2ARNative;
    import com.in2ar.IIN2AR;
    import flash.display.Sprite;
    import flash.events.Event;
    
    /**
     * Base class for IN2AR Native Extension version
     * @author Eugene Zatepyakin
     */
    public class IN2ARNativeBase extends Sprite 
    {
        private var _in2arLib:IIN2AR;
        
        public function IN2ARNativeBase() 
        {
            _in2arLib = new IN2ARNative();
            dispatchEvent(new Event(Event.INIT));
        }
        
        public function get in2arLib():IIN2AR
        {
            return _in2arLib;
        }

        public function disposeIN2AR():void
        {
            _in2arLib.destroy();
            _in2arLib = null;
        }
        
    }

}