package  
{
    import com.in2ar.IIN2AR;
    import com.in2ar.IN2AR;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.system.LoaderContext;

    /**
     * Base class for IN2AR pure AS3 version
     * @author Eugene Zatepyakin
     */
    public class IN2ARBase extends Sprite 
    {
        private var _in2arShell:IN2AR;
        private var _in2arLib:IIN2AR;
        
        public function IN2ARBase() 
        {
            if(stage) onAddedToStage();
            else addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        }
        
        protected function onAddedToStage(e:Event = null):void
        {
            removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
            
            _in2arShell = new IN2AR(new LoaderContext(false));
            _in2arShell.addEventListener(Event.INIT, onIN2ARInit);
        }
        
        private function onIN2ARInit(e:Event):void 
        {
            _in2arShell.removeEventListener(Event.INIT, onIN2ARInit);
            _in2arLib = _in2arShell.lib;
            
            dispatchEvent(e);
        }

        public function disposeIN2AR():void
        {
            _in2arShell.destroy();
            _in2arLib = null;
            _in2arShell = null;
        }
        
        public function get in2arLib():IIN2AR
        {
            return _in2arLib;
        }
        
        public function get in2arShell():IN2AR
        {
            return _in2arShell;
        }
        
    }

}