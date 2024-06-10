import * as THREE from 'https://cdnjs.cloudflare.com/ajax/libs/three.js/0.165.0/three.module.min.js';

let camera, scene, renderer, backbufferRenderTarget, backbufferTexture;;
let geometry, material, mesh;
let attributes,uniforms;

init();
main();

//
// 初期化
//
function init() {
    window.addEventListener('resize', onWindowResize, false);
    document.addEventListener('mousemove', onDocumentMouseMove, false);
    document.addEventListener('DOMContentLoaded', onDocumentReady, false);
}
//
// Shaderファイル読み込み
//
function loadShader(url) {
    var request = new XMLHttpRequest();
    request.open('GET', url, false);
    request.send(null);

    // リクエストが完了したとき
    if (request.readyState == 4) {
        // Http status 200 (成功)
        if (request.status == 200) {
            return request.responseText;
        } else { // 失敗
            console.log("error");
            return null;
        }
    }
}
//
// メイン処理
//
function main() {
    const vertexShader = loadShader('../shader/vert.glsl');
    const fragmentShader = loadShader('../shader/frag.glsl');

    //console.log(vertexShader);
    // 作成
    scene = new THREE.Scene();
    // カメラ (視野角,アス比, 近面位置, 遠面位置)
    camera = new THREE.PerspectiveCamera(70, window.innerWidth / window.innerHeight, 0.01, 10);
    camera.position.z = 1; //手前
    //
    // 描画
    //
    // 形状
    /////// [debug]
    const aspect = window.innerWidth / window.innerHeight;
    const frustumHeight = 2 * Math.tan(THREE.MathUtils.degToRad(camera.fov) / 2) * camera.position.z;
    const frustumWidth = frustumHeight * aspect;
    // geometry = new THREE.PlaneGeometry(2, 2,10,10);
    geometry = new THREE.PlaneGeometry(
        frustumWidth, frustumHeight
        //window.innerWidth/90, window.innerHeight/90,
        // 10,10
    );
    backbufferRenderTarget = new THREE.WebGLRenderTarget(window.innerWidth, window.innerHeight);
    backbufferTexture = backbufferRenderTarget.texture;
    uniforms = {
        u_time: { value: 1.0 },
        u_resolution: {
            value: new THREE.Vector2(
                window.innerWidth, window.innerHeight
            )
        },
        u_mouse: { value: new THREE.Vector2(0.0, 0.0) },
        u_near: { value: 0 },
        u_temp: { value: 0 },
        u_rotate: { value: 0 },
        u_slide: { value: 0 },
        u_pir: { value: 0 },
        u_backbuffer: { value: backbufferTexture }
    };

    //
    // 画
    //
    ///// [debug]
    //material = new THREE.MeshNormalMaterial();

    // https://threejs.org/docs/#api/en/materials/ShaderMaterial
    material = new THREE.ShaderMaterial({
        uniforms: uniforms,
        vertexShader: vertexShader,
        fragmentShader: fragmentShader,
        blending: THREE.AdditiveBlending,
        uniformsNeedUpdate: true,
        //wireframe: true,
        depthTest: false,
        transparent: true, //透明度
        vertexColors: true, //頂点色
    });
    mesh = new THREE.Mesh(geometry, material);
    scene.add(mesh);

    //
    // レンダー
    //
    renderer = new THREE.WebGLRenderer({ antialias: true });
    // 画面サイズ
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.setAnimationLoop(animation);
    // HTMLに反映
    document.body.appendChild(renderer.domElement);

}

//
// loop
//
function animation(time) {
    // shaderに渡す値の更新
    uniforms.u_time.value = time * 0.001; // ミリ秒から秒に変換

    //mesh.rotation.x = time / 2000;
    //mesh.rotation.y = time / 1000;

    //前フレームをバックバッファに
    renderer.setRenderTarget(backbufferRenderTarget);
    renderer.render(scene, camera);
    // バックバッファを画面に
    renderer.setRenderTarget(null);
    renderer.render(scene, camera);
}
// 画面サイズ
function onWindowResize() {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
    uniforms.u_resolution.value.set(window.innerWidth, window.innerHeight);

    // 再計算された平面ジオメトリのサイズを更新
    const aspect = window.innerWidth / window.innerHeight;
    const frustumHeight = 2 * Math.tan(THREE.MathUtils.degToRad(camera.fov) / 2) * camera.position.z;
    const frustumWidth = frustumHeight * aspect;
    geometry.dispose(); // 古いジオメトリを破棄
    geometry = new THREE.PlaneGeometry(frustumWidth, frustumHeight);
    mesh.geometry = geometry;
}
//
// マウス
//
function onDocumentMouseMove(event) {
    uniforms.u_mouse.value.set(event.clientX, window.innerHeight - event.clientY);
}
//
// pyデータ更新
//
function onDocumentReady() {
    // 初回データの取得
    fetchData();
    // 0.5秒ごとにデータを更新
    setInterval(fetchData, 500);
}
//
// pyから受取り
//
function fetchData() {
    fetch('/data')
        .then(response => response.json())
        .then(data => {
            console.log(data);
            uniforms.u_near.value = data.near;
            uniforms.u_temp.value = data.temp; // 他のユニフォーム変数も同様に更新
            uniforms.u_rotate.value = data.rotate;
            uniforms.u_slide.value = data.slide;
            if (data.pir==true) uniforms.u_pir.value = 1;
            else uniforms.u_pir.value = 0;
        })
        .catch(error => console.error('Error fetching data:', error));
}