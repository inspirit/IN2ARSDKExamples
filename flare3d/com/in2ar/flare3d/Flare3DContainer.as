package com.in2ar.flare3d 
{
    import flare.core.Pivot3D;
    import flash.geom.Matrix3D;
    import flash.geom.Vector3D;
    import com.in2ar.detect.IN2ARReference;
    
    /**
     * @author Eugene Zatepyakin
     */
    public final class Flare3DContainer extends Pivot3D 
    {
        public var transformRAW:Vector.<Number>;
        
        protected var arTransform:Matrix3D;
        protected var maxDropFrames:int = 2;
        protected var droppedFrames:int = 0;
        
        public function Flare3DContainer(name:String="", maxDropFrames:int = 2) 
        {
            super(name);
            
            this.maxDropFrames = maxDropFrames;
            droppedFrames = 0;
            
            transformRAW = new Vector.<Number>(16);
            arTransform = new Matrix3D(transformRAW);
            arTransform.identity();
        }
        
        public function lost():void
        {
            if(super.visible) {
                droppedFrames++;
                if (droppedFrames >= maxDropFrames) {
                    super.visible = false;
                }
            }
        }
        
        public function in2arTransform(ref:IN2ARReference, smooth:Number = 1.0, mirror:Boolean = false):void
        {
            get3DMatrixLH(transformRAW, ref.rotationMatrix, ref.translationVector, mirror);
            if (smooth != 1.0) {
                arTransform.copyRawDataFrom(transformRAW);
                super.world.position = arTransform.position;
                super.world.interpolateTo(arTransform, smooth);
            } else {
                super.world.copyRawDataFrom(transformRAW);
            }
            
            droppedFrames = 0;
            
            super.updateTransforms(true);
            if (!super.visible) {
                super.visible = true;
            }
        }
        
        protected function get3DMatrixLH(data:Vector.<Number>, R:Vector.<Number>, t:Vector.<Number>, mirror:Boolean = false):void
        {
            if (!mirror)
            {
                data[0] = R[0]; data[1] = -R[3]; data[2] = R[6]; data[3] = 0.0;
                data[4] = R[1]; data[5] = -R[4]; data[6] = R[7]; data[7] = 0.0;
                data[8] = -R[2]; data[9] = R[5]; data[10] = -R[8]; data[11] = 0.0;
                data[12] = t[0]; data[13] = -t[1]; data[14] = t[2]; data[15] = 1.0;
            } else {
                data[0] = -R[0]; data[1] = -R[3]; data[2] = R[6]; data[3] = 0.0;
                data[4] = R[1]; data[5] = R[4]; data[6] = -R[7]; data[7] = 0.0;
                data[8] = R[2]; data[9] = R[5]; data[10] = -R[8]; data[11] = 0.0;
                data[12] = -t[0]; data[13] = -t[1]; data[14] = t[2]; data[15] = 1.0;
            }
        }
        
    }

}