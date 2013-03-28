package  
{
    import flash.display.BitmapData;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.geom.Rectangle;
    import flash.media.Camera;
import flash.utils.ByteArray;
import flash.utils.Endian;

/**
     * WEB/DEVICE Camera controller 
     * this one uses Flash Player 11.4 and above features
     * @author Eugene Zatepyakin
     */
    public class CaptureController extends EventDispatcher
    {
        public static const UPDATE_BITMAPDATA:uint = 2;
        public static const UPDATE_VECTORDATA:uint = 4;
        public static const UPDATE_BYTEARRAY:uint = 8;
        
        private var _cam:Camera;
        private var _width:int;
        private var _height:int;
        private var _bitmapData:BitmapData;
        private var _vectorData:Vector.<uint>;
        private var _byteArray:ByteArray;
        private var _frameRect:Rectangle;
        
        private var _options:uint = 2;
        
        public function CaptureController(camera:Camera, options:uint = 2) 
        {
            _cam = camera;
            _width = _cam.width;
            _height = _cam.height;

            if(options&2) _bitmapData = new BitmapData(_width, _height);
            if(options&4) _vectorData = new Vector.<uint>(_width * _height);
            if(options&8) {
                _byteArray = new ByteArray();
                _byteArray.endian = Endian.LITTLE_ENDIAN;
                _byteArray.length = _width*_height*4;
                _byteArray.shareable = true;
            }

            _frameRect = new Rectangle(0, 0, _width, _height);
            _options = options;
            
            _cam.addEventListener(Event.VIDEO_FRAME, camUpdateEvent);
        }
        
        private function camUpdateEvent(e:Event):void 
        {
            if(_options&2) _cam.drawToBitmapData(_bitmapData);
            if(_options&4) _cam.copyToVector(_frameRect, _vectorData);
            if(_options&8) {
                _byteArray.position = 0;
                _cam.copyToByteArray(_frameRect, _byteArray);
            }
            
            dispatchEvent(e);
        }
        
        public function updateBitmapData():void
        {
            _cam.drawToBitmapData(_bitmapData);
        }
        
        public function updateVectorData():void
        {
            _cam.copyToVector(_frameRect, _vectorData);
        }
        
        public function get bitmapData():BitmapData
        {
            return _bitmapData;
        }
        
        public function get vectorData():Vector.<uint>
        {
            return _vectorData;
        }

        public function get byteArray():ByteArray
        {
            return _byteArray;
        }
        
    }

}