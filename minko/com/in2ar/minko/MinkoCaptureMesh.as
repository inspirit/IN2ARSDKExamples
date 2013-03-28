package com.in2ar.minko 
{
    import aerys.minko.render.Effect;
    import aerys.minko.render.geometry.Geometry;
    import aerys.minko.render.material.Material;
    import aerys.minko.scene.node.Mesh;
    import aerys.minko.type.enum.FrustumCulling;
    import flash.display.BitmapData;
import flash.geom.Matrix;
import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.ByteArray;
    
    /**
     * ...
     * @author Eugene Zatepyakin
     */
    public final class MinkoCaptureMesh extends Mesh 
    {
        private var _viewWidth:int;
        private var _viewHeight:int;
        private var _imageWidth:int;
        private var _imageHeight:int;
        private var _textureWidth:int;
        private var _textureHeight:int;
        private var _matrix:Matrix;
        private var _imageRect:Rectangle;

        private var _texture:MinkoCaptureTexture;
        private var _textureBmp:BitmapData;

        private var _mirror:Boolean = false;
        
        public function MinkoCaptureMesh(
                                        viewWidth:int, viewHeight:int, 
                                        streamWidth:int, streamHeight:int, 
                                        fillMode:uint = MinkoCaptureGeometry.FILL_MODE_PRESERVE_ASPECT_RATIO_AND_FILL,
                                        maxTextureSize:uint = 0)
        {           
            _viewWidth = viewWidth;
            _viewHeight = viewHeight;
            _imageWidth = streamWidth;
            _imageHeight = streamHeight;
            
            _textureWidth = nextPowerOfTwo(streamWidth);
            _textureHeight = nextPowerOfTwo(streamHeight);
            _matrix = new Matrix();
            _imageRect = new Rectangle(0,0,_imageWidth,_imageHeight);
            
            if (0 < maxTextureSize)
            {
                maxTextureSize = nextPowerOfTwo(maxTextureSize);
                _textureWidth = Math.min(maxTextureSize, _textureWidth);
                _textureHeight = Math.min(maxTextureSize, _textureHeight);

                var sc:Number = Math.min(_textureWidth/_imageWidth, _textureHeight/_imageHeight);
                if(sc < 1.0) {
                    _matrix.a = _matrix.d = sc;
                    _matrix.tx = (_textureWidth - _imageWidth*sc) * 0.5;
                    _matrix.ty = (_textureHeight - _imageHeight*sc) * 0.5;
                }
            }
            
            _textureCopyPoint = new Point((_textureWidth - _imageWidth) * 0.5, (_textureHeight - _imageHeight) * 0.5);
            
            var geometry:Geometry = new MinkoCaptureGeometry(viewWidth, viewHeight, _textureWidth, _textureHeight, _imageWidth, _imageHeight, fillMode);
            
            _texture = new MinkoCaptureTexture(_textureWidth, _textureHeight);
            
            var properties:Object = {diffuseMap:_texture};
            var effect:Effect = new Effect([new MinkoCaptureShader]);
            var mat:Material = new Material(effect, properties);
            
            super(geometry, mat);
            
            frustumCulling = FrustumCulling.DISABLED;
        }
        
        protected var _buffer:BitmapData = null;
        protected var _textureCopyPoint:Point;
        public function setupForBitmapData(bmp:BitmapData):void
        {
            _buffer = bmp;
            _textureBmp = new BitmapData(_textureWidth, _textureHeight, true, 0x0);
            _texture.setContentFromBitmapData(_textureBmp, false);
        }
        public function setupForByteArray(ba:ByteArray):void
        {
            _texture.setContentFromBytes(ba);
        }
        
        public function invalidate():void
        {
            if (_buffer)
            {
                if(_matrix.a < 1.0) {
                    _textureBmp.draw(_buffer, _matrix);
                } else {
                    _textureBmp.copyPixels(_buffer, _imageRect, _textureCopyPoint);
                }
            }
            _texture.update = true;
        }
        
        public function get mirror():Boolean
        {
            return _mirror;
        }
        public function set mirror(flag:Boolean):void
        {
            _mirror = flag;
            (geometry as MinkoCaptureGeometry).mirror = flag;
        }
        
        public function get textureWidth():Number
        {
            return _textureWidth;
        }
        public function get textureHeight():Number
        {
            return _textureHeight;
        }
        
        public function dispose():void
        {
            geometry.dispose();
            _texture.dispose();
            if (_buffer) _buffer.dispose();
        }
        
        public static function nextPowerOfTwo(v:uint):uint
        {
            v--;
            v |= v >> 1;
            v |= v >> 2;
            v |= v >> 4;
            v |= v >> 8;
            v |= v >> 16;
            v++;
            return v;
        }
        
    }

}