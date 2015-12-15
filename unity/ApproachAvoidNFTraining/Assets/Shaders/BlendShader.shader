Shader "Custom/BlendShader" {
	Properties {
		_Blend ("Blend", Range (0, 1) ) = 0.5 
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Texture Neutral", 2D) = "white" {}
		_Texture2 ("Texture Bad", 2D) = ""
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 300
		Pass {
			SetTexture[_MainTex]
			SetTexture[_Texture2] {
				ConstantColor (0,0,0, [_Blend])
				Combine texture Lerp(constant) previous
			}
		}
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		//#pragma surface surf Standard fullforwardshadows
		#pragma surface surf Lambert

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;
		sampler2D _Texture2;
		float _Blend;
		fixed4 _Color;

		struct Input {
			float2 uv_MainTex;
			float2 uv_Texture2;
		};


		void surf (Input IN, inout SurfaceOutput o) {
			// Albedo comes from a texture tinted by color
			fixed4 t1 = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			fixed4 t2 = tex2D (_Texture2, IN.uv_MainTex) * _Color;
			
			o.Albedo = lerp(t1, t2, _Blend);
		}
		ENDCG
	} 
	FallBack "Diffuse"
}
