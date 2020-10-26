

#if !defined(TESSELLATION_INCLUDED)
#define TESSELLATION_INCLUDED

float _TessellationUniform;
float _TessellationEdgeLength;



struct TessellationControlPoint
{
    float4 vertex : INTERNALTESSPOS;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float4 color : COLOR;

};

struct vertexInput
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float4 color : COLOR;
};

struct vertexOutput
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float4 color : COLOR;
    float2 wposuv : TEXCOORD0;
    float3 wpos : TEXCOORD1;
    
};

struct TessellationFactors
{
    float edge[3] : SV_TessFactor;
    float inside : SV_InsideTessFactor;
};

TessellationControlPoint MyTessellationVertexProgram(vertexInput v)
{
    TessellationControlPoint p;
    p.vertex = v.vertex;
    p.normal = v.normal;
    p.tangent = v.tangent;
    p.color = v.color;
    return p;
}

vertexInput vert(vertexInput v)
{
    return v;
}

sampler2D _RenderTexture;
float4 _RenderTexture_ST;
float3 _PlayerPos;

vertexOutput tessVert(vertexInput v)
{
    vertexOutput o;

    o.vertex = v.vertex;
    o.wpos = mul(unity_ObjectToWorld, v.vertex).xyz;
    o.wposuv = TRANSFORM_TEX((o.wpos.xz - _PlayerPos.xz + 75), _RenderTexture) / 150;
    o.normal = v.normal;
    o.tangent = v.tangent;
    o.color = v.color;

    
    return o;
}

float TessellationEdgeFactor(
	TessellationControlPoint cp0, TessellationControlPoint cp1
)
{
        return _TessellationUniform;
}

TessellationFactors patchConstantFunction(InputPatch<vertexInput, 3> patch)
{
    TessellationFactors f;
    f.edge[0] = TessellationEdgeFactor(patch[1], patch[2]);
    f.edge[1] = TessellationEdgeFactor(patch[2], patch[0]);
    f.edge[2] = TessellationEdgeFactor(patch[0], patch[1]);
    f.inside = (f.edge[0] + f.edge[1] + f.edge[2]) * (1 / 3.0);
    return f;
}

[UNITY_domain("tri")]
[UNITY_outputcontrolpoints(3)]
[UNITY_outputtopology("triangle_cw")]
[UNITY_partitioning("integer")]
[UNITY_patchconstantfunc("patchConstantFunction")]
vertexInput hull(InputPatch<vertexInput, 3> patch, uint id : SV_OutputControlPointID)
{
    return patch[id];
}

[UNITY_domain("tri")]
vertexOutput domain(TessellationFactors factors, OutputPatch<vertexInput, 3> patch, float3 barycentricCoordinates : SV_DomainLocation)
{
    vertexInput v;

#define MY_DOMAIN_PROGRAM_INTERPOLATE(fieldName) v.fieldName = \
		patch[0].fieldName * barycentricCoordinates.x + \
		patch[1].fieldName * barycentricCoordinates.y + \
		patch[2].fieldName * barycentricCoordinates.z;

	MY_DOMAIN_PROGRAM_INTERPOLATE(vertex)
	MY_DOMAIN_PROGRAM_INTERPOLATE(normal)
	MY_DOMAIN_PROGRAM_INTERPOLATE(tangent)
    MY_DOMAIN_PROGRAM_INTERPOLATE(color)

    return tessVert(v);
}

#endif