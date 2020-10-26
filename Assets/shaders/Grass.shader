Shader "Joppe/Grass"
{
	Properties
	{
		[Header(Shading)]
		_MainTex("Texture", 2D) = "white" {}
		_TopColor("Top Color", Color) = (1,1,1,1)
		_BottomColor("Bottom Color", Color) = (1,1,1,1)

		_CardSize("Card Size", Range(0, 5)) = 1
		_CardRemovalVal("Remove Size", Range(0, 2)) = 1
		
		_WindDistortionMap("Wind Distortion Map", 2D) = "white" {}
		_WindSpeed("Wind Speed (XY)", Vector) = (0.05, 0.05, 0,0)
		_WindStrength("Wind Force", Float) = 1

		_RenderDistance("Render Distance", Range(0, 500)) = 50
		_TessellationUniform("Tessellation Amount", Int) = 1
		_OffsetAmount("Offset Amount", Float) = 0

		_DisplacementStrength("Displacement Strength", Float) = 0
		_ShadowLightness("Shadow Strength", Range(0, 1)) = 0

	}

		CGINCLUDE

#include "UnityCG.cginc"
#include "AutoLight.cginc"
#include "CustomTesselation.cginc"

		float _CardSize;
		float _CardRemovalVal;
		float _RenderDistance;

		sampler2D _WindDistortionMap;
		float4 _WindDistortionMap_ST;

		float2 _WindSpeed;
		float _WindStrength;

		float _OffsetAmount;

		float _DisplacementStrength;

		struct geometryOutput
		{
		//Information Geometry requires to be sent to the Fragment Shader
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD0;
			
			LIGHTING_COORDS(1, 2)

			float fresnel : TEXCOORD3;
		};

		geometryOutput VertData(float3 pos, float2 uv, float3 normal)
		{
		//Filling a Geometry-Vertex with information
			geometryOutput o;
			o.pos = UnityObjectToClipPos(pos);
			o.uv = uv;
			float3 i = normalize(ObjSpaceViewDir(float4(pos.xyz, 0)));
			o.fresnel = dot(i, normal);
			TRANSFER_VERTEX_TO_FRAGMENT(o);
			return o;
		}

		float3x3 AngleAxis3x3(float angle, float3 axis)
		{
			//RotationMatrix function written by Keijiro Takahashi
			float c, s;
			sincos(angle, s, c);

			float t = 1 - c;
			float x = axis.x;
			float y = axis.y;
			float z = axis.z;

			return float3x3(
				t * x * x + c, t * x * y - s * z, t * x * z + s * y,
				t * x * y + s * z, t * y * y + c, t * y * z - s * x,
				t * x * z - s * y, t * y * z + s * x, t * z * z + c
				);
		}

		float rand(float3 co)
		{
			//Randomization function written by Keijiro Takahashi
			return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453123);
		}

		[maxvertexcount(8)]
		void geo(triangle vertexOutput IN[3] : SV_POSITION, inout TriangleStream<geometryOutput> geo)
		{
			//for every triangle in the mesh we grab point 0, eventually giving us every point
			geometryOutput o;
			float4 pos = IN[0].vertex;
			float3 wpos = IN[0].wpos;
			float2 wposuv = IN[0].wposuv;
			float3 vertNormal = IN[0].normal;
			float4 vertTangent = IN[0].tangent;
			float3 color = IN[0].color;
			float3 randomOffset = (rand(wpos) * 2 - 1) * _OffsetAmount;
			randomOffset.y = 0;

			float viewDistance = distance(wpos, _WorldSpaceCameraPos);
			
			//Cull the mesh if it's too far away or too small
			if (_CardSize * color.r < _CardRemovalVal || viewDistance > _RenderDistance)
				return;

			float3 vertCross = cross(vertNormal, vertTangent) * vertTangent.w;

			float3x3 tangentToLocal = float3x3(
				vertTangent.x, vertCross.x, vertNormal.x,
				vertTangent.y, vertCross.y, vertNormal.y,
				vertTangent.z, vertCross.z, vertNormal.z
				);

			float3x3 facingRotationMatrix = AngleAxis3x3(rand(pos) * UNITY_TWO_PI, float3(0, 0, 1));

			float2 uv = pos.xz * _WindDistortionMap_ST.xy + _WindDistortionMap_ST.zw + _WindSpeed * _Time;
			float2 windSample = (tex2Dlod(_WindDistortionMap, float4(uv, 0, 0)).xy * 2 - 1) * _WindStrength;

			float3 wind = float3(windSample.x, 0, windSample.y);

			float2 wposUV_tex = tex2Dlod(_RenderTexture, float4(wposuv.xy, 0, 0));
			float3 renderDisplacement = (float3(wposUV_tex.x - 0.25, 0, wposUV_tex.y - 0.25)) * _DisplacementStrength;

			float3x3 transformationMatrix = mul(tangentToLocal, facingRotationMatrix);
			pos.xz += vertTangent * randomOffset.xz;

			//first quad
			geo.Append(VertData(pos + mul(transformationMatrix, float3((-_CardSize / 2) * color.r, 0, 0)), float2(0, 0), vertNormal));
			geo.Append(VertData(pos + mul(transformationMatrix, float3((_CardSize / 2) * color.r, 0, 0)), float2(1, 0), vertNormal));
			geo.Append(VertData(pos + renderDisplacement + wind * (color.r * _CardSize) + mul(transformationMatrix, float3((-_CardSize / 2) * color.r, 0, _CardSize * color.r)), float2(0, 1), vertNormal));
			geo.Append(VertData(pos + renderDisplacement + wind * (color.r * _CardSize) + mul(transformationMatrix, float3((_CardSize / 2) * color.r, 0, _CardSize * color.r)), float2(1, 1), vertNormal));

			//start second quad
			geo.RestartStrip();
			geo.Append(VertData(pos + mul(transformationMatrix, float3(0, (-_CardSize / 2) * color.r, 0)), float2(0, 0), vertNormal));
			geo.Append(VertData(pos + mul(transformationMatrix, float3(0, (_CardSize / 2) * color.r, 0)), float2(1, 0), vertNormal));
			geo.Append(VertData(pos + renderDisplacement + wind * (color.r * _CardSize) + mul(transformationMatrix, float3(0, (-_CardSize / 2) * color.r, _CardSize * color.r)), float2(0, 1), vertNormal));
			geo.Append(VertData(pos + renderDisplacement + wind * (color.r * _CardSize) + mul(transformationMatrix, float3(0, (_CardSize / 2) * color.r, _CardSize * color.r)), float2(1, 1), vertNormal));

		}
		ENDCG

	SubShader
	{
		Pass
		{
		Tags
			{
			"Queue" = "AlphaTest"
			"RenderType" = "TransparentCutout"
			"LightMode" = "ForwardBase"
			}
			Cull Off
			ZWrite On
			AlphaToMask On

			CGPROGRAM

			#pragma vertex vert
			#pragma geometry geo
			#pragma fragment frag
			
			#pragma hull hull
			#pragma domain domain

			#pragma target 5.0
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight

			sampler2D _MainTex;
			float4 _TopColor;
			float4 _BottomColor;
			float _ShadowLightness;

			float4 frag(geometryOutput i, fixed facing : VFACE) : SV_Target
			{
				float atten = clamp(LIGHT_ATTENUATION(i),  _ShadowLightness / i.fresnel, 1);
				
				float4 tex = tex2D(_MainTex, i.uv);
				float4 col = lerp(_BottomColor, _TopColor, i.uv.y);
				col.rgb *= atten;
				tex *= col;

				return tex;
            }
            ENDCG
        }
		UsePass "VertexLit/SHADOWCASTER"
    }
}