﻿Shader "Unity Shader Book/Chapter 7/Normal Map Tangent Space"
{
	Properties{
		_Color("Color Tint", Color) = (1,1,1,1)
		_MainTex("Main Tex", 2D) = "white"{}
		_BumpMap("Normal Map", 2D) = "bump"{}
		_BumpScale("Bump Scale", Float) = 1.0
		_Specular("Specular", Color) = (1,1,1,1)
		_Gloss("Gloss", Range(8.0,256)) = 20
	}

		SubShader
		{
			Pass
			{
				Tags{"LightingMode" = "ForwardBase"}

				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#include "Lighting.cginc"

				fixed4 _Color;
				sampler2D _MainTex;
				float4 _MainTex_ST;
				sampler2D _BumpMap;
				float4 _BumpMap_ST;
				float _BumpScale;
				fixed4 _Specular;
				float _Gloss;

				struct a2v {
					float4 vertex : POSITION;
					float3 normal : NORMAL;
					float4 tangent : TANGENT;
					float4 texcoord : TEXCOORD0;
				};

				struct v2f {
					float4 pos : SV_POSITION;
					//float3 worldNormal : TEXCOORD0;
					//float3 worldPos : TEXCOORD1;
					float4 uv : TEXCOORD0;
					float3 lightDir : TEXCOORD1;
					float3 viewDir : TEXCOORD2;
				};

				v2f vert(a2v v)
				{
					v2f o;

					o.pos = UnityObjectToClipPos(v.vertex);
					//o.worldNormal = UnityObjectToWorldNormal(v.normal);
					//o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
					o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
					o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);

					TANGENT_SPACE_ROTATION;

					o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
					o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;

					return o;
				}

				fixed4 frag(v2f i) : SV_Target
				{
					fixed3 tangentLightDir = normalize(i.lightDir);
					fixed3 tangentViewDir = normalize(i.viewDir);

					fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);
					fixed3 tangentNormal;

					tangentNormal.xy = (packedNormal.xy * 2 - 1) * _BumpScale;
					tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
					fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
					fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(tangentNormal, tangentLightDir));

					//fixed3 worldNormal = normalize(i.worldNormal);
					//fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
					//fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
					//fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(worldNormal, worldLightDir));

					//fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
					//fixed3 halfDir = normalize(worldLightDir + viewDir);
					fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
					fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(tangentNormal, halfDir)), _Gloss);

					return fixed4(ambient + diffuse + specular, 1.0);
				}
				ENDCG
			}
		}
}