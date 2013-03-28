package
{
import away3d.entities.Mesh;
import away3d.events.AssetEvent;
import away3d.library.assets.AssetType;
import away3d.loaders.Loader3D;
import away3d.loaders.misc.AssetLoaderContext;
import away3d.loaders.parsers.OBJParser;
import away3d.materials.TextureMaterial;
import away3d.textures.BitmapTexture;
import com.in2ar.away3d.Away3DContainer;
import flash.geom.Vector3D;
import flash.utils.ByteArray;



public class IN2ARLogoModel extends Away3DContainer
{
    [Embed(source = "../assets/in2ar_logo/paint_noise.png")] 
    private static var Charmap:Class;
    
    [Embed(source = "../assets/in2ar_logo/logo_bouquet.obj", mimeType = "application/octet-stream")] 
    private static var Charmesh:Class;

    private var _mesh:Mesh;
    private var _texture:BitmapTexture;
    private var _material:TextureMaterial;

    public function IN2ARLogoModel(maxDropFrames:int = 2)
    {
        super(maxDropFrames);

        initObjects();
    }

    private function initObjects():void
    {
        _texture = new BitmapTexture(new Charmap().bitmapData);
        _material = new TextureMaterial(_texture);

        var objParser:away3d.loaders.parsers.OBJParser = new away3d.loaders.parsers.OBJParser(12);
        var ld:Loader3D = new Loader3D();
        ld.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetRetrieved);
        ld.loadData(ByteArray(new Charmesh), new AssetLoaderContext(false), null, objParser);
        addChild(ld);
    }
    
    private function onAssetRetrieved(event : AssetEvent) : void
    {
        if (event.asset.assetType == AssetType.MESH)
        {
            _mesh = Mesh(event.asset);
            _mesh.transform.appendScale( -1, -1, 1 );
            _mesh.transform.appendRotation( -90, Vector3D.X_AXIS );
            _mesh.material = _material;
            
            dispatchEvent(event);
        }
    }
}
}
