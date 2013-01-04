// CubeMap based Environment Mapping
// featuring:
//         - SkyBox
//         - Reflection (bump, normal distortion)
//         - Reflection <- fresnel based blending -> Refraction
//         - image based diffuse lighting

// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------
#include "CubeMapper.fxh"
#include <effects\PhongPoint.fxh>

//transforms
float4x4 tW: WORLD;        //the models world matrix
float4x4 tWIT: WORLDINVERSETRANSPOSE;
float4x4 tV: VIEW;         //view matrix as set via Renderer (EX9)
float4x4 tP: PROJECTION;   //projection matrix as set via Renderer (EX9)
float4x4 tWVP: WORLDVIEWPROJECTION;
float4x4 tWV: WORLDVIEW;
float4x4 tVP: VIEWPROJECTION;
float3 posCam : CAMERAPOSITION;

//textures
texture TexEnvironment <string uiname="Environment CubeMap";>;
samplerCUBE SampEnvironment = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (TexEnvironment);       //apply a texture to the sampler
    MipFilter = LINEAR;         //sampler states
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

//texture transformation marked with semantic TEXTUREMATRIX to achieve symmetric transformations
float4x4 tTex: TEXTUREMATRIX <string uiname="Texture Transform";>;

//the data structure: "vertexshader to pixelshader"
//used as output data with the VS function
//and as input data with the PS function
struct vs2ps_SkyBox
{
    float4 PosWVP: POSITION;
    float3 ViewVectorW: TEXCOORD0;
};

struct vs2ps
{
    float4 PosWVP: POSITION;
    float3 ViewVectorW: TEXCOORD0;
    float3 NormW: TEXCOORD1;
	float3 LightDirV: TEXCOORD2;
    float3 NormV: TEXCOORD3;
    float3 ViewDirV: TEXCOORD4;
	float4 PosW : TEXCOORD5;
};

// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// --------------------------------------------------------------------------------------------------


vs2ps VS_Reflect(
    float4 PosO: POSITION,
    float4 NormalO: NORMAL)
{
    //declare output struct
    vs2ps Out = (vs2ps) 0;

    //position in world space
    float4 PosW = mul(PosO, tW);
	
	//inverse light direction in view space
    float3 LightDirW = normalize(lPos - Out.PosW);
    Out.LightDirV = mul(LightDirW, tV);
    
    //normal in view space
    Out.NormV = normalize(mul(NormalO, tWV));

    //texture coordinates for skybox cubemap
    Out.ViewVectorW = PosW - posCam;
    Out.ViewDirV = -normalize(mul(PosO, tWV));
 
    //normal in world space
    //make sure NormO.w = 0, else we get artefacts when scaling the model
    NormalO.w = 0;
    //the normal is a directional vector and therefore should have length=1
    Out.NormW = normalize(mul(NormalO, tW));

    //position in projection space
    Out.PosWVP = mul(PosW, tVP);

    return Out;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------
float diffuse = 0.5f;


float4 PS_Reflect(vs2ps In): COLOR
{
    //reflective color
    float4 cReflect = ReflectiveColor(SampEnvironment, In.ViewVectorW, In.NormW);
    //scale reflection to maximum reflectiveness
    cReflect.rgb *= MaxReflectiveness;
    
	float4 cPhong = PhongPoint(In.PosW, In.NormV, In.ViewDirV, In.LightDirV);
	
	return lerp(cReflect, cPhong, diffuse);
    return cReflect;
}


// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique TReflect
{
    pass P0
    {
        VertexShader = compile vs_2_0 VS_Reflect();
        PixelShader  = compile ps_2_0 PS_Reflect();
    }
}

