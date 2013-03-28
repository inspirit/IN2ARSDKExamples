package  
{
    import aerys.minko.render.Effect;
    import aerys.minko.render.geometry.Geometry;
    import aerys.minko.render.geometry.stream.format.VertexFormat;
    import aerys.minko.render.geometry.stream.IndexStream;
    import aerys.minko.render.geometry.stream.IVertexStream;
    import aerys.minko.render.geometry.stream.StreamUsage;
    import aerys.minko.render.geometry.stream.VertexStream;
    import aerys.minko.render.material.basic.BasicMaterial;
    import aerys.minko.render.material.Material;
    import aerys.minko.render.resource.texture.TextureResource;
    import aerys.minko.scene.node.Mesh;
    import aerys.minko.type.loader.TextureLoader;
    import aerys.minko.type.math.Vector4;
    import com.in2ar.minko.MinkoCaptureTexture;
    import com.in2ar.minko.MinkoLightMapShader;
    import flash.display.BitmapData;
    import flash.geom.Vector3D;
    import flash.utils.ByteArray;
    
    /**
     * ...
     * @author Eugene Zatepyakin
     */
    public final class IN2ARLogoModel extends Mesh 
    {
        [Embed(source="../assets/in2ar_logo/paint_noise.png")] private static var Charmap:Class;
        [Embed(source = "../assets/in2ar_logo/logo_bouquet.obj", mimeType = "application/octet-stream")] private static var Charmesh:Class;
        
        protected var _lightTexture:MinkoCaptureTexture;
        protected var _texture:TextureResource;
        protected var _model:Mesh;
        protected var _defMat:Material;
        protected var _lightMapMat:Material;
        
        public function IN2ARLogoModel() 
        {
            var geometry:Geometry = createGeometry();
            _texture = TextureLoader.loadClass(Charmap);
            
            geometry.computeNormals();
            
            _defMat = new BasicMaterial( { diffuseMap:_texture } );
            
            super(geometry, _defMat);
            
            transform.prependScale( -1, 1, 1 );
            transform.prependRotation( 90 * (Math.PI / 180), Vector4.X_AXIS );
            transform.prependRotation( 180 * (Math.PI / 180), Vector4.Y_AXIS );
        }
        
        public function setupLightMap(bmp:BitmapData):void
        {
            _lightTexture = new MinkoCaptureTexture(bmp.width);
            _lightTexture.setContentFromBitmapData(bmp, false);
            
            var properties:Object = {diffuseMap:_texture, lightMap:_lightTexture};
            var effect:Effect = new Effect([new MinkoLightMapShader]);
            _lightMapMat = new Material(effect, properties);
            
            super.material = _lightMapMat;
        }
        public function updateLightMap():void
        {
            _lightTexture.update = true;
        }
        
        public var surfNormal:Vector3D = new Vector3D();
        protected var _surfNormal4:Vector4 = new Vector4();
        public function getSurfaceNormal():Vector3D
        {
            //var dt:Vector.<Number> = this.transform.matrix3D.rawData;

            //surfNormal.x = dt[2];
            //surfNormal.y = dt[6];
            //surfNormal.z = dt[10];
            
            _surfNormal4.x = 0;
            _surfNormal4.y = 0;
            _surfNormal4.z = -1;
            _surfNormal4 = this.transform.deltaTransformVector(_surfNormal4);

            _surfNormal4.normalize();
            
            surfNormal.x = _surfNormal4.x;
            surfNormal.y = _surfNormal4.y;
            surfNormal.z = _surfNormal4.z;

            return surfNormal;
        }
        
        protected function createGeometry():Geometry
        {
            var parser:OBJParser = new OBJParser(12);
            var obj_ba:ByteArray = ByteArray(new Charmesh);
            var str:String = obj_ba.toString();
            parser.parse(str);
            obj_ba.clear();
            
            // construct format
            var verts:Vector.<Number> = parser.vertices;
            var uvs:Vector.<Number> = parser.uvs;
            var numV:int = verts.length / 3;
            var xyz_uv:Vector.<Number> = new Vector.<Number>();
            
            var j:int = 0;
            for (var i:int = 0; i < numV; ++i)
            {
                xyz_uv.push(verts[j], verts[(j + 1) | 0], verts[(j + 2) | 0], uvs[i << 1], uvs[((i << 1) + 1) | 0]);
                j += 3;
            }
            
            return new Geometry(
                new <IVertexStream>[VertexStream.fromVector(StreamUsage.READ, VertexFormat.XYZ_UV, xyz_uv)],
                IndexStream.fromVector(StreamUsage.READ, parser.indices)
            );
        }
        
    }

}