package com.in2ar.flare3d 
{
    import flare.core.Camera3D;
    import com.in2ar.calibration.IntrinsicParameters;
    
    /**
     * @author Eugene Zatepyakin
     */
    public final class Flare3DCamera extends Camera3D 
    {
        
        public var projectionRAW:Vector.<Number>;
        
        public function Flare3DCamera(name:String="") 
        {
            super(name);
            
            super.setPosition(0, 0, 0);
            super.lookAt(0, 0, 1);
            
            projectionRAW = new Vector.<Number>(16);
        }
        
        public function setupProjectionMatrix(intrinsic:IntrinsicParameters, 
                                                viewWidth:uint, viewHeight:uint, 
                                                in2arWidth:uint, in2arHeight:uint):void
        {
            // setup projection matrix
            var raw:Vector.<Number> = projectionRAW;
            var fx:Number = intrinsic.fx;
            var fy:Number = intrinsic.fy;
            var w:Number = viewWidth;
            var h:Number = viewHeight;
            var aspectRatio:Number = w / h;
            var scaleF:Number = Math.max(Number(viewWidth) / Number(in2arWidth), Number(viewHeight) / Number(in2arHeight));
            
            var near:Number = fx / 32;
            var far:Number = fx * 32;
            var fov:Number = 2.0 * Math.atan( (h - 1) / (2 * fy) );
            var focalLengthInv:Number = Math.tan(fov * 0.5);
            
            var yMax:Number = near*focalLengthInv;
            var xMax:Number = yMax*aspectRatio;
            
            // assume symmetric frustum
            raw[uint(0)] = near/xMax * scaleF;
            raw[uint(5)] = near/yMax * scaleF;
            raw[uint(10)] = far/(far-near);
            raw[uint(11)] = 1;
            raw[uint(14)] = -near * raw[uint(10)];
            //
            super.far = far;
            super.near = near;
            super.fieldOfView = (fov*(180/Math.PI));
            super.aspectRatio = aspectRatio;
            super.zoom = 1;
            //
            updateProjection();
        }
        
        public function updateProjection():void
        {
            super.projection.copyRawDataFrom( projectionRAW );
            super.updateTransforms();
        }
        
    }

}