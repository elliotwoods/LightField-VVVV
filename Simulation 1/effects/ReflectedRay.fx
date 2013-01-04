//@author: vvvv group
//@help: draws a mesh with a constant color
//@tags: template, basic
//@credits:

// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//texture
texture TexWorld <string uiname="World";>;
sampler SampWorld = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (TexWorld);          //apply a texture to the sampler
    MipFilter = NONE;         //sampler states
    MinFilter = NONE;
    MagFilter = NONE;
};

//texture
texture TexNormal <string uiname="Normal";>;
sampler SampNormal = sampler_state    //sampler for doing the texture-lookup
{
    Texture  = (TexNormal);          //apply a texture to the sampler
    MipFilter = NONE;         //sampler states
    MinFilter = NONE;
    MagFilter = NONE;
};

float3 ProjectorWorld <string uiname="Projector Position";>;


//the data structure: vertexshader to pixelshader
//used as output data with the VS function
//and as input data with the PS function
struct vs2ps
{
    float4 Pos : POSITION;
    float4 TexCd : TEXCOORD0;
};

// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// --------------------------------------------------------------------------------------------------

vs2ps VS(
    float4 Pos : POSITION,
    float4 TexCd : TEXCOORD0)
{
    //inititalize all fields of output struct with 0
    vs2ps Out;

    //transform position
	Pos.xy *= 2.0f;
    Out.Pos = Pos;

    Out.TexCd = TexCd;

    return Out;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------

float4 PS(vs2ps In): COLOR
{
	float3 MirrorNormal = tex2D(SampNormal, In.TexCd).xyz;
	float3 MirrorWorld = tex2D(SampWorld, In.TexCd).xyz;
	
	float3 IncidentVector = MirrorWorld - ProjectorWorld;
	float3 ReflectVector = reflect(IncidentVector, MirrorNormal);
    float4 col;
	col.a = length(MirrorNormal) > 0.5f;
	col.rgb = ReflectVector;
    return col;
}

// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique TReflectedTransmission
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_3_0 PS();
    }
}