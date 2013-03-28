package com.in2ar.flare3d 
{
    import flare.basic.Scene3D;
    import flare.core.Mesh3D;
    import flare.core.Surface3D;
    import flare.materials.filters.TextureFilter;
    import flare.materials.flsl.FLSLCompiler;
    import flare.materials.flsl.FLSLFilter;
    import flare.materials.Shader3D;
    import flare.system.Device3D;
    import flash.display.BitmapData;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.ByteArray;
    
    /**
     * @author Eugene Zatepyakin
     */
    public final class Flare3DCaptureMesh extends Mesh3D 
    {
        public static const FILL_MODE_STRETCH:uint = 0;
        public static const FILL_MODE_PRESERVE_ASPECT_RATIO:uint = 1;
        public static const FILL_MODE_PRESERVE_ASPECT_RATIO_AND_FILL:uint = 2;
        public static const FILL_MODE_NO_STRETCH:uint = 3;
        
        [Embed(source = '../../../filters/webcam.flsl', mimeType = 'application/octet-stream')]
        private static var FilterSource:Class;
        private static var webcamFilterBytes:ByteArray = FLSLCompiler.compile( new FilterSource );
        
        protected var _viewWidth:int;
        protected var _viewHeight:int;
        protected var _imageWidth:int;
        protected var _imageHeight:int;
        protected var _textureWidth:int;
        protected var _textureHeight:int;
        protected var _imageRect:Rectangle;
        
        protected var _texture:Flare3DCaptureTexture;
        protected var _textureBmp:BitmapData;
        protected var _surface:Surface3D;
        
        public function Flare3DCaptureMesh(name:String, 
                                        viewWidth:int, viewHeight:int, 
                                        streamWidth:int, streamHeight:int, 
                                        fillMode:uint = Flare3DCaptureMesh.FILL_MODE_PRESERVE_ASPECT_RATIO_AND_FILL) 
        {
            super(name);
            
            surfaces[0] = _surface = new Surface3D();
            _surface.addVertexData( Surface3D.POSITION, 3 );
            _surface.addVertexData( Surface3D.UV0, 2 );
            
            _viewWidth = viewWidth;
            _viewHeight = viewHeight;
            _imageWidth = streamWidth;
            _imageHeight = streamHeight;
            
            _textureWidth = nextPowerOfTwo(streamWidth);
            _textureHeight = nextPowerOfTwo(streamHeight);
            
            _imageRect = new Rectangle(0, 0, _imageWidth, _imageHeight);
            
            _textureCopyPoint = new Point((_textureWidth - _imageWidth) * 0.5, (_textureHeight - _imageHeight) * 0.5);
            
            _textureBmp = new BitmapData(_textureWidth, _textureHeight, true, 0xffffffff);
            _texture = new Flare3DCaptureTexture(_textureBmp);
            
            setup(viewWidth, viewHeight, _textureWidth, _textureHeight, _imageWidth, _imageHeight, fillMode);
        }
        
        protected var _buffer:BitmapData = null;
        protected var _textureCopyPoint:Point;
        public function setupForBitmapData(bmp:BitmapData):void
        {
            _buffer = bmp;
        }
        
        protected function setup(viewWidth:int, viewHeight:int,
                                                textureWidth:int, textureHeight:int,
                                                imageWidth:int, imageHeight:int,
                                                fillMode:uint = Flare3DCaptureMesh.FILL_MODE_PRESERVE_ASPECT_RATIO_AND_FILL):void
        {
            
            var u:Number, v:Number;
            var renderToTextureRect:Rectangle = new Rectangle();
            
            if (textureWidth > imageWidth) {
                renderToTextureRect.x = uint((textureWidth-imageWidth)*.5);
                renderToTextureRect.width = imageWidth;
            }
            else {
                renderToTextureRect.x = 0;
                renderToTextureRect.width = textureWidth;
            }

            if (textureHeight > imageHeight) {
                renderToTextureRect.y = uint((textureHeight-imageHeight)*.5);
                renderToTextureRect.height = imageHeight;
            }
            else {
                renderToTextureRect.y = 0;
                renderToTextureRect.height = textureHeight;
            }

            if (imageWidth > textureWidth) {
                u = 0;
            }
            else {
                u = renderToTextureRect.x / textureWidth;
            }
            if (imageHeight > textureHeight) {
                v = 0;
            }
            else {
                v = renderToTextureRect.y / textureHeight;
            }
            
            var widthScaling:Number, heightScaling:Number;
            var insetSize:Point = scaleWithAspect(imageWidth, imageHeight, viewWidth, viewHeight, true);
            
            switch(fillMode)
            {
                case 0://FillModeStretch:
                    widthScaling = 1.0;
                    heightScaling = 1.0;
                    break;
                case 1://FillModePreserveAspectRatio:
                    widthScaling = insetSize.x / viewWidth;
                    heightScaling = insetSize.y / viewHeight;
                    break;
                default:
                case 2://FillModePreserveAspectRatioAndFill:
                    widthScaling = viewHeight / insetSize.y;
                    heightScaling = viewWidth / insetSize.x;
                    break;
                case 3://FILL_MODE_NO_STRETCH
                    widthScaling = imageWidth / viewWidth;
                    heightScaling = imageHeight / viewHeight;
                    break;
            }
            _uv.x = u; _uv.y = v;
            _surface.vertexVector.push( -widthScaling, -heightScaling,0,  u,    1-v,
                                             widthScaling, -heightScaling,0,  1-u,  1-v,
                                            -widthScaling, heightScaling,0,   u,    v,
                                             widthScaling, heightScaling,0,   1-u,  v );
                                             
            _surface.indexVector.push( 0, 1, 2, 
                                            1, 3, 2 );
                                            
            //
            
            var shader:Shader3D = new Shader3D("WebCamShader", null, false);
            var filter:FLSLFilter = new FLSLFilter( webcamFilterBytes, "normal", "main" );
            
            filter.textures.mainTexture.value = _texture;
            
            shader.filters.push( filter );
            shader.build();
            
            _surface.material = shader;
            _surface.material.depthWrite = false;
            _surface.material.depthCompare = "always";
            _surface.material.twoSided = true;
        }
        
        protected var _mirror:Boolean = false;
        protected var _uv:Point = new Point();
        public function get mirror():Boolean
        {
            return _mirror;
        }
        public function set mirror(flag:Boolean):void
        {
            _mirror = flag;
            if (_mirror) {
                _surface.vertexVector[3] = 1 - _uv.x;
                _surface.vertexVector[8] = _uv.x;
                _surface.vertexVector[13] = 1 - _uv.x;
                _surface.vertexVector[18] = _uv.x;
            } else {
                _surface.vertexVector[3] = _uv.x;
                _surface.vertexVector[8] = 1 - _uv.x;
                _surface.vertexVector[13] = _uv.x;
                _surface.vertexVector[18] = 1 - _uv.x;
            }
            _surface.upload(this.scene);
        }
        
        protected function scaleWithAspect(w:Number, h:Number, x:Number, y:Number, fill:Boolean = true):Point
        {
            var nw:int = y * w / h;
            var nh:int = x * h / w;
            if (int(fill) ^ int(nw >= x)) return new Point(nw || 1, y);
            return new Point(x, nh || 1);
        }
        
        public function invalidate(scene:Scene3D=null):void
        {
            if (_buffer)
            {
                _texture.bitmapData.copyPixels(_buffer, _imageRect, _textureCopyPoint);
            }
            _texture.upload(scene);
        }
        
        public function get textureWidth():Number
        {
            return _textureWidth;
        }
        public function get textureHeight():Number
        {
            return _textureHeight;
        }
        
        override public function dispose():void
        {
            _texture.dispose();
            super.dispose();
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