//@author: vvvv group
//@help: this is a very basic template. use it to start writing your own effects. if you want effects with lighting start from one of the GouraudXXXX or PhongXXXX effects
//@tags:
//@credits:

// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//transforms
float4x4 tW: WORLD;        //the models world matrix
float4x4 tV: VIEW;         //view matrix as set via Renderer (EX9)
float4x4 tP: PROJECTION;
float4x4 tWVP: WORLDVIEWPROJECTION;
float4x4 tWV: WORLDVIEW;


//the data structure: "vertexshader to pixelshader"
//used as output data with the VS function
//and as input data with the PS function
struct vs2ps
{
    float4 Pos  : POSITION;
	float4 NormW : TEXCOORD0;
	float4 NormV : TEXCOORD1;
};

// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// --------------------------------------------------------------------------------------------------
vs2ps VS(
    float4 PosO  : POSITION,
	float4 NormO : NORMAL)
{
    //declare output struct
    vs2ps Out;

    //transform position
    Out.Pos = mul(PosO, tWVP);
	
	NormO.w = 0.0f;
	Out.NormW = mul(NormO, tW);
	Out.NormV = mul(NormO, tWV);
    return Out;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------

float4 PSView(vs2ps In): COLOR
{
	float4 col = (float4)1.0f;
	col.rgb = normalize(In.NormV.xyz);
    return col;
}

float4 PSWorld(vs2ps In): COLOR
{
	float4 col = (float4)1.0f;
	col.rgb = normalize(In.NormW.xyz);
    return col;
}

// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique TWorld
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_2_0 VS();
        PixelShader  = compile ps_2_0 PSWorld();
    }
}

technique TView
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_2_0 VS();
        PixelShader  = compile ps_2_0 PSView();
    }
}