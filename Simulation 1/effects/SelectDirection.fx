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

float3 Direction;
float ThresholdX = 1.0f;
float ThresholdY = 1.0f;

float ApplyThreshold(float Transission, float Direction, float Threshold)
{
	float Threshold2 = Threshold * 2.0f * 3.141592654 / 360.0f;
	return 1 - smoothstep(0, Threshold2, abs(Transission - Direction));
}

float AngleX(float3 Gradient)
{
	return atan2(Gradient.x, Gradient.z);
}

float AngleY(float3 Gradient)
{
	return atan2(Gradient.y, Gradient.z);
}

float4 PS(vs2ps In): COLOR
{
	float4 TransmissionLookup = tex2D(SampTransmission, In.TexCd);
	bool RayValid = TransmissionLookup.a;
    float3 MirrorWorld = tex2D(SampWorld, In.TexCd).xyz;
    float3 TransmissionVector = TransmissionLookup.xyz;
	
	float4 col = (float4)1.0f;
	col.a *= ApplyThreshold(AngleX(TransmissionVector), AngleX(Direction), ThresholdX);
	col.a *= ApplyThreshold(AngleY(TransmissionVector), AngleY(Direction), ThresholdY);
	col.a *= RayValid;
    return col;
}

// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique TSelectDirection
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_3_0 PS();
    }
}