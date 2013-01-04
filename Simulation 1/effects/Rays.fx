//@author: vvvv group
//@help: draws a mesh with a constant color
//@tags: template, basic
//@credits:

// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//transforms
float4x4 tW: WORLD;        //the models world matrix
float4x4 tV: VIEW;         //view matrix as set via Renderer (EX9)
float4x4 tP: PROJECTION;   //projection matrix as set via Renderer (EX9)
float4x4 tVP: VIEWPROJECTION;
float4x4 tWVP: WORLDVIEWPROJECTION;

//material properties
float4 cAmb : COLOR <String uiname="Color";>  = {1, 1, 1, 1};
float Alpha = 1;

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

//texture
texture TexIntensity <string uiname="Intensity Map";>;
sampler SampIntensity= sampler_state    //sampler for doing the texture-lookup
{
    Texture  = (TexIntensity);          //apply a texture to the sampler
    MipFilter = NONE;         //sampler states
    MinFilter = NONE;
    MagFilter = NONE;
};
float3 ProjectorWorld <string uiname="Projector Position";>;
//float4x4 tTex: TEXTUREMATRIX <string uiname="Texture Transform";>;

//the data structure: vertexshader to pixelshader
//used as output data with the VS function
//and as input data with the PS function
struct vs2ps
{
    float4 PosWVP : POSITION;
	bool Reflect : COLOR0;
	bool Discard : COLOR1;
	float Fade : COLOR2;
	float4 Color : COLOR3;
};

// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// --------------------------------------------------------------------------------------------------

int2 Resolution;
int PixelX <string uiname="Pixel X";>;
int PixelY <string uiname="Pixel Y";>;

float ReflectDistance <string uiname="Reflection Distance";> = 5.0f;
vs2ps VS(
    float4 PosO : POSITION,
    float4 TexCd : TEXCOORD0)
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;
	Out.Fade = 1.0f;
	
	PosO = mul(PosO, tW);
	
	float4 PosR = PosO;
	PosR.x += float(PixelX) + 0.5f;
	PosR.y += float(PixelY) + 0.5f;
	
	PosR.xy /= float2(Resolution);
	
	float4 PosW;
	PosW.w = 1.0f;
	
	float4 TexLookup;
	TexLookup.xy = PosR.xy;
	TexLookup.zw = float2(0.0f, 1.0f);
	
	float3 MirrorWorld = tex2Dlod(SampWorld, TexLookup).xyz;
	float4 RayTransmissionLookup = tex2Dlod(SampTransmission, TexLookup);
    Out.Color = tex2Dlod(SampIntensity, TexLookup);
	
	float3 RayTransmission = RayTransmissionLookup.xyz;
	bool RayValid = RayTransmissionLookup.a > 0.5;
	
	Out.Reflect = false;

	if (PosR.z <= 0) {
		//casting from projector to mirror
		PosW.xyz = lerp(MirrorWorld, ProjectorWorld, abs(PosR.z)).xyz;
		Out.Fade /= length(PosW.xyz - ProjectorWorld) * 2.0f;
		Out.Discard = false;
	} else {
		//casting out from mirror
		//check if mirror exists here
		if (RayValid)
		{
			PosW.xyz = MirrorWorld + RayTransmission * ReflectDistance * PosR.z;
			Out.Reflect = true;
			Out.Fade /= length(ProjectorWorld - MirrorWorld);
			Out.Fade /= length(PosW.xyz - MirrorWorld);
			Out.Discard = false;
		} else {
			PosW.xyz = ProjectorWorld;
			Out.Fade = 1.0f;
			Out.Discard = true;
		}
	}
	
    Out.PosWVP = mul(PosW, tVP);
	return Out;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------
float dampening = 4;
float4 PS(vs2ps In): COLOR
{
    //In.TexCd = In.TexCd / In.TexCd.w; // for perpective texture projections (e.g. shadow maps) ps_2_0

	if (In.Discard > 0.0f)
		discard;
    float4 col = In.Color * cAmb;
	
	col.rgb *= In.Fade;
	col.rgb /= pow(2, dampening);
    col.a *= Alpha;
	
    return col;
}

// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique TCast
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_3_0 PS();
    }
}