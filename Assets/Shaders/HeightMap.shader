Shader "Custom/HeightMap" 
{
	Properties 
	{
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_MainHeightTex("Height map", 2D) = "white" {}
		_MainNormalTex("NormalMap", 2D) = "white" {}		

		_TopTex("Top Albedo (RGB)", 2D) = "white" {}		
		_TopHeightTex("Height map", 2D) = "white" {}

		_TopHeight("Top Height", Range(-1, 1.5)) = 0.5
		_TopNormalTex("NormalMap", 2D) = "white" {}

		_Fade("Fade", Range(0,1)) = 0.5		
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf SimpleSpecular fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		uniform sampler2D _MainTex;
		uniform sampler2D _MainHeightTex;
		uniform sampler2D _MainNormalTex;

		uniform sampler2D _TopTex;
		sampler2D _TopNormalTex;
		sampler2D _TopHeightTex;
		uniform float _TopHeight;
		uniform float _Fade;

		struct Input 
		{
			float2 uv_MainTex;
			float2 uv_TopTex;
		};
				
		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_CBUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_CBUFFER_END

		half4 LightingSimpleSpecular(SurfaceOutput s, half3 lightDir, half3 viewDir, half atten)
		{
			half3 h = normalize(lightDir + viewDir);

			half diff = max(0, dot(s.Normal, lightDir));

			float nh = max(0, dot(s.Normal, h));
			float spec = pow(nh, 48.0) * s.Specular;

			half4 c;
			c.rgb = (s.Albedo * _LightColor0.rgb * diff + _LightColor0.rgb * spec) * atten;
			c.a = s.Alpha;
			return c;
		}

		float4 getBlend(float4 left, float4 right, float t)
		{
			float f = t * (3 * t - 2 * t*t);			
			
			float4 result = lerp(left, right, f);
			return result;
		}

		void surf (Input IN, inout SurfaceOutput o)
		{
			float mainHeight = tex2D(_MainHeightTex, IN.uv_MainTex).r;
			float topHeight = tex2D(_TopHeightTex, IN.uv_TopTex).r + _TopHeight + IN.uv_MainTex.x / 2;			
			
			float ss = smoothstep(mainHeight - _Fade / 2.0, mainHeight + _Fade / 2.0, topHeight);
			
			float dif = (abs(mainHeight - topHeight));
			
			o.Albedo = getBlend(tex2D(_MainTex, IN.uv_MainTex), tex2D(_TopTex, IN.uv_TopTex), ss);
			o.Normal = UnpackNormal(lerp(tex2D(_MainNormalTex, IN.uv_MainTex), tex2D(_TopNormalTex, IN.uv_TopTex), ss));
		}
		ENDCG
	}
	FallBack "Diffuse"
}
