package com.in2ar.flare3d 
{
    import flare.core.Texture3D;
    import flash.display.BitmapData;
    
    /**
     * @author Eugene Zatepyakin
     */
    public final class Flare3DCaptureTexture extends Texture3D 
    {
        
        public function Flare3DCaptureTexture(image:BitmapData) 
        {
            super(image);
            super.mipMode = Texture3D.MIP_NONE;
            super.loaded = true;
        }
        
    }

}