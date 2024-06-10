#ifdef GL_ES
precision mediump float;
#endif

#define PI acos(-1.)
#define loop(i,n)for(i;i<n;i++)
#define sat(v)clamp(v,0.,1.)
// uniform モデルの値
uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

uniform float u_near;// 近さ 0~150くらい？
uniform float u_temp;// 温度 *10
uniform float u_rotate;// 回転 0 ~ 300
uniform float u_slide;// ｽﾗｲﾀﾞ- 0~100
uniform float u_pir;// 動きを検知 1/0
//uniform vec3 u_camera;

//
// v to f
//
varying vec2 v_uv;


///////////////////////////////////////
// method
///////////////////////////////////////

// 色変換
vec3 rgbTo01(vec3 rgb){
    return rgb/255.;
}
// ノイズ
float rand21(vec2 co){
    return fract(sin(dot(co.xy,vec2(12.9898,78.233)))*43758.5453);
}
vec2 rand22(vec2 st){
    st=vec2(dot(st,vec2(127.1,311.7)),
    dot(st,vec2(269.5,183.3)));
    
    return 2.*fract(sin(st)*43758.5453123)-1.;
}
float fsnoise(vec2 st){
    vec2 i=floor(st);
    vec2 f=fract(st);
    vec2 u=f*f*(3.-2.*f);
    return mix(mix(dot(rand22(i+vec2(0.,0.)),f-vec2(0.,0.)),
    dot(rand22(i+vec2(1.,0.)),f-vec2(1.,0.)),u.x),
    mix(dot(rand22(i+vec2(0.,1.)),f-vec2(0.,1.)),
    dot(rand22(i+vec2(1.,1.)),f-vec2(1.,1.)),u.x),u.y);
}
vec3 rand33(vec3 p)
{
    uvec3 x=floatBitsToUint(p);
    const uint k=1892563894u;
    x=((x>>8U)^x.yzx)*k;
    x=((x>>8U)^x.yzx)*k;
    x=((x>>8U)^x.yzx)*k;
    return vec3(x)/float(0xffffffffu);
}
//回転
mat2 rot(float a){
    float c=cos(a),s=sin(a);
    return mat2(c,s,-s,c);
}
// 極座標
vec2 pmod(vec2 p,float r){
    float a=atan(p.x,p.y)+PI/r;
    float n=2.*PI/r;//各セクターの角度幅
    a=floor(a/n)*n;//角度aを最も近いセクターの境界にスナップ(丸める)
    return p*rot(-a);
}
// 万華鏡みたいな分割イージング
vec2 easeUV(vec2 uv, float time)
{
    int n=3;
    for(int i=0;i<3;i++)
    {
        float lt=time*1.+float(i);
        float li=floor(lt);
        float lf=fract(lt);
        lf=smoothstep(0.,1.,pow(lf,.3));//イージング
        // 0で1-lf / 他1 / ラストでlf
        float ins=((i==0)?1.-lf:((i==n-1)?lf:1.));
        vec3 s=rand33(vec3(42.42,2.4,li));
        vec3 c=(rand33(s*42.1231+.12)-.5);//*ins;
        //中心を0にする&insスケーリング
        if(s.x<-.6)
        {
            float a=PI*c.x*.5;
            vec2 of=c.yz;
            vec2 p=vec2(cos(a),sin(a));
            uv-=of;
            uv-=2.*min(0.,dot(uv,p))*p;// fold
            uv+=of;
        }
        else
        {
            uv*=c.z+1.;//普通のトンネル
        }
        return uv;
    }
}
// UVうずまき歪ませ
vec2 yugamiUV(vec2 uv,float u,float r,float t){
    float ang=atan(-uv.y,uv.x);
    float uzu=sin(length(uv)*u-ang+t);
    float yugami=r;
    return uv+yugami*uzu;
}
// flower
float flower(vec2 p,float size){
    float ang=atan(p.y,p.x);
    ang=(PI+ang)/(2.*PI);
    float c=sin(ang*10.*PI)-length(p);
    return max(0.,1.-(length(p)*size+c));
}
float lineFlower(vec2 p, float size, float b){
    float ang=atan(p.y,p.x);
    ang=(PI+ang)/(2.*PI);
    float c=sin(ang*10.*PI)-length(p*size);
    return step(0.8,b/abs(c));
}

//////////////////////////////////
// レイマーチング
//////////////////////////////////
// 球
float sphere(vec3 p,vec3 s){
    return length(p)-s.x;
}
// きらきら
float octahedron(vec3 p,vec3 s)
{
    p=abs(p);
    return(p.x+p.y+p.z-s.x)*.57735027;
}
// 箱
float cube(vec3 p,vec3 s){
    vec3 q=abs(p);
    vec3 m=max(s-q,0.);
    return length(max(q-s,0.))-min(min(m.x,m.y),m.z);
}
float crossBox(vec3 p,float s){
    float m1=cube(p,vec3(s,s,99999.));
    float m2=cube(p,vec3(99999.,s,s));
    float m3=cube(p,vec3(s,99999.,s));
    return min(min(m1,m2),m3);
}
float dist(vec3 p, float time){
    p.xy*=rot(time*.2);
    p.z+=3.*time;
    
    p.xy=pmod(p.xy,6.);//極座標
    
    for(int i=0;i<1;i++){
        p=abs(p)-1.;
        float nn = mod(floor(u_time/10.),4.)*0.5*PI; //0.0~0.5
        p.xz *= rot(nn);
    }
    
    float k=.6;//太さ？
    p=mod(p,k)-.5*k;
    float bou=crossBox(p,.02);
    float connect=octahedron(p,vec3(.1));
    return min(bou,connect);
}
///////////////////////////////////////
// main
///////////////////////////////////////
void main(){
    // uv
    vec2 uv=v_uv;//画面の通りのサイズ 0~1
    //vec2 cuv=2.*uv-1.;//0中心 -1~1
    vec2 yuv=((v_uv*u_resolution)*2.-u_resolution)/max(u_resolution.x,u_resolution.y);//yが-1~1
    vec2 suv = yuv;
    vec2 puv=pmod(yuv,u_slide);
    // マウス座標変換
    vec2 mouse_uv=(u_mouse/u_resolution);
    vec2 mouse_yuv=((mouse_uv*u_resolution)*2.-u_resolution)/max(u_resolution.x,u_resolution.y);
    // カラーパレット https://colorffy.com/palettes/EZK3Hki3yJNuF90CJSMS
    vec3 pink1=rgbTo01(vec3(251.,144.,250.));
    vec3 pink2=rgbTo01(vec3(252.,121.,140.));
    vec3 purple1=rgbTo01(vec3(168.,153.,255.));
    vec3 purple2=rgbTo01(vec3(227.,163.,255.));
    vec3 rain1=rgbTo01(vec3(68.,84.,185.));
    vec3 rain2=rgbTo01(vec3(178.,242.,255.));
    vec3 neon1=rgbTo01(vec3(233.,87.,255.));
    vec3 neon2=rgbTo01(vec3(71.,255.,240.));

    // vec3 sun1=rgbTo01(vec3(254.,241.,138.));
    // vec3 sun2=rgbTo01(vec3(254.,204.,108.));
    // vec3 rain1=rgbTo01(vec3(133.,208.,240.));
    // vec3 rain2=rgbTo01(vec3(0.,153.,204.));
    
    ///////////////////////////////////
    // 計算開始
    ///////////////////////////////////
    // 速度調整
    float time = (u_near<30.)?u_time*0.1:u_time;
    float near = step(30.,u_near); //近いと青
    // テーマ色
    float tmp = fract(u_temp/10.);
    vec3 rain = mix(rain1,rain2,tmp);
    vec3 pink = mix(pink1,pink2,tmp);
    vec3 purple = mix(purple1,purple2,tmp);
    vec3 srColor = mix(rain,purple,near);
    // UV
    puv=easeUV(puv, time);
    //float n=mod(time*4.,6.)+2.;
    //yuv*=rot(PI/n);
    yuv=yugamiUV(yuv,u_rotate/8.,.04*u_rotate/300.,3.*time);
    // UV色
    vec3 uvColor=.5+.5*cos(time+yuv.xyx+vec3(0,2,4));
    
    //////////////////////////////
    // レイマーチング
    //////////////////////////////
    float st = sin(time);
    vec3 ro=vec3(st*0.,st*0.,0.+exp(cos(time)));
    vec3 rdir=normalize(vec3(yuv,0.)-ro);//カメラ向き
    vec3 rayP=vec3(0.);
    float d,t=2.;
    vec3 ac = vec3(0.);
    for(int i=0;i<66;i++){
        rayP=ro+rdir*t;
        d=dist(ro+rdir*t,time);
        t+=d;
        vec3 a=vec3(exp(-10.*d));
        ac+=a;
        if(d<.01)break;
    }
    float cl=exp(-1.*t);
    vec3 blackRay = 0.005*ac;
    //vec3 blackRay = srColor * 0.05*ac;
    vec3 whiteRay = srColor + 0.9/ac;
    vec3 rayMarch = sat(whiteRay);
    vec4 ray = vec4(rayMarch,1.);

    ////////////////////
    // 波
    /////////////////////
    float wtime = time/2.;
    vec2 p = mod(uv*2.*PI, 2.*PI)-300.0;
	vec2 i = p;
	float c = 1.0;
	for (int n = 0; n < 5; n++){
		float t = wtime;// * (1.0 - (3.5 / float(n+1)));
		i = p + vec2(cos(t-i.x)+sin(t+i.y), sin(t-i.y)+cos(t+i.x));
		c += 1.0/length(vec2(p.x/(sin(i.x+t)/0.005), p.y/(cos(i.y+t)/0.005)));
	}
	c /= float(5);
	c = 1.17-pow(c, 1.4);
	vec3 wat = vec3(pow(abs(c), 8.0));
    vec3 wcol = vec3(0.0, 0.35, 0.5);
    wat = clamp(wat + wcol, 0.0, 1.0);
    vec4 water = vec4(wat,1.);

    /////////////////////
    // ノイズ
    //////////////////////
    vec2 noiseUV = vec2(uv.x,uv.y+rand21(uv*mod(time,10.)));
    float nf = rand21(uv*mod(time,10.));
    vec4 noise = vec4(vec3(nf),1.0);

    ///////////////////////////
    // タイル
    ///////////////////////////
    vec2 tuv = yugamiUV(uv,u_rotate/8.,.04*u_rotate/300.,3.*time)*u_resolution/8.;
    float mm = max(1.,u_slide*0.7);
    tuv.x = float(int(tuv.x)^int(tuv.y))/mm+time*0.5;
    vec4 m1 = 0.2*vec4(fract(tuv.x));
    vec4 m2 = 0.3+sin(tuv.x*4.+time*vec4(3.,2.,4.,0.));
    float stp = step(mod(tuv.x,0.7),0.2);
    vec4 tile = mix(m1,m2,stp);

    //////////////////////
    //基本図形
    //////////////////////

    vec4 blwh;
    float bwSize = 0.7*sin(mod(time*2.,1.) * (PI/2.));
    float cw = 0.3*(1.-abs(length(yuv)- bwSize));
    float circle =  step( abs(length(yuv)- bwSize), 0.01 );
    float dw = 2.*bwSize*(1.-dot(abs(yuv), vec2(1.)));
    float daiya = step( dot(abs(yuv), vec2(1.)), bwSize );
    //circle=step(circle,0.);
    blwh=vec4((fract(time)>0.5?uvColor*cw+circle:uvColor*dw+daiya),1.);

    //////////////////////////////
    // 花
    /////////////////////////////
    vec2 floUV = yuv;
    float floTime = 0.7*sin(mod(time*2.,1.) * (PI/2.));
    vec3 flo = vec3(0.);
    floUV = yuv*rot(floTime);
    flo += lineFlower(floUV,4.,0.1);
    floUV = yuv*rot(floTime+PI);
    flo += lineFlower(floUV,6.,0.1);
    floUV = yuv*rot(-floTime);
    flo += lineFlower(floUV,1.,0.1);
    floUV = yuv*rot(-floTime+PI);
    flo += lineFlower(floUV,2.,0.1);
    vec4 flower=vec4(flo,1.);
    //color = vec3(uv.x, uv.y, 1.0 - uv.x);
    //color = 0.5 + 0.5*cos(time + suv.xyx + vec3(0, 2, 4));


    //////////////
    // ドット 円状に広がる
    //////////////
    vec2 dotUV = fract(yuv*10.)-.5;
    float dCol = length(dotUV);
    float dSize = 0.1 + 0.4 * sin(-10.*time + length(yuv) * 3.0);
    vec4 dotCol = vec4(uvColor*vec3(step(dCol,dSize)),1.);

    ////////////
    float s = u_slide;
    float change = fract(u_time*3./10.);
    //vec3 color = tile;
    vec4 c1 = mix(ray,water,step(change,0.2));
    vec4 c2 = mix(tile,dotCol,step(change,0.2));
    vec4 c3 = mix(blwh,flower,step(change,0.2));
    // モノクロ～レイマーチング/波～タイル/波
    vec4 mode = (s<25.)? c2 : ( (s<50.)? c1 : ((s<75.)?c1:c3) );
    noise = vec4(mode.rgb*noise.rgb,1.);
    vec4 color=(u_pir>0.)? noise:mode;
    
    //////////////////////////
    // 出力
    //////////////////////////
    gl_FragColor = color;
}
