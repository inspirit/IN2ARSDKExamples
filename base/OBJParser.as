package  
{
    import flash.geom.Point;
    import flash.geom.Vector3D;
    
	/**
     * Basic implementation of OBJ file parser
     * @author Eugene Zatepyakin
     */
    
    public final class OBJParser 
    {
        public var vertices:Vector.<Number>;
		public var normals:Vector.<Number>;
		public var uvs:Vector.<Number>;
		public var indices:Vector.<uint>;
		public var materials:Vector.<String>;
		
		protected var scale:Number = 1.0;
		
		public function OBJParser(scale:Number = 1.0)
		{
			this.scale = scale;
		}
		
		public function parse(fileData:String):void
		{
			vertices = new Vector.<Number>();
			normals = new Vector.<Number>();
			uvs = new Vector.<Number>();
			indices = new Vector.<uint>();
			materials = new Vector.<String>();
			
			var tmpV:Vector.<Vector3D> = new Vector.<Vector3D>();
			var tmpVN:Vector.<Vector3D> = new Vector.<Vector3D>();
			var tmpUV:Vector.<Point> = new Vector.<Point>();
			
			var line:String;
            var creturn:String = String.fromCharCode(10);
            var trunk:Array;

            if(fileData.indexOf(creturn) == -1)
            {
				creturn = String.fromCharCode(13);
            }
            var stringLength:int = fileData.length;
            var charIndex:int = fileData.indexOf(creturn, 0);
			var oldIndex:int = 0;
			var realIndices:Array = [];
			var vertexIndex:int = 0;
			
            while(charIndex < stringLength)
            {
				charIndex = fileData.indexOf(creturn, oldIndex);
				if(charIndex == -1)
				{
					charIndex = stringLength;
				}
				line = fileData.substring(oldIndex, charIndex);
				line = line.split('\r').join("");

				trunk = line.replace("  "," ").split(" ");
				oldIndex = charIndex + 1;
				
				switch(trunk[0])
				{
					case "mtllib":
                            //_mtlLib = true;
                            //_mtlLibLoaded = false;
                            //loadMtl (trunk[1]);
                            break;
                    case "g":
                            //createGroup(trunk);
                            break;
                    case "o":
                            //createObject(trunk);
                            break;
                    case "usemtl":
                            //_materialIDs.push(trunk[1]);
                            //_activeMaterialID = trunk[1];
                            //_currentGroup.materialID= _activeMaterialID;
                            materials.push(trunk[1]);
                            break;
                    case "v":
                            //parseVertex
                            tmpV.push(new Vector3D(parseFloat(trunk[1]), 
                            						parseFloat(trunk[2]), 
                            						parseFloat(trunk[3])));
                            break;
                    case "vt":
                            //parseUV
                            tmpUV.push( new Point( parseFloat(trunk[1]), 
                            						1-parseFloat(trunk[2]) ) );
                            break;
                    case "vn":
                            //parseVertexNormal;
                            tmpVN.push(new Vector3D(parseFloat(trunk[1]), 
                            						parseFloat(trunk[2]), 
                            						parseFloat(trunk[3])));
                            break;
                    case "f":
							// parseFace;
							var len:int = trunk.length;
							var indc:Array;
							var rvind:int;
                            for (var i:uint = 1; i < len; ++i)
                            {
                            	if (trunk[i] == "") continue;
                            	indc = trunk[i].split("/");
                            	if (!realIndices[ trunk[i] ])
                            	{
                            		rvind = vertexIndex;
                            		realIndices[ trunk[i] ] = ++vertexIndex;
                            		
									var vt:Vector3D = tmpV[parseInt( indc[0] ) - 1];
									var uvp:Point = tmpUV[parseInt( indc[1] ) - 1];									
									
									vertices.push( vt.x * scale, vt.y * scale, vt.z * scale );
									uvs.push( uvp.x, uvp.y );
                                    
                                    // check normals
                                    if (tmpVN.length) {
                                        var vtn:Vector3D = tmpVN[parseInt( indc[2] ) - 1];
									    normals.push( vtn.x, vtn.y, vtn.z );
                                    }
                            	
                            	} else {
                            		rvind = parseInt(realIndices[ trunk[i] ]) - 1;
                            	}
                            	
                            	indices.push(rvind);
                            }
				}
            }
            
            if (normals.length == 0) {
                computeNormals();
            }
		}
		
		public function computeNormals():void
		{
			var vn:uint = vertices.length;
			var n:int = vn * 3;
			var n2:int = indices.length;
			var i:int;
			var normal_buffer:Vector.<Vector3D> = new Vector.<Vector3D>(vn, true);
			for(i = 0; i < vn; ++i)
			{
				normal_buffer[i] = new Vector3D();
			}

			var normal:Vector3D;
			
			for(i = 0; i < n2; i += 3)
			{
				var a:int = indices[i];
				var b:int = indices[(i+1)|0];
				var c:int = indices[(i+2)|0];
				var a3:int = (a*3);
				var b3:int = (b*3);
				var c3:int = (c*3);
				
				var p1x:Number = vertices[a3];
				var p1y:Number = vertices[(a3+1)|0];
				var p1z:Number = vertices[(a3+2)|0];
				
				var p2x:Number = vertices[b3];				
				var p2y:Number = vertices[(b3+1)|0];
				var p2z:Number = vertices[(b3+2)]|0;
				
				var p3x:Number = vertices[c3];
				var p3y:Number = vertices[(c3+1)|0];
				var p3z:Number = vertices[(c3+2)|0];
				
				var v1x:Number = p2x - p1x;
				var v1y:Number = p2y - p1y;
				var v1z:Number = p2z - p1z;
				var v2x:Number = p3x - p1x;
				var v2y:Number = p3y - p1y;
				var v2z:Number = p3z - p1z;
				
				var nx:Number = v1y * v2z - v1z * v2y;
				var ny:Number = v1z * v2x - v1x * v2z;
				var nz:Number = v1x * v2y - v1y * v2x;
				
				normal = normal_buffer[a];
				normal.x += nx;
				normal.y += ny;
				normal.z += nz;
				//
				normal = normal_buffer[b];
				normal.x += nx;
				normal.y += ny;
				normal.z += nz;
				//
				normal = normal_buffer[c];
				normal.x += nx;
				normal.y += ny;
				normal.z += nz;
			}
			
			n = 0;
			for(i = 0; i < vn; ++i)
			{
				normal = normal_buffer[i];
				normal.normalize();
                
				normals[n++] = normal.x;
				normals[n++] = normal.y;
				normals[n++] = normal.z;
			}
		}
        
    }

}