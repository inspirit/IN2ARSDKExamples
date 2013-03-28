package com.in2ar.minko 
{
    import aerys.minko.render.resource.Context3DResource;
    import aerys.minko.render.resource.texture.ITextureResource;
    import flash.display.BitmapData;
    import flash.display3D.Context3DTextureFormat;
    import flash.display3D.textures.Texture;
    import flash.display3D.textures.TextureBase;
    import flash.utils.ByteArray;
    
    /**
     * ...
     * @author Eugene Zatepyakin
     */
    public final class MinkoCaptureTexture implements ITextureResource 
    {
        private static const MAX_SIZE           : uint      = 2048;
        private static const FORMAT_BGRA        : String    = Context3DTextureFormat.BGRA;
        
        private var _texture    : Texture       = null;

        private var _bitmapData : BitmapData    = null;
        private var _bytes:ByteArray = null;

        private var _width      : Number        = 0;
        private var _height     : Number        = 0;

        private var _update     : Boolean       = false;
        private var _resize     : Boolean       = false;
        
        public function MinkoCaptureTexture(width:uint = 0, height:uint = 0) 
        {
            if (width != 0 && height != 0)
                setSize(width, height);
        }
        
        public function get width():uint 
        {
            return _width;
        }
        
        public function get height():uint 
        {
            return _height;
        }
        
        public function set update(value:Boolean):void
        {
            _update = value;
        }
        
        public function setContentFromBitmapData(bitmapData:BitmapData, mipmap:Boolean, downSample:Boolean = false):void 
        {
            _bitmapData = bitmapData;
            _width = bitmapData.width;
            _height = bitmapData.height;
            _update = true;
        }
        
        public function setContentFromATF(atf:ByteArray):void 
        {
            // not supported
        }
        
        public function setContentFromBytes(bytes:ByteArray):void
        {
            _bytes = bytes;
            _update = true;
        }
        
        public function getNativeTexture(context:Context3DResource):TextureBase 
        {
            if ((!_texture || _resize) && _width && _height)
            {
                _resize = false;
                
                if (_texture) _texture.dispose();
                
                _texture = context.createTexture(
                    _width,
                    _height,
                    FORMAT_BGRA, false
                );
                
                _update = true;
            }

            if (_update)
            {
                _update = false;
                
                if (_bytes)
                {
                    _texture.uploadFromByteArray(_bytes, 0);
                }
                else if (_bitmapData)
                {
                    _texture.uploadFromBitmapData(_bitmapData, 0);
                }
            }

            if (_texture == null)
                throw new Error();
            
            return _texture;
        }
        
        public function setSize(w:uint, h:uint):void 
        {           
            _width  = w;
            _height = h;
            _resize = true;
        }
        
        public function dispose():void 
        {
            if (_texture)
            {
                _texture.dispose();
                _texture = null;
            }
        }
        
    }

}