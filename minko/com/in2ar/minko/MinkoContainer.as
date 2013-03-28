package com.in2ar.minko 
{
    import aerys.minko.ns.minko_math;
    import aerys.minko.scene.node.Group;
    import aerys.minko.scene.node.ISceneNode;
    import aerys.minko.scene.node.Mesh;
    import aerys.minko.type.math.Matrix4x4;
    import com.in2ar.detect.IN2ARReference;
    
    use namespace minko_math;
    
    /**
     * @author Eugene Zatepyakin
     */
    public final class MinkoContainer extends Group
    {
        protected var maxDropFrames:int = 2;
        protected var droppedFrames:int = 0;
        
        protected var transformRAW:Vector.<Number>;
        protected var arTransform:Matrix4x4;
        protected var detected:Boolean = false;
        
        public function MinkoContainer(maxDropFrames:int = 2) 
        {
            this.maxDropFrames = maxDropFrames;
            droppedFrames = 0;
            
            transformRAW = new Vector.<Number>(16, true);
            arTransform = new Matrix4x4();
        }
        
        public function lost():void
        {
            if(detected) {
                droppedFrames++;
                if (droppedFrames >= maxDropFrames) {
                    detected = false;
                    toggleVisibility(this, false);
                }
            }
        }
        
        public function in2arTransform(ref:IN2ARReference, smooth:Number = 1.0, mirror:Boolean = false):void
        {
            get3DMatrixLH(transformRAW, ref.rotationMatrix, ref.translationVector, mirror);
            
            super.transform.lock();
            if (smooth != 1.0) {
                arTransform._matrix.copyRawDataFrom(transformRAW);
                super.transform.setTranslation(transformRAW[12],transformRAW[13],transformRAW[14]);
                super.transform.interpolateTo(arTransform, smooth, false);
            } else {
                super.transform.setRawData(transformRAW);
            }
            
            super.transform.unlock();
            
            droppedFrames = 0;
            
            if (!detected) {
                detected = true;
                toggleVisibility(this, true);
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
        
        public function toggleVisibility(node:ISceneNode, value:Boolean):void
        {
            var meshes:Vector.<ISceneNode> = node is Group ? Group(node).getDescendantsByType(Mesh) : new <ISceneNode>[node];
            for each (var mesh:ISceneNode in meshes)
            {   
                Mesh(mesh).visible = value;
            }
        }
        
    }
}