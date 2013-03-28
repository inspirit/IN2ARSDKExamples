package com.in2ar.minko 
{
    import aerys.minko.render.geometry.stream.format.VertexComponent;
    import aerys.minko.render.shader.SFloat;
    import aerys.minko.render.shader.Shader;
    import aerys.minko.type.enum.SamplerFiltering;
    import aerys.minko.type.enum.SamplerMipMapping;
    import aerys.minko.type.enum.SamplerWrapping;
    
    /**
     * ...
     * @author Eugene Zatepyakin
     */
    public final class MinkoLightMapShader extends Shader 
    {        
        override protected function getVertexPosition():SFloat
        {
            return localToScreen(vertexXYZ);
        }
        
        override protected function getPixelColor():SFloat
        {
            var diffuseMap:SFloat = meshBindings.getTextureParameter(
                    'diffuseMap',
                    meshBindings.getConstant('diffuseFiltering', SamplerFiltering.LINEAR),
                    meshBindings.getConstant('diffuseMipMapping', SamplerMipMapping.LINEAR),
                    meshBindings.getConstant('diffuseWrapping', SamplerWrapping.REPEAT)
                );
            var lightMap:SFloat = meshBindings.getTextureParameter(
                    'lightMap',
                    SamplerFiltering.LINEAR,
                    SamplerMipMapping.DISABLE,
                    SamplerWrapping.CLAMP
                );
                
            var diffuseColor:SFloat = sampleTexture(diffuseMap, interpolate(vertexUV.xy));
            
            var surfaceNormal:SFloat = getVertexAttribute(VertexComponent.NORMAL);
            var vertexPos:SFloat = getVertexAttribute(VertexComponent.XYZ);
            
            var normal:SFloat = normalize(
                    interpolate(
                        float4(multiply3x3(surfaceNormal, localToWorldMatrix), 1)
                    )
                );
            var pos:SFloat = normalize(
                    interpolate(
                        float4(multiply3x3(vertexPos, localToWorldMatrix), 1)
                    )
                );
            
            //var refl0:SFloat = reflect( pos, normal );
            // different from built in
            var refl0:SFloat = subtract(multiply(2, dotProduct3(normal, pos), normal), pos);
            var refl1:SFloat = add( refl0, float3(0, 0, 1) );
            var sqt:SFloat = multiply(0.5, rsqrt( dotProduct3(refl1, refl1) ));
            var uv:SFloat = add( 0.5, multiply(refl0, sqt) );
            
            var lightColor:SFloat = sampleTexture(lightMap, uv.xy);
            //var bias:SFloat = meshBindings.getParameter('cameraBias', 3);
            //var mix:SFloat = add( bias, multiply(diffuseColor.rgb, lightColor.rgb) );
            var mix:SFloat = multiply(diffuseColor.rgb, lightColor.rgb);
            
            return float4(mix, diffuseColor.a);
        }
        
    }

}