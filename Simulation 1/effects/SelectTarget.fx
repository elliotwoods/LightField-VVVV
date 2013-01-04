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
texture TexTransmission <string uiname="Transmission";>;
sampler SampTransmission = sampler_state    //sampler for doing the texture-lookup
{
    Texture  = (TexTransmission);          //apply a texture to the sampler
    MipFilter = NONE;         //sampler states
    MinFilter = NONE;
    MagFilter = NONE;
};

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
	Out.Pos = Pos;
	Out.Pos.xy *= 2.0f;
    Out.TexCd = TexCd;

    return Out;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------

float distanceRayToPoint(float3 s, float3 t, float3 p)
{
	return length(cross(p - s, p - (s+t))) / length(t);
}

float3 Target;
float Threshold = 0.01f;
float4 PS(vs2ps In): COLOR
{
    //In.TexCd = In.TexCd / In.TexCd.w; // for perpective texture projections (e.g. shadow maps) ps_2_0

	float4 TransmissionLookup = tex2D(SampTransmission, In.TexCd);
    float3 MirrorWorld = tex2D(SampWorld, In.TexCd).xyz;
    float3 TransmissionVector = TransmissionLookup.xyz;
	
	float4 col = (float4)1.0f;
	
	col.a = 1.0f - smoothstep(0, Threshold, distanceRayToPoint(MirrorWorld, TransmissionVector, Target));
	col.a *= TransmissionLookup.a;
    return col;
}

// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique TSelectTarget
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}